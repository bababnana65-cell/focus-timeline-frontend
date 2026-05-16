import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:event_timeline/dto/followed_topic_dto.dart';
import 'package:event_timeline/dto/topic_timeline_dto.dart';
import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/models/timeline_creation_models.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/followed_topic_remote_service.dart';
import 'package:event_timeline/services/remote/http_api_client.dart';
import 'package:event_timeline/services/remote/http_timeline_creation_service.dart';
import 'package:event_timeline/services/remote/topic_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';

void main() {
  test('create timeline keyword hint uses spaced terms from hot topic names',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final controller = TimelineController(
      repository: _KeywordHintRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    expect(controller.createTimelineKeywordHint, '例如：霍尔木兹海峡 航运');
  });

  test('guest create uses server topic and restores tracked topic', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final draft = await controller.expandTimelineKeywords('哪吒汽车 资金重组 海外工厂');
    final topic = await controller.createTimelineFromDraft(draft);

    expect(topic.id.startsWith('custom-'), isFalse);
    expect(topic.id.startsWith('topic_custom_'), isTrue);
    expect(controller.trackedTopics.any((item) => item.id == topic.id), isTrue);
    expect(controller.latestEntryForTopic(topic.id), isNull);
    expect(controller.selectedTopicStatus, 'draft');
    expect(controller.selectedTopicInitializationState, 'pending');
    expect(topic.definition, isNotNull);
    expect(topic.definition!.coreKeywords, isNotEmpty);

    final restoredController = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: AppLocalStorage(),
      creationService: MockTimelineCreationService(),
    );
    await restoredController.initialize();

    expect(restoredController.trackedTopics.any((item) => item.id == topic.id),
        isTrue);
    final restoredTopic = restoredController.trackedTopics
        .firstWhere((item) => item.id == topic.id);
    expect(restoredTopic.definition, isNotNull);
    expect(restoredTopic.definition!.coreKeywords, contains('哪吒汽车'));
  });

  test('supports historical explicit dates and long-range bucket granularity',
      () async {
    final service = MockTimelineCreationService();
    final draft = await service.expandKeywords(
      '公元26年4月12日 帝国更替',
      variation: 0,
    );

    expect(draft.startDate.year, 26);
    expect(draft.startDate.month, 4);
    expect(draft.startDate.day, 12);

    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: service,
    );
    await controller.initialize();

    final topic = await controller.createTimelineFromDraft(
      draft,
      startDate: DateTime(26, 4, 12),
    );

    expect(topic.id.startsWith('topic_custom_'), isTrue);
    expect(controller.timelineBuckets, isEmpty);
    expect(controller.selectedTopicInitializationState, 'pending');
  });

  test('expands category from keywords and respects explicit category hint',
      () async {
    final service = MockTimelineCreationService();

    final inferred = await service.expandKeywords(
      '美伊冲突 导弹',
      variation: 0,
    );
    expect(inferred.categoryId, 'military');
    expect(inferred.definition.relatedKeywords, contains('军事行动'));

    final overridden = await service.expandKeywords(
      '美伊冲突 导弹',
      variation: 1,
      categoryHint: 'economy',
    );
    expect(overridden.categoryId, 'economy');
    expect(overridden.tagline, contains('经济'));
    expect(overridden.definition.relatedKeywords, contains('价格波动'));
  });

  test('re-expansion preserves current keywords and filters removed keywords',
      () async {
    final service = MockTimelineCreationService();

    final draft = await service.expandKeywords(
      'spacex 发展',
      variation: 0,
      currentDefinition: const TopicDefinition(
        overview: '',
        includeScope: '',
        excludeScope: '',
        coreKeywords: <String>['spacex', '星舰'],
        relatedKeywords: <String>['资金流向'],
        excludedKeywords: <String>['短线喊单'],
      ),
      removedDefinition: const TopicDefinition(
        overview: '',
        includeScope: '',
        excludeScope: '',
        coreKeywords: <String>['发展'],
        relatedKeywords: <String>['市场反应'],
        excludedKeywords: <String>['无关评论'],
      ),
    );

    expect(draft.definition.coreKeywords.take(2), <String>['spacex', '星舰']);
    expect(draft.definition.coreKeywords, isNot(contains('发展')));
    expect(draft.definition.relatedKeywords.first, '资金流向');
    expect(draft.definition.relatedKeywords, isNot(contains('市场反应')));
    expect(draft.definition.excludedKeywords.first, '短线喊单');
    expect(draft.definition.excludedKeywords, isNot(contains('无关评论')));
  });

  test('http creation service expands topic definition through backend',
      () async {
    final requests = <http.Request>[];
    final apiClient = HttpApiClient(
      baseUrl: 'http://127.0.0.1:8010',
      sessionTokenProvider: () => null,
      guestKeyProvider: () => 'guest-create-key',
      client: MockClient((request) async {
        requests.add(request);
        expect(request.method, 'POST');
        expect(request.url.path, '/topics/expand-definition');
        expect(request.headers['X-Timeliness-Guest-Key'], 'guest-create-key');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['keywords'], '霍尔木兹海峡航运情况');
        expect(body['categoryId'], 'international');
        expect(body['interestCategoryIds'], <String>['finance', 'health']);
        expect(body['currentDefinition'], <String, dynamic>{
          'coreKeywords': <String>['霍尔木兹海峡', '航运'],
          'extendedKeywords': <String>['通航预警'],
          'excludedKeywords': <String>['内陆战况'],
        });
        expect(body['removedDefinition'], <String, dynamic>{
          'coreKeywords': <String>['情况'],
          'extendedKeywords': <String>['旅游攻略'],
          'excludedKeywords': <String>['无关评论'],
        });
        expect(body['selectedDirection'], <String, dynamic>{
          'candidateId': 'candidate_shipping',
          'title': '霍尔木兹海峡航运近期关键进展时间线',
          'trackingDirection': '追踪霍尔木兹海峡航运从通行预警到绕航、保险和能源运输影响的时间线',
          'trackingQuestion': '霍尔木兹海峡航运风险如何影响通行、保险和能源运输？',
          'topicObject': '霍尔木兹海峡航运风险',
          'topicScope': '纳入通行状态、船舶动态、绕航安排、保险费率和官方回应。',
          'timelineType': 'recurring_event_stream',
          'timelineTypeConfidence': 'high',
          'categoryId': 'international',
          'primaryCategory': 'transport_logistics',
          'recentActivityStatus': 'active',
          'trackingViability': 'high',
          'recentEvidenceCount': 3,
          'latestRelevantSourceAt': '2026-05-08T11:30:00.000Z',
          'reason': '近期有多个相关来源，适合持续关注。',
          'isRecommended': true,
        });
        return http.Response(
          jsonEncode(
            <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'keywords': '霍尔木兹海峡 航运',
                'topicName': '霍尔木兹海峡航运进展追踪',
                'title': '霍尔木兹海峡航运进展追踪',
                'tagline': '跟踪霍尔木兹海峡航运的通行变化、运输安排和运营影响',
                'summary':
                    '跟踪霍尔木兹海峡航运通行、油轮动态、保险费率、绕航安排和区域安全风险变化，关注其对能源运输、供应链成本与市场预期的影响。',
                'trackingDirection': '追踪霍尔木兹海峡航运从通行预警到绕航、保险和能源运输影响的时间线',
                'trackingQuestion': '霍尔木兹海峡航运风险如何影响通行、保险和能源运输？',
                'topicObject': '霍尔木兹海峡航运风险',
                'topicScope': '纳入通行状态、船舶动态、绕航安排、保险费率和官方回应。',
                'timelineType': 'recurring_event_stream',
                'timelineFocus': '霍尔木兹海峡航运风险',
                'nodeSelectionPolicy': <String, dynamic>{
                  'include': <String>['直接相关节点'],
                  'exclude': <String>['无关评论'],
                },
                'startDateConfidence': 'medium',
                'timelineTypeConfidence': 'high',
                'sourceEvidenceCount': 4,
                'recentActivityStatus': 'active',
                'recentEvidenceCount': 3,
                'latestRelevantSourceAt': '2026-05-08T11:30:00Z',
                'trackingViability': 'high',
                'trackingViabilityReason': '近期有多个相关来源，适合持续关注。',
                'categoryId': 'international',
                'interestCategoryId': 'international',
                'primaryCategory': 'transport_logistics',
                'categories': <String>['transport_logistics'],
                'startDate': '2026-04-02',
                'topicDefinition': <String, dynamic>{
                  'overview': '围绕「霍尔木兹海峡 航运」建立边界清晰的持续追踪专题。',
                  'includeScope': '纳入通行状态、船舶动态、绕航安排和保险费率变化。',
                  'excludeScope': '排除内陆战况、旅游攻略和没有新增事实的二次解读。',
                  'coreKeywords': <String>['霍尔木兹海峡', '航运'],
                  'extendedKeywords': <String>['通航预警', '绕航安排', '保险费率'],
                  'excludedKeywords': <String>['内陆战况', '旅游攻略'],
                },
              },
            },
          ),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(apiClient.close);

    final service = HttpTimelineCreationService(apiClient);
    final selectedDirection = TimelineDirectionCandidate(
      candidateId: 'candidate_shipping',
      title: '霍尔木兹海峡航运近期关键进展时间线',
      trackingDirection: '追踪霍尔木兹海峡航运从通行预警到绕航、保险和能源运输影响的时间线',
      trackingQuestion: '霍尔木兹海峡航运风险如何影响通行、保险和能源运输？',
      topicObject: '霍尔木兹海峡航运风险',
      topicScope: '纳入通行状态、船舶动态、绕航安排、保险费率和官方回应。',
      timelineType: 'recurring_event_stream',
      timelineTypeConfidence: 'high',
      categoryId: 'international',
      primaryCategory: 'transport_logistics',
      recentActivityStatus: 'active',
      trackingViability: 'high',
      recentEvidenceCount: 3,
      latestRelevantSourceAt: DateTime.utc(2026, 5, 8, 11, 30),
      reason: '近期有多个相关来源，适合持续关注。',
      isRecommended: true,
    );
    final draft = await service.expandKeywords(
      '霍尔木兹海峡航运情况',
      variation: 2,
      categoryHint: 'international',
      interestCategoryIds: const <String>['finance', 'health'],
      selectedDirection: selectedDirection,
      currentDefinition: const TopicDefinition(
        overview: '',
        includeScope: '',
        excludeScope: '',
        coreKeywords: <String>['霍尔木兹海峡', '航运'],
        relatedKeywords: <String>['通航预警'],
        excludedKeywords: <String>['内陆战况'],
      ),
      removedDefinition: const TopicDefinition(
        overview: '',
        includeScope: '',
        excludeScope: '',
        coreKeywords: <String>['情况'],
        relatedKeywords: <String>['旅游攻略'],
        excludedKeywords: <String>['无关评论'],
      ),
    );

    expect(requests, hasLength(1));
    expect(draft.keywords, '霍尔木兹海峡 航运');
    expect(draft.topicName, '霍尔木兹海峡航运进展追踪');
    expect(draft.categoryId, 'international');
    expect(draft.summary, contains('能源运输'));
    expect(
      draft.trackingDirection,
      '追踪霍尔木兹海峡航运从通行预警到绕航、保险和能源运输影响的时间线',
    );
    expect(draft.trackingQuestion, contains('如何影响'));
    expect(draft.topicObject, '霍尔木兹海峡航运风险');
    expect(draft.topicScope, contains('通行状态'));
    expect(draft.timelineType, 'recurring_event_stream');
    expect(draft.timelineFocus, '霍尔木兹海峡航运风险');
    expect(draft.nodeSelectionPolicy['include'], <String>['直接相关节点']);
    expect(draft.startDateConfidence, 'medium');
    expect(draft.timelineTypeConfidence, 'high');
    expect(draft.sourceEvidenceCount, 4);
    expect(draft.recentActivityStatus, 'active');
    expect(draft.recentEvidenceCount, 3);
    expect(draft.latestRelevantSourceAt, DateTime.utc(2026, 5, 8, 11, 30));
    expect(draft.trackingViability, 'high');
    expect(draft.trackingViabilityReason, contains('持续关注'));
    expect(draft.definition.coreKeywords, <String>['霍尔木兹海峡', '航运']);
    expect(draft.definition.recentActivityStatus, 'active');
    expect(draft.definition.recentEvidenceCount, 3);
    expect(draft.definition.latestRelevantSourceAt,
        DateTime.utc(2026, 5, 8, 11, 30));
    expect(draft.definition.trackingViability, 'high');
    expect(draft.definition.trackingViabilityReason, contains('持续关注'));
    expect(draft.definition.relatedKeywords, contains('通航预警'));
    expect(draft.definition.excludedKeywords, contains('内陆战况'));
    expect(draft.startDate, DateTime(2026, 4, 2));
    expect(draft.seedEntries.single.sourceName, 'AI 扩写');
  });

  test('http creation service suggests timeline direction candidates',
      () async {
    final apiClient = HttpApiClient(
      baseUrl: 'http://127.0.0.1:8010',
      sessionTokenProvider: () => null,
      guestKeyProvider: () => 'guest-create-key',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/topics/expand-definition/candidates');
        expect(request.headers['X-Timeliness-Guest-Key'], 'guest-create-key');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['keywords'], '小米汽车事故');
        expect(body['interestCategoryIds'], <String>['society']);
        return http.Response(
          jsonEncode(
            <String, dynamic>{
              'success': true,
              'data': <String, dynamic>{
                'items': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'candidateId': 'candidate_recent',
                    'title': '近期关键事故处置时间线',
                    'trackingDirection': '追踪近期事故发生、回应、调查、处置和后续更新的时间线',
                    'trackingQuestion': '近期事故发生后如何回应和处置？',
                    'topicObject': '近期事故处置过程',
                    'topicScope': '纳入事故发生、官方回应、调查和处置。',
                    'timelineType': 'single_event_lifecycle',
                    'timelineTypeConfidence': 'high',
                    'categoryId': 'society',
                    'primaryCategory': 'public_safety',
                    'recentActivityStatus': 'active',
                    'trackingViability': 'high',
                    'sourceEvidenceCount': 4,
                    'recentEvidenceCount': 2,
                    'latestRelevantSourceAt': '2026-05-09T08:00:00Z',
                    'reason': '近期有多个相关来源。',
                    'isRecommended': true,
                  },
                  <String, dynamic>{
                    'candidateId': 'candidate_stream',
                    'title': '相关事故连续追踪',
                    'trackingDirection': '追踪相关多起事故的发生、调查和后续更新',
                    'trackingQuestion': '相关事故是否持续出现？',
                    'topicObject': '相关事故',
                    'topicScope': '纳入同一范围内的事故节点。',
                    'timelineType': 'recurring_event_stream',
                    'timelineTypeConfidence': 'medium',
                    'categoryId': 'society',
                    'primaryCategory': 'public_safety',
                    'recentActivityStatus': 'active',
                    'trackingViability': 'medium',
                    'sourceEvidenceCount': 2,
                    'recentEvidenceCount': 1,
                    'latestRelevantSourceAt': '2026-05-08T09:00:00Z',
                    'reason': '适合连续追踪。',
                    'isRecommended': false,
                  },
                ],
              },
            },
          ),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(apiClient.close);

    final service = HttpTimelineCreationService(apiClient);
    final candidates = await service.suggestDirections(
      '小米汽车事故',
      interestCategoryIds: const <String>['society'],
    );

    expect(candidates, hasLength(2));
    expect(candidates.first.isRecommended, isTrue);
    expect(candidates.first.title, '近期关键事故处置时间线');
    expect(candidates.first.trackingDirection, contains('时间线'));
    expect(candidates.first.timelineType, 'single_event_lifecycle');
    expect(candidates.first.timelineTypeConfidence, 'high');
    expect(candidates.first.primaryCategory, 'public_safety');
    expect(candidates.first.sourceEvidenceCount, 4);
    expect(
        candidates.first.latestRelevantSourceAt, DateTime.utc(2026, 5, 9, 8));
  });

  test('controller creates topic directly from selected AI direction',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    final remoteService = _CreateAwareTopicRemoteService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      topicRemoteService: remoteService,
    );
    await controller.initialize();

    const candidate = TimelineDirectionCandidate(
      candidateId: 'candidate_recent',
      title: '近期事故处置时间线',
      trackingDirection: '追踪事故发生、回应、调查和处置的时间线',
      trackingQuestion: '事故后如何回应和处置？',
      topicObject: '事故处置过程',
      topicScope: '纳入事故发生、官方回应、调查和处置。',
      timelineType: 'single_event_lifecycle',
      timelineTypeConfidence: 'high',
      categoryId: 'public_safety',
      primaryCategory: '公共安全',
      recentActivityStatus: 'active',
      trackingViability: 'high',
      sourceEvidenceCount: 4,
      recentEvidenceCount: 2,
      reason: '近期有多个相关来源。',
      isRecommended: true,
    );

    final topic = await controller.createTimelineFromDirection(
      keywords: '小米汽车事故',
      candidate: candidate,
    );

    expect(topic.id, isNotEmpty);
    expect(remoteService.lastCreateRequest?.keywords, '小米汽车事故');
    expect(remoteService.lastCreateRequest?.startDate, isNull);
    expect(remoteService.lastCreateRequest?.selectedDirection?.candidateId,
        'candidate_recent');
    expect(remoteService.lastCreateRequest?.definition.trackingDirection,
        candidate.trackingDirection);
    expect(remoteService.lastCreateRequest?.definition.sourceEvidenceCount, 4);
    expect(remoteService.lastCreateRequest?.definition.recentEvidenceCount, 2);
    expect(controller.selectedTopicInitializationState, 'pending');
  });

  test('controller sends low evidence AI direction to backend for decision',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    final remoteService = _CreateAwareTopicRemoteService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      topicRemoteService: remoteService,
    );
    await controller.initialize();

    const candidate = TimelineDirectionCandidate(
      candidateId: 'candidate_low',
      title: '证据不足方向',
      trackingDirection: '追踪没有真实来源支撑的方向',
      trackingQuestion: '没有来源时是否还会创建？',
      topicObject: '低证据方向',
      topicScope: '无真实来源支撑的方向',
      timelineType: 'sequence_chronology',
      timelineTypeConfidence: 'low',
      categoryId: 'society',
      primaryCategory: '社会',
      recentActivityStatus: 'unknown',
      trackingViability: 'low',
      recentEvidenceCount: 0,
      reason: '近期证据不足，建议补充关键词或等待后续来源。',
    );

    final topic = await controller.createTimelineFromDirection(
      keywords: '低证据方向',
      candidate: candidate,
    );

    expect(topic.id, isNotEmpty);
    expect(remoteService.lastCreateRequest?.keywords, '低证据方向');
    expect(remoteService.lastCreateRequest?.selectedDirection?.candidateId,
        'candidate_low');
  });

  test(
      'http creation service polls async expansion job and emits progress clues',
      () async {
    final requests = <http.Request>[];
    var pollCount = 0;
    final apiClient = HttpApiClient(
      baseUrl: 'http://127.0.0.1:8010',
      sessionTokenProvider: () => null,
      guestKeyProvider: () => 'guest-create-key',
      client: MockClient((request) async {
        requests.add(request);
        if (request.method == 'POST' &&
            request.url.path == '/topics/expand-definition/jobs') {
          return http.Response(
            jsonEncode(
              <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'jobId': 'job_001',
                  'status': 'searching',
                  'stage': '正在检索时间轴线索',
                  'progressItems': <Map<String, dynamic>>[],
                  'result': null,
                },
              },
            ),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == '/topics/expand-definition/jobs/job_001') {
          pollCount += 1;
          if (pollCount == 1) {
            return http.Response(
              jsonEncode(
                <String, dynamic>{
                  'success': true,
                  'data': <String, dynamic>{
                    'jobId': 'job_001',
                    'status': 'generating',
                    'stage': '正在整理专题方向',
                    'progressItems': <Map<String, dynamic>>[
                      <String, dynamic>{
                        'date': '2024-03-29',
                        'title': '安徽高速小米汽车事故线索',
                        'sourceTier': 'mainstream_media',
                        'url': 'https://example.com/xiaomi-accident',
                      },
                    ],
                    'result': null,
                  },
                },
              ),
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          return http.Response(
            jsonEncode(
              <String, dynamic>{
                'success': true,
                'data': <String, dynamic>{
                  'jobId': 'job_001',
                  'status': 'done',
                  'stage': '扩写完成',
                  'progressItems': <Map<String, dynamic>>[
                    <String, dynamic>{
                      'date': '2024-03-29',
                      'title': '安徽高速小米汽车事故线索',
                      'sourceTier': 'mainstream_media',
                      'url': 'https://example.com/xiaomi-accident',
                    },
                  ],
                  'result': <String, dynamic>{
                    'keywords': '小米汽车 事故',
                    'topicName': '小米汽车事故时间线',
                    'title': '小米汽车事故时间线',
                    'tagline': '追踪事故发生、回应、调查和处置',
                    'summary': '围绕小米汽车事故建立时间轴。',
                    'categoryId': 'society',
                    'startDate': '2024-03-29',
                    'topicDefinition': <String, dynamic>{
                      'overview': '围绕小米汽车事故建立时间轴。',
                      'includeScope': '纳入事故发生、官方回应和调查处置。',
                      'excludeScope': '排除无事实评论。',
                      'coreKeywords': <String>['小米汽车', '事故'],
                      'extendedKeywords': <String>['官方回应'],
                      'excludedKeywords': <String>['无关股评'],
                    },
                  },
                },
              },
            ),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      }),
    );
    addTearDown(apiClient.close);

    final service = HttpTimelineCreationService(apiClient);
    final progress = <TimelineExpansionProgress>[];
    final draft = await service.expandKeywords(
      '小米汽车事故',
      variation: 0,
      onProgress: progress.add,
    );

    expect(requests.map((request) => request.url.path), <String>[
      '/topics/expand-definition/jobs',
      '/topics/expand-definition/jobs/job_001',
      '/topics/expand-definition/jobs/job_001',
    ]);
    expect(progress, isNotEmpty);
    final clueProgress = progress.firstWhere(
      (item) => item.items.isNotEmpty,
    );
    expect(clueProgress.stage, '正在整理专题方向');
    expect(clueProgress.items.single.title, '安徽高速小米汽车事故线索');
    expect(clueProgress.items.single.date, DateTime(2024, 3, 29));
    expect(draft.topicName, '小米汽车事故时间线');
    expect(draft.startDate, DateTime(2024, 3, 29));
  });

  test('controller passes saved user interest preferences to AI expansion',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    final creationService = _CapturingTimelineCreationService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: creationService,
    );
    await controller.initialize();
    await controller.saveUserInterestCategoryIds(<String>['health', 'finance']);

    await controller.expandTimelineKeywords('霍尔木兹 海峡');

    expect(
        creationService.lastInterestCategoryIds, <String>['health', 'finance']);
  });

  test('controller passes current and removed keyword context to AI expansion',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    final creationService = _CapturingTimelineCreationService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: creationService,
    );
    await controller.initialize();

    const currentDefinition = TopicDefinition(
      overview: '',
      includeScope: '',
      excludeScope: '',
      coreKeywords: <String>['小米汽车'],
      relatedKeywords: <String>['事故调查'],
      excludedKeywords: <String>['无关股评'],
    );
    const removedDefinition = TopicDefinition(
      overview: '',
      includeScope: '',
      excludeScope: '',
      coreKeywords: <String>['情况'],
      relatedKeywords: <String>['营销话术'],
      excludedKeywords: <String>['旧闻复读'],
    );

    await controller.expandTimelineKeywords(
      '小米汽车 安全事故',
      currentDefinition: currentDefinition,
      removedDefinition: removedDefinition,
    );

    expect(creationService.lastCurrentDefinition, currentDefinition);
    expect(creationService.lastRemovedDefinition, removedDefinition);
  });

  test(
      'authenticated create uses remote topic and pending empty timeline state',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final topicRemoteService = _CreateAwareTopicRemoteService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      topicRemoteService: topicRemoteService,
    );
    await controller.initialize();

    final draft = await controller.expandTimelineKeywords('登录用户 服务端创建 专题');
    final topic = await controller.createTimelineFromDraft(draft);

    expect(topic.id.startsWith('custom-'), isFalse);
    expect(topic.id.startsWith('topic_custom_'), isTrue);
    expect(controller.customTopics.any((item) => item.id == topic.id), isFalse);
    expect(controller.trackedTopics.any((item) => item.id == topic.id), isTrue);
    expect(controller.selectedTopicId, topic.id);
    expect(controller.selectedTopicStatus, 'draft');
    expect(controller.selectedTopicInitializationState, 'pending');
    expect(controller.timelineBuckets, isEmpty);
    expect(controller.latestEntryForTopic(topic.id), isNull);
    expect(topicRemoteService.lastCreateRequest, isNotNull);
    final createdDefinition = topicRemoteService.lastCreateRequest!.definition;
    expect(createdDefinition.trackingDirection, draft.trackingDirection);
    expect(createdDefinition.trackingQuestion, draft.trackingQuestion);
    expect(createdDefinition.topicObject, draft.topicObject);
    expect(createdDefinition.topicScope, draft.topicScope);
    expect(createdDefinition.timelineType, draft.timelineType);
    expect(createdDefinition.timelineFocus, draft.timelineFocus);
    expect(createdDefinition.startDateConfidence, draft.startDateConfidence);
    expect(
        createdDefinition.timelineTypeConfidence, draft.timelineTypeConfidence);
    expect(createdDefinition.sourceEvidenceCount, draft.sourceEvidenceCount);
    expect(createdDefinition.recentActivityStatus, draft.recentActivityStatus);
    expect(createdDefinition.recentEvidenceCount, draft.recentEvidenceCount);
    expect(
        createdDefinition.latestRelevantSourceAt, draft.latestRelevantSourceAt);
    expect(createdDefinition.trackingViability, draft.trackingViability);
    expect(createdDefinition.trackingViabilityReason,
        draft.trackingViabilityReason);
  });

  test(
      'cannot create a custom timeline after reaching the authenticated follow limit',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final followedTopics = SampleData.topics.take(10).map((topic) {
      return FollowedTopicItemDto(
        followId: 'follow_${topic.id}',
        topicId: topic.id,
        title: topic.name,
        summary: topic.tagline,
        isPinned: false,
        followedAt: DateTime(2026, 4, 19, 9, 0),
        latestRelevantEventAt: DateTime(2026, 4, 19, 9, 0),
        latestRelevantEventSummary: '${topic.name} 最新动态',
        hasRecentUpdate: true,
      );
    }).toList();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService:
          _FixedFollowLimitRemoteService(followedTopics),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final draft = await controller.expandTimelineKeywords('额度已满 自建专题');

    await expectLater(
      controller.createTimelineFromDraft(draft),
      throwsA(isA<Exception>()),
    );

    expect(controller.trackedTopics.length, 10);
    expect(controller.customTopics, isEmpty);
    expect(controller.errorMessage, '当前最多可关注 10 个专题，升级后可关注更多。');
  });
}

