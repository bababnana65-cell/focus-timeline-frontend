import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/topic_share_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = TopicShareService();

  test('builds and parses a built-in topic share link', () {
    const topic = Topic(
      id: 'ai-model-release',
      name: 'AI 大模型发布',
      tagline: '追踪模型发布时间、功能更新与外部反馈',
      followerCount: 18240,
      isHot: true,
    );

    final link = service.buildShareLink(
      topic: topic,
      entries: const <TimelineEntry>[],
    );
    final parsed = service.parseIncomingRoute(link);

    expect(parsed, isNotNull);
    expect(parsed!.isImportedPayload, isFalse);
    expect(parsed.topicId, topic.id);
  });

  test('builds and parses a custom topic share payload', () {
    const topic = Topic(
      id: 'custom-168001',
      name: '伊朗 / 美国战事时间线',
      tagline: '持续追踪外部表态、地缘风险与关键节点',
      followerCount: 1,
      isHot: false,
      definition: TopicDefinition(
        overview: '围绕伊朗与美国战事建立可持续追踪的专题。',
        includeScope: '纳入冲突升级、导弹发射、外交表态和制裁变化。',
        excludeScope: '排除泛评论和弱相关旧闻。',
        coreKeywords: <String>['伊朗', '美国', '战事'],
        relatedKeywords: <String>['导弹发射', '停火信号'],
        excludedKeywords: <String>['泛讨论'],
      ),
    );
    final entries = <TimelineEntry>[
      TimelineEntry(
        id: 'entry-1',
        topicId: topic.id,
        title: '事件起点',
        summary: '冲突从这里进入持续追踪阶段。',
        detail: '第一阶段详情。',
        fullText: '第一阶段全文。',
        sourceName: '整理稿',
        timestamp: DateTime(2025, 4, 1, 8),
        isMajor: true,
      ),
    ];

    final link = service.buildShareLink(
      topic: topic,
      entries: entries,
    );
    final parsed = service.parseIncomingRoute(link);

    expect(parsed, isNotNull);
    expect(parsed!.isImportedPayload, isTrue);
    expect(parsed.importedTopic?.name, topic.name);
    expect(parsed.importedTopic?.definition?.coreKeywords, contains('伊朗'));
    expect(parsed.importedEntries.single.summary, entries.single.summary);
  });

  test('parses token-based share route from https url', () {
    final parsed = service.parseIncomingRoute(
      'https://example.com/share/share_ai-model-release',
    );

    expect(parsed, isNotNull);
    expect(parsed!.isShareToken, isTrue);
    expect(parsed.shareToken, 'share_ai-model-release');
  });
}
