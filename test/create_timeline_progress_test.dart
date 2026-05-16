import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:event_timeline/models/timeline_creation_models.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/http_api_client.dart';
import 'package:event_timeline/services/remote/topic_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:event_timeline/dto/topic_timeline_dto.dart';
import 'package:event_timeline/widgets/create_timeline_sheet.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  testWidgets('create sheet shows weak candidate clues while AI is working',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: _ProgressTimelineCreationService(),
    );
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showCreateTimelineSheet(context, controller);
              },
              child: const Text('打开创建'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('打开创建'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.enterText(find.byType(TextField).last, '小米汽车事故');
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('候选线索'), findsOneWidget);
    expect(find.text('正在整理专题方向'), findsOneWidget);
    expect(
      find.textContaining('围绕“小米汽车事故”整理专题方向和简介'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('小米汽车事故进展追踪'), findsWidgets);
    expect(find.text('AI 理解'), findsOneWidget);
    expect(find.textContaining('追踪事故发生到回应处置的时间线'), findsOneWidget);
    expect(find.text('近期更新较少'), findsOneWidget);
    expect(find.textContaining('后续可能更新不频繁'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets('create sheet lets user choose an AI timeline direction first',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final creationService = _CandidateTimelineCreationService();
    final topicRemoteService = _RecordingTopicRemoteService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: creationService,
      topicRemoteService: topicRemoteService,
    );
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showCreateTimelineSheet(context, controller);
              },
              child: const Text('打开创建'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('打开创建'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.enterText(find.byType(TextField).last, '小米汽车事故');
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('AI 建议追踪方向'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('近期事故处置时间线'), findsOneWidget);
    expect(find.text('相关事故连续追踪'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '确定'), findsNothing);
    expect(find.text('小米汽车事故进展追踪'), findsNothing);
    final clueCard = find.byKey(
      const ValueKey<String>('ai-expansion-progress-clues'),
    );
    expect(find.text('候选线索'), findsOneWidget);
    expect(
      find.descendant(
        of: clueCard,
        matching: find.textContaining('追踪事故发生、回应、调查和处置的时间线'),
      ),
      findsOneWidget,
    );
    expect(creationService.expandCallCount, 0);

    await tester.tap(find.text('近期事故处置时间线'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(creationService.expandCallCount, 0);
    expect(topicRemoteService.lastCreateRequest?.keywords, '小米汽车事故');
    expect(topicRemoteService.lastCreateRequest?.selectedDirection?.candidateId,
        'candidate_recent');
    expect(find.text('AI 建议追踪方向'), findsNothing);
    controller.dispose();
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets('create sheet shows backend 409 for low evidence directions',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final topicRemoteService = _RejectingLowEvidenceTopicRemoteService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: _LowEvidenceCandidateTimelineCreationService(),
      topicRemoteService: topicRemoteService,
    );
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showCreateTimelineSheet(context, controller);
              },
              child: const Text('打开创建'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('打开创建'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.enterText(find.byType(TextField).last, '低证据方向');
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('证据不足方向'), findsOneWidget);
    expect(find.text('暂无足够来源'), findsOneWidget);

    await tester.tap(find.text('证据不足方向'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      topicRemoteService.lastCreateRequest?.selectedDirection?.candidateId,
      'candidate_low',
    );
    expect(
      find.textContaining('暂无足够真实来源'),
      findsOneWidget,
    );
    controller.dispose();
  }, timeout: const Timeout(Duration(seconds: 10)));

  testWidgets('create sheet shows search clues while finding AI directions',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: _SlowCandidateTimelineCreationService(),
    );
    await tester.runAsync(controller.initialize);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return FilledButton(
              onPressed: () {
                showCreateTimelineSheet(context, controller);
              },
              child: const Text('打开创建'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('打开创建'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    await tester.enterText(find.byType(TextField).last, '小米汽车事故');
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.text('候选线索'), findsOneWidget);
    expect(find.text('正在检索时间轴线索'), findsOneWidget);
    expect(
      find.textContaining('小米汽车事故”起点：首次爆发、官方表态、关键时间'),
      findsOneWidget,
    );

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('AI 建议追踪方向'), findsOneWidget);
    expect(find.text('近期事故处置时间线'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 10)));
}

class _ProgressTimelineCreationService extends MockTimelineCreationService {
  @override
  Future<List<TimelineDirectionCandidate>> suggestDirections(
    String keywords, {
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
  }) {
    throw StateError('candidate stage unavailable');
  }

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
  }) async {
    onProgress?.call(
      TimelineExpansionProgress(
        status: 'generating',
        stage: '正在整理专题方向',
        items: <TimelineExpansionProgressItem>[
          TimelineExpansionProgressItem(
            title: '安徽高速小米汽车事故线索',
            date: DateTime(2024, 3, 29),
            sourceTier: 'mainstream_media',
            url: 'https://example.com/xiaomi-accident',
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return TimelineDraft(
      keywords: '小米汽车 事故',
      topicName: '小米汽车事故进展追踪',
      tagline: '追踪事故发生、回应、调查和处置',
      summary: '围绕小米汽车事故建立时间轴。',
      categoryId: 'society',
      trackingDirection: '追踪事故发生到回应处置的时间线',
      trackingQuestion: '事故发生后经历了哪些回应、调查和处置节点？',
      topicObject: '事故处置过程',
      topicScope: '纳入事故发生、官方回应和调查处置。',
      timelineType: 'single_event_lifecycle',
      timelineFocus: '事故处置过程',
      startDateConfidence: 'medium',
      timelineTypeConfidence: 'high',
      sourceEvidenceCount: 2,
      recentActivityStatus: 'quiet',
      recentEvidenceCount: 0,
      trackingViability: 'low',
      trackingViabilityReason: '近期更新较少，适合作为历史时间线阅读；后续可能更新不频繁。',
      definition: const TopicDefinition(
        overview: '围绕小米汽车事故建立时间轴。',
        includeScope: '纳入事故发生、官方回应和调查处置。',
        excludeScope: '排除无事实评论。',
        coreKeywords: <String>['小米汽车', '事故'],
        relatedKeywords: <String>['官方回应'],
        excludedKeywords: <String>['无关股评'],
        trackingDirection: '追踪事故发生到回应处置的时间线',
        trackingQuestion: '事故发生后经历了哪些回应、调查和处置节点？',
        topicObject: '事故处置过程',
        topicScope: '纳入事故发生、官方回应和调查处置。',
        timelineType: 'single_event_lifecycle',
        timelineFocus: '事故处置过程',
        startDateConfidence: 'medium',
        timelineTypeConfidence: 'high',
        sourceEvidenceCount: 2,
        recentActivityStatus: 'quiet',
        recentEvidenceCount: 0,
        trackingViability: 'low',
        trackingViabilityReason: '近期更新较少，适合作为历史时间线阅读；后续可能更新不频繁。',
      ),
      seedEntries: <TimelineEntry>[
        TimelineEntry(
          id: 'draft-xiaomi-accident',
          topicId: 'draft',
          title: '事件起点识别',
          summary: '围绕小米汽车事故建立时间轴。',
          detail: '候选线索已用于生成专题草案。',
          fullText: '候选线索已用于生成专题草案。',
          sourceName: 'AI 扩写',
          timestamp: DateTime(2024, 3, 29),
          isMajor: true,
        ),
      ],
    );
  }
}

class _CandidateTimelineCreationService extends MockTimelineCreationService {
  int expandCallCount = 0;
  TimelineDirectionCandidate? lastSelectedDirection;

  @override
  Future<List<TimelineDirectionCandidate>> suggestDirections(
    String keywords, {
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
  }) async {
    return <TimelineDirectionCandidate>[
      TimelineDirectionCandidate(
        candidateId: 'candidate_recent',
        title: '近期事故处置时间线',
        trackingDirection: '追踪事故发生、回应、调查和处置的时间线',
        trackingQuestion: '事故后如何回应和处置？',
        topicObject: '事故处置过程',
        topicScope: '纳入事故发生、官方回应、调查和处置。',
        categoryId: 'society',
        primaryCategory: 'public_safety',
        recentActivityStatus: 'active',
        trackingViability: 'high',
        recentEvidenceCount: 2,
        latestRelevantSourceAt: DateTime.utc(2026, 5, 9, 8),
        reason: '近期有多个相关来源。',
        isRecommended: true,
      ),
      const TimelineDirectionCandidate(
        candidateId: 'candidate_stream',
        title: '相关事故连续追踪',
        trackingDirection: '追踪相关多起事故的发生、调查和后续更新',
        trackingQuestion: '相关事故是否持续出现？',
        topicObject: '相关事故',
        topicScope: '纳入同一范围内的事故节点。',
        categoryId: 'society',
        primaryCategory: 'public_safety',
        recentActivityStatus: 'active',
        trackingViability: 'medium',
        recentEvidenceCount: 1,
        reason: '适合连续追踪。',
      ),
    ];
  }

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
  }) async {
    expandCallCount += 1;
    lastSelectedDirection = selectedDirection;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return TimelineDraft(
      keywords: '小米汽车 事故',
      topicName: '小米汽车事故进展追踪',
      tagline: '追踪事故发生、回应、调查和处置',
      summary: '围绕小米汽车事故建立时间轴。',
      categoryId: selectedDirection?.categoryId ?? 'society',
      trackingDirection: selectedDirection?.trackingDirection ?? '',
      trackingQuestion: selectedDirection?.trackingQuestion ?? '',
      topicObject: selectedDirection?.topicObject ?? '',
      topicScope: selectedDirection?.topicScope ?? '',
      definition: TopicDefinition(
        overview: '围绕小米汽车事故建立时间轴。',
        includeScope: selectedDirection?.topicScope ?? '',
        excludeScope: '排除无事实评论。',
        coreKeywords: const <String>['小米汽车', '事故'],
        relatedKeywords: const <String>['官方回应'],
        excludedKeywords: const <String>['无关股评'],
        trackingDirection: selectedDirection?.trackingDirection ?? '',
        trackingQuestion: selectedDirection?.trackingQuestion ?? '',
        topicObject: selectedDirection?.topicObject ?? '',
        topicScope: selectedDirection?.topicScope ?? '',
      ),
      seedEntries: <TimelineEntry>[
        TimelineEntry(
          id: 'draft-xiaomi-accident',
          topicId: 'draft',
          title: '事件起点识别',
          summary: '围绕小米汽车事故建立时间轴。',
          detail: '候选方向已用于生成专题草案。',
          fullText: '候选方向已用于生成专题草案。',
          sourceName: 'AI 扩写',
          timestamp: DateTime(2024, 3, 29),
          isMajor: true,
        ),
      ],
    );
  }
}

class _RecordingTopicRemoteService extends MockTopicRemoteService {
  _RecordingTopicRemoteService()
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

class _RejectingLowEvidenceTopicRemoteService
    extends _RecordingTopicRemoteService {
  @override
  Future<TopicCreateResultDto> createTopic(TopicCreateRequestDto request) {
    lastCreateRequest = request;
    throw const HttpApiException(
      message: '该方向暂无足够真实来源，建议补充关键词后再生成时间线。',
      code: 'TOPIC_DIRECTION_NOT_INITIALIZABLE',
      statusCode: 409,
    );
  }
}

class _LowEvidenceCandidateTimelineCreationService
    extends MockTimelineCreationService {
  @override
  Future<List<TimelineDirectionCandidate>> suggestDirections(
    String keywords, {
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
  }) async {
    return const <TimelineDirectionCandidate>[
      TimelineDirectionCandidate(
        candidateId: 'candidate_low',
        title: '证据不足方向',
        trackingDirection: '追踪没有真实来源支撑的方向',
        trackingQuestion: '没有来源时是否还会创建？',
        topicObject: '低证据方向',
        topicScope: '无真实来源支撑的方向',
        categoryId: 'society',
        primaryCategory: '社会',
        recentActivityStatus: 'unknown',
        trackingViability: 'low',
        recentEvidenceCount: 0,
        reason: '近期证据不足，建议补充关键词或等待后续来源。',
      ),
    ];
  }
}

class _SlowCandidateTimelineCreationService
    extends _CandidateTimelineCreationService {
  @override
  Future<List<TimelineDirectionCandidate>> suggestDirections(
    String keywords, {
    String? categoryHint,
    List<String> interestCategoryIds = const <String>[],
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return super.suggestDirections(
      keywords,
      categoryHint: categoryHint,
      interestCategoryIds: interestCategoryIds,
    );
  }
}
