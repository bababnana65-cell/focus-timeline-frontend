import 'package:event_timeline/dto/followed_topic_dto.dart';
import 'package:event_timeline/dto/recommendation_dto.dart';
import 'package:event_timeline/dto/topic_timeline_dto.dart';
import 'package:event_timeline/mappers/followed_topic_mapper.dart';
import 'package:event_timeline/mappers/recommendation_mapper.dart';
import 'package:event_timeline/mappers/topic_timeline_mapper.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/widgets/timeline_signal_resolver.dart';
import 'package:event_timeline/widgets/topic_icon_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recommendation projection preserves category and latest node fields',
      () {
    final response = RecommendationResponseDto.fromJson(<String, dynamic>{
      'sections': <Map<String, dynamic>>[
        <String, dynamic>{
          'sectionKey': 'hot',
          'sectionTitle': '当前热门',
          'items': <Map<String, dynamic>>[
            _recommendationItemJson(),
          ],
        },
      ],
      'history': <dynamic>[],
      'generatedAt': '2026-05-03T14:40:24Z',
    });

    final projection = const RecommendationMapper().project(
      response,
      existingTopics: const <Topic>[],
    );

    final topic = projection.hotTopics.single;
    expect(topic.primaryCategory, 'technology_ai');
    expect(topic.categories,
        containsAll(<String>['technology_ai', 'finance_capital']));
    expect(topic.categoryConfidence, 0.87);

    final latestEntry = projection.latestEntriesByTopicId[topic.id];
    expect(latestEntry, isNotNull);
    expect(latestEntry!.id, 'node-1');
    expect(latestEntry.summary, '今天确认首批量产排期。');
    expect(latestEntry.primarySignal, 'technology_update');
  });

  test('followed topic DTO prefers unread and latest node contract fields', () {
    final item = FollowedTopicItemDto.fromJson(<String, dynamic>{
      'followId': 'follow-1',
      'topicId': 'topic-1',
      'title': '端侧AI芯片量产进展',
      'summary': '关注AI芯片、模型适配、量产排期和生态工具更新',
      'primaryCategory': 'technology_ai',
      'categories': <String>['technology_ai'],
      'categoryConfidence': 0.95,
      'isPinned': false,
      'followedAt': '2026-04-01T00:00:00Z',
      'latestRelevantEventAt': '2026-04-20T00:00:00Z',
      'latestRelevantEventSummary': '旧摘要',
      'hasRecentUpdate': false,
      'unreadSignalCount': 0,
      'latestNode': _latestNodeJson(),
      'hasUnreadUpdate': true,
      'unreadNodeCount': 2,
    });

    expect(item.hasRecentUpdate, isTrue);
    expect(item.unreadSignalCount, 2);
    expect(item.latestNode?.headline, '今天确认首批量产排期');

    final topic = const FollowedTopicMapper().toTopic(item);
    expect(topic.primaryCategory, 'technology_ai');

    final latestEntry =
        const FollowedTopicMapper().toLatestEntry(item, topic: topic);
    expect(latestEntry, isNotNull);
    expect(latestEntry!.id, 'node-1');
    expect(latestEntry.timestamp, DateTime.parse('2026-05-03T14:27:00Z'));
    expect(latestEntry.summary, '今天确认首批量产排期。');
    expect(latestEntry.primarySignal, 'technology_update');
  });

  test('topic timeline DTO maps stats, category, and entry signals', () {
    final response = TopicTimelineResponseDto.fromJson(<String, dynamic>{
      'topic': <String, dynamic>{
        'topicId': 'topic-1',
        'title': '美伊战争总体进展',
        'summary': '跟踪冲突升级、军事动作、外交回应和阶段变化',
        'primaryCategory': 'military_security',
        'categories': <String>['military_security', 'diplomacy_policy'],
        'categoryConfidence': 0.79,
        'isFollowed': false,
      },
      'stats': <String, dynamic>{
        'bucketCount': 6,
        'entryCount': 10,
        'majorCount': 8,
        'startedAt': '2026-04-04T03:30:00Z',
        'eventNodeCount': 6,
        'dynamicCount': 10,
        'majorNodeCount': 5,
        'latestEventAt': '2026-05-03T15:45:00Z',
        'trackingDays': 30,
      },
      'filters': <String, dynamic>{
        'defaultOrder': 'asc',
        'supportsMajorOnly': true,
      },
      'entries': <Map<String, dynamic>>[
        _timelineEntryJson(),
      ],
      'page': <String, dynamic>{
        'hasMore': false,
        'nextCursor': null,
      },
    });

    expect(response.stats.startedAt, DateTime.parse('2026-04-04T03:30:00Z'));
    expect(response.stats.eventNodeCount, 6);
    expect(response.stats.dynamicCount, 10);
    expect(response.stats.majorNodeCount, 5);
    expect(
        response.stats.latestEventAt, DateTime.parse('2026-05-03T15:45:00Z'));
    expect(response.stats.trackingDays, 30);

    const mapper = TopicTimelineMapper();
    final topic = mapper.toTopic(response.topic);
    expect(topic.primaryCategory, 'military_security');

    final entry = mapper.toTimelineEntries(response).single;
    expect(entry.sourceName, '后端联调样本源');
    expect(entry.sourceProvider, 'serpapi_baidu');
    expect(entry.primarySignal, 'diplomacy_response');
    expect(entry.signals,
        containsAll(<String>['diplomacy_response', 'military_action']));
    expect(entry.signalConfidence, 0.69);
  });

  test('visual resolvers prefer backend labels before keyword fallback', () {
    const topic = Topic(
      id: 'topic-1',
      name: '战争风险中的芯片供应',
      tagline: '名称容易误导，但后端已判定为科技AI',
      followerCount: 0,
      isHot: false,
      primaryCategory: 'technology_ai',
      categories: <String>['technology_ai'],
    );
    expect(TopicIconResolver.resolve(topic).label, 'AI');

    final bucket = TimelineBucket(
      id: 'bucket-1',
      periodStart: DateTime.parse('2026-05-03T00:00:00Z'),
      granularity: TimelineGranularity.day,
      label: '今天',
      headline: '导弹消息引发油价波动',
      entries: <TimelineEntry>[
        TimelineEntry(
          id: 'entry-1',
          topicId: 'topic-1',
          title: '导弹消息引发油价波动',
          summary: '文本会命中军事，但后端标注为市场反应。',
          detail: '文本会命中军事，但后端标注为市场反应。',
          fullText: '文本会命中军事，但后端标注为市场反应。',
          sourceName: '测试',
          timestamp: DateTime.parse('2026-05-03T15:45:00Z'),
          isMajor: false,
          primarySignal: 'market_reaction',
          signals: <String>['market_reaction', 'military_action'],
        ),
      ],
    );
    expect(TimelineSignalResolver.resolve(bucket).label, '市场反应');
  });

  test('topic icon resolver covers backend standard category ids', () {
    const expectedLabelsByCategory = <String, String>{
      'military_security': '军事安全',
      'diplomacy_policy': '外交政策',
      'policy_regulation': '政策监管',
      'legal_regulation': '法律司法',
      'economy_market': '宏观经济',
      'finance_capital': '金融市场',
      'enterprise_business': '公司商业',
      'industry_chain': '产业链',
      'technology_ai': 'AI',
      'semiconductor_chip': '半导体',
      'cybersecurity': '网络安全',
      'aerospace': '航天航空',
      'automotive_ev': '新能源车',
      'energy_supply': '能源',
      'transport_logistics': '交通物流',
      'infrastructure_real_estate': '基建地产',
      'public_safety': '公共安全',
      'disaster_accident': '灾害事故',
      'social_public': '社会民生',
      'health_medical': '医疗健康',
      'biotech_pharma': '生物医药',
      'education_research': '教育研究',
      'environment_climate': '环境',
      'culture_media': '文化媒体',
      'sports_events': '体育赛事',
      'general_event': '通用事件',
    };

    for (final entry in expectedLabelsByCategory.entries) {
      final topic = Topic(
        id: 'topic-${entry.key}',
        name: '后端分类样本',
        tagline: '没有关键词，必须依赖 primaryCategory',
        followerCount: 0,
        isHot: false,
        primaryCategory: entry.key,
      );

      expect(
        TopicIconResolver.resolve(topic).label,
        entry.value,
        reason: 'category ${entry.key} should have a standard icon mapping',
      );
    }
  });
}