class _KeywordHintRepository extends MockTimelineRepository {
  @override
  Future<List<Topic>> fetchTrackedTopics() async => const <Topic>[];

  @override
  Future<List<Topic>> fetchRecommendedTopics() async => const <Topic>[
        Topic(
          id: 'hormuz-shipping',
          name: '霍尔木兹海峡航运情况',
          tagline: '关注航运风险与通行变化',
          followerCount: 12000,
          isHot: true,
        ),
      ];

  @override
  Future<List<TimelineEntry>> fetchTimeline(String topicId) async =>
      const <TimelineEntry>[];
}

class _CreateAwareTopicRemoteService extends MockTopicRemoteService {
  _CreateAwareTopicRemoteService()
      : super(
          repository: MockTimelineRepository(),
        );

  TopicCreateRequestDto? lastCreateRequest;

  @override
  Future<TopicCreateResultDto> createTopic(TopicCreateRequestDto request) {
    lastCreateRequest = request;
    return super.createTopic(request);
  }
}

class _CapturingTimelineCreationService extends MockTimelineCreationService {
  List<String> lastInterestCategoryIds = const <String>[];
  TopicDefinition? lastCurrentDefinition;
  TopicDefinition? lastRemovedDefinition;
  TimelineDirectionCandidate? lastSelectedDirection;

