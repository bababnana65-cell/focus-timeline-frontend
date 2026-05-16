import '../dto/followed_topic_dto.dart';
import '../models/timeline_models.dart';

class FollowedTopicMapper {
  const FollowedTopicMapper();

  Topic toTopic(
    FollowedTopicItemDto dto, {
    Topic? fallbackTopic,
  }) {
    final title =
        dto.title.trim().isNotEmpty ? dto.title : (fallbackTopic?.name ?? '');
    final summary = dto.summary.trim().isNotEmpty
        ? dto.summary
        : (fallbackTopic?.tagline ?? '');
    return Topic(
      id: dto.topicId,
      name: title,
      tagline: summary,
      followerCount: fallbackTopic?.followerCount ?? 0,
      isHot: fallbackTopic?.isHot ?? false,
      definition: fallbackTopic?.definition,
      primaryCategory: dto.primaryCategory ?? fallbackTopic?.primaryCategory,
      categories: dto.categories.isNotEmpty
          ? dto.categories
          : (fallbackTopic?.categories ?? const <String>[]),
      categoryConfidence:
          dto.categoryConfidence ?? fallbackTopic?.categoryConfidence,
    );
  }

  List<Topic> toTopics(
    Iterable<FollowedTopicItemDto> items, {
    required List<Topic> existingTopics,
  }) {
    final topicsById = <String, Topic>{
      for (final topic in existingTopics) topic.id: topic,
    };
    return items
        .map((item) => toTopic(item, fallbackTopic: topicsById[item.topicId]))
        .toList();
  }

  List<String> pinnedTopicIds(Iterable<FollowedTopicItemDto> items) {
    return items
        .where((item) => item.isPinned)
        .map((item) => item.topicId)
        .toList();
  }

  Map<String, TimelineEntry> toLatestEntriesByTopicId(
    Iterable<FollowedTopicItemDto> items, {
    required List<Topic> topics,
  }) {
    final topicsById = <String, Topic>{
      for (final topic in topics) topic.id: topic,
    };
    final mapped = <String, TimelineEntry>{};
    for (final item in items) {
      final topic = topicsById[item.topicId];
      if (topic == null) {
        continue;
      }
      final latestEntry = toLatestEntry(item, topic: topic);
      if (latestEntry != null) {
        mapped[item.topicId] = latestEntry;
      }
    }
    return mapped;
  }

  TimelineEntry? toLatestEntry(
    FollowedTopicItemDto dto, {
    required Topic topic,
  }) {
    final latestNode = dto.latestNode;
    if (latestNode != null) {
      final summary = latestNode.summary.trim().isNotEmpty
          ? latestNode.summary.trim()
          : latestNode.headline.trim();
      return TimelineEntry(
        id: latestNode.id.isNotEmpty
            ? latestNode.id
            : 'followed-${dto.followId}',
        topicId: dto.topicId,
        title: latestNode.headline.trim().isNotEmpty
            ? latestNode.headline.trim()
            : topic.name,
        summary: summary.isNotEmpty ? summary : topic.tagline,
        detail: summary.isNotEmpty ? summary : topic.tagline,
        fullText: summary.isNotEmpty ? summary : topic.tagline,
        sourceName: '服务端同步',
        sourceKind: SourceKind.aggregator,
        sourceReliability: SourceReliability.medium,
        timestamp: latestNode.occurredAt,
        isMajor: latestNode.isMajor,
        primarySignal: latestNode.primarySignal,
        signals: latestNode.signals,
        signalConfidence: latestNode.signalConfidence,
      );
    }

    final eventTime = dto.effectiveLatestEventAt ?? dto.followedAt;
    final summary = dto.effectiveLatestEventSummary?.trim();
    if (summary == null || summary.isEmpty) {
      return TimelineEntry(
        id: 'followed-${dto.followId}',
        topicId: dto.topicId,
        title: topic.name,
        summary: topic.tagline,
        detail: topic.tagline,
        fullText: topic.tagline,
        sourceName: '服务端同步',
        sourceKind: SourceKind.aggregator,
        sourceReliability: SourceReliability.medium,
        timestamp: eventTime,
        isMajor: false,
      );
    }

    return TimelineEntry(
      id: 'followed-${dto.followId}',
      topicId: dto.topicId,
      title: topic.name,
      summary: summary,
      detail: summary,
      fullText: summary,
      sourceName: '服务端同步',
      sourceKind: SourceKind.aggregator,
      sourceReliability: SourceReliability.medium,
      timestamp: eventTime,
      isMajor: false,
    );
  }
}