Map<String, dynamic> _recommendationItemJson() {
  return <String, dynamic>{
    'topicId': 'topic-1',
    'title': '端侧AI芯片量产进展',
    'summary': '关注AI芯片、模型适配、量产排期和生态工具更新',
    'primaryCategory': 'technology_ai',
    'categories': <String>['technology_ai', 'finance_capital'],
    'categoryConfidence': 0.87,
    'isFollowed': false,
    'recommendationSource': 'hot',
    'reasonCode': 'GLOBAL_HEAT_UP',
    'reason': '全站热度上升',
    'score': 0.58,
    'latestNode': _latestNodeJson(),
    'hasUnreadUpdate': false,
    'unreadNodeCount': 0,
  };
}

Map<String, dynamic> _latestNodeJson() {
  return <String, dynamic>{
    'id': 'node-1',
    'occurredAt': '2026-05-03T14:27:00Z',
    'headline': '今天确认首批量产排期',
    'summary': '今天确认首批量产排期。',
    'isMajor': true,
    'primarySignal': 'technology_update',
    'signals': <String>['technology_update', 'follow_up'],
    'signalConfidence': 0.88,
  };
}

Map<String, dynamic> _timelineEntryJson() {
  return <String, dynamic>{
    'timelineEntryId': 'timeline-1',
    'eventNodeId': 'node-1',
    'topicEventLinkId': 'link-1',
    'topicId': 'topic-1',
    'title': '今日外交沟通窗口重新打开',
    'summary': '沟通渠道重新出现短期缓和信号。',
    'primarySignal': 'diplomacy_response',
    'signals': <String>['diplomacy_response', 'military_action'],
    'signalConfidence': 0.69,
    'detail': '这是一条后端联调样本。',
    'eventTime': '2026-05-03T09:30:00Z',
    'sortTime': '2026-05-03T09:30:00Z',
    'displayDateLabel': '5月3日 09:30',
    'precision': 'minute',
    'relationType': 'primary',
    'relevanceScore': 1.0,
    'importanceLevel': 'critical',
    'reviewStatus': 'pending',
    'contextualMajor': true,
    'contextTag': '',
    'bucketKey': '2026-05-03T00:00:00Z',
    'bucketLabel': '5月3日',
    'bucketStart': '2026-05-03T00:00:00Z',
    'bucketGranularity': 'day',
    'primarySource': <String, dynamic>{
      'sourceId': 'source-1',
      'sourceName': '后端联调样本源',
      'sourceType': 'official',
      'sourceUrl': '',
      'sourceProvider': 'serpapi_baidu',
      'reliability': 0.9,
    },
    'sources': <dynamic>[],
    'dynamicCount': 0,
  };
}