  @override
  Future<TimelineDraft> expandKeywords(
    String keywords, {
    required int variation,
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
    TopicDefinition? currentDefinition,
    TopicDefinition? removedDefinition,
    TimelineDirectionCandidate? selectedDirection,
    TimelineExpansionProgressCallback? onProgress,
  }) {
    lastInterestCategoryIds = List<String>.from(interestCategoryIds);
    lastCurrentDefinition = currentDefinition;
    lastRemovedDefinition = removedDefinition;
    lastSelectedDirection = selectedDirection;
    return super.expandKeywords(
      keywords,
      variation: variation,
      categoryHint: categoryHint,
      interestCategoryIds: interestCategoryIds,
      currentDefinition: currentDefinition,
      removedDefinition: removedDefinition,
      selectedDirection: selectedDirection,
      onProgress: onProgress,
    );
  }
}

class _FixedFollowLimitRemoteService implements FollowedTopicRemoteService {
  _FixedFollowLimitRemoteService(this._items);

  final List<FollowedTopicItemDto> _items;

  @override
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  }) async {
    return UserCapabilitiesDto(
      authenticated: userId != null,
      accountTier: 'free',
      followLimit: 10,
      followCount: _items.length,
      remainingFollowQuota: 0,
    );
  }

  @override
  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  }) async {
    return FollowedTopicListDto(
      items: List<FollowedTopicItemDto>.from(_items),
      generatedAt: DateTime(2026, 4, 19, 9, 0),
    );
  }

  @override
  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  }) async {
    return GuestFollowMergeResultDto(
      mergedTopicIds: const <String>[],
      alreadyFollowedTopicIds: const <String>[],
      skippedTopicIds: guestTopicIds,
      followCount: _items.length,
      followLimit: 10,
      remainingFollowQuota: 0,
    );
  }

  @override
  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    return GuestTopicClaimResultDto(
      claimedTopicIds: List<String>.from(topicIds),
      alreadyOwnedTopicIds: const <String>[],
      skippedTopicIds: const <String>[],
      followCount: _items.length,
      followLimit: 10,
      remainingFollowQuota: 0,
    );
  }

  @override
  Future<FollowMutationResultDto> followTopic({
    required String userId,
    required String topicId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FollowMutationResultDto> unfollowTopic({
    required String userId,
    required String topicId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FollowMutationResultDto> pinTopic({
    required String userId,
    required String topicId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<FollowMutationResultDto> unpinTopic({
    required String userId,
    required String topicId,
  }) {
    throw UnimplementedError();
  }
}
