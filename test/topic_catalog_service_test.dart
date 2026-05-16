import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/topic_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'orders pinned topics first and remaining tracked topics by latest node time',
      () {
    const service = TopicCatalogService();
    const pinned = Topic(
      id: 'pinned-topic',
      name: '置顶专题',
      tagline: '置顶保持最前',
      followerCount: 0,
      isHot: false,
    );
    const oldTopic = Topic(
      id: 'old-topic',
      name: '较早节点',
      tagline: '较早节点',
      followerCount: 0,
      isHot: false,
    );
    const newTopic = Topic(
      id: 'new-topic',
      name: '最新节点',
      tagline: '最新节点',
      followerCount: 0,
      isHot: false,
    );
    const untimedTopic = Topic(
      id: 'untimed-topic',
      name: '暂无节点',
      tagline: '暂无节点',
      followerCount: 0,
      isHot: false,
    );

    final ordered = service.orderedTrackedTopics(
      trackedTopics: const <Topic>[
        oldTopic,
        pinned,
        untimedTopic,
        newTopic,
      ],
      pinnedTopicIds: const <String>['pinned-topic'],
      entriesByTopic: const <String, List<TimelineEntry>>{},
      latestEntriesByTopicId: <String, TimelineEntry>{
        'untimed-topic': TimelineEntry(
          id: 'followed-untimed-topic',
          topicId: 'untimed-topic',
          title: '暂无节点',
          summary: '暂无节点',
          detail: '暂无节点',
          fullText: '暂无节点',
          sourceName: '服务端同步',
          timestamp: DateTime(2026, 5, 1),
          isMajor: false,
        ),
      },
      latestActivityAtByTopicId: <String, DateTime?>{
        'old-topic': DateTime(2026, 4, 7),
        'new-topic': DateTime(2026, 4, 25),
        'untimed-topic': null,
      },
    );

    expect(
      ordered.map((topic) => topic.id),
      <String>[
        'pinned-topic',
        'new-topic',
        'old-topic',
        'untimed-topic',
      ],
    );
  });
}
