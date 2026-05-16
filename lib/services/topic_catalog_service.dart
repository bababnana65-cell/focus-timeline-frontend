import '../models/timeline_models.dart';
import 'timeline_bucketing_service.dart';

class TopicCatalogService {
  const TopicCatalogService({
    TimelineBucketingService? bucketingService,
  }) : _bucketingService = bucketingService ?? const TimelineBucketingService();

  final TimelineBucketingService _bucketingService;

  List<Topic> mergeTopics(
    List<Topic> trackedTopics,
    List<Topic> recommendedTopics,
    List<Topic> customTopics,
    List<Topic> sharedTopics,
    List<Topic> guestTrackedTopics, [
    List<Topic> ownedTopics = const <Topic>[],
  ]) {
    final seen = <String>{};
    return <Topic>[
      ...trackedTopics,
      ...recommendedTopics,
      ...customTopics,
      ...sharedTopics,
      ...guestTrackedTopics,
      ...ownedTopics,
    ].where((topic) => seen.add(topic.id)).toList();
  }

  List<Topic> allTopics({
    required List<Topic> trackedTopics,
    required List<Topic> recommendedTopics,
    required List<Topic> customTopics,
    required List<Topic> sharedTopics,
    required List<Topic> guestTrackedTopics,
    List<Topic> ownedTopics = const <Topic>[],
  }) {
    return mergeTopics(
      trackedTopics,
      recommendedTopics,
      customTopics,
      sharedTopics,
      guestTrackedTopics,
      ownedTopics,
    );
  }

  Topic? selectedTopic({
    required List<Topic> allTopics,
    required String? selectedTopicId,
  }) {
    for (final topic in allTopics) {
      if (topic.id == selectedTopicId) {
        return topic;
      }
    }
    return allTopics.isNotEmpty ? allTopics.first : null;
  }

  List<Topic> orderedTrackedTopics({
    required List<Topic> trackedTopics,
    required List<String> pinnedTopicIds,
    required Map<String, List<TimelineEntry>> entriesByTopic,
    Map<String, TimelineEntry> latestEntriesByTopicId =
        const <String, TimelineEntry>{},
    Map<String, DateTime?> latestActivityAtByTopicId =
        const <String, DateTime?>{},
  }) {
    final topics = List<Topic>.from(trackedTopics);
    final pinnedTopics = <Topic>[];
    for (final pinnedTopicId in pinnedTopicIds) {
      final pinnedIndex =
          topics.indexWhere((topic) => topic.id == pinnedTopicId);
      if (pinnedIndex < 0) {
        continue;
      }
      pinnedTopics.add(topics.removeAt(pinnedIndex));
    }
    topics.sort((a, b) => compareTopicActivity(
          a,
          b,
          entriesByTopic: entriesByTopic,
          latestEntriesByTopicId: latestEntriesByTopicId,
          latestActivityAtByTopicId: latestActivityAtByTopicId,
        ));
    return List<Topic>.unmodifiable(<Topic>[
      ...pinnedTopics,
      ...topics,
    ]);
  }

  List<Topic> timelineSelectionTopics({
    required List<Topic> trackedTopics,
    required Topic? activeTopic,
  }) {
    final topics = <Topic>[...trackedTopics];
    if (activeTopic != null &&
        topics.every((topic) => topic.id != activeTopic.id)) {
      topics.insert(0, activeTopic);
    }
    return topics;
  }

  List<Topic> historyTopics({
    required List<String> historyTopicIds,
    required List<Topic> allTopics,
  }) {
    final topicsById = <String, Topic>{
      for (final topic in allTopics) topic.id: topic,
    };
    return historyTopicIds
        .map((topicId) => topicsById[topicId])
        .whereType<Topic>()
        .toList();
  }

  List<Topic> searchableRecommendationTopics({
    required List<Topic> recommendedTopics,
    required List<Topic> trackedTopics,
    required List<Topic> customTopics,
    required List<Topic> sharedTopics,
  }) {
    final seen = <String>{};
    final topics = <Topic>[
      ...recommendedTopics,
      ...trackedTopics,
      ...customTopics,
      ...sharedTopics,
    ].where((topic) => seen.add(topic.id)).toList();

    topics.sort((a, b) {
      final hotCompare = (b.isHot ? 1 : 0).compareTo(a.isHot ? 1 : 0);
      if (hotCompare != 0) {
        return hotCompare;
      }
      final followerCompare = b.followerCount.compareTo(a.followerCount);
      if (followerCompare != 0) {
        return followerCompare;
      }
      return a.name.compareTo(b.name);
    });
    return topics;
  }

  List<Topic> visibleTrackedTopics({
    required String query,
    required List<Topic> trackedTopics,
    required Map<String, List<TimelineEntry>> entriesByTopic,
    Map<String, TimelineEntry> latestEntriesByTopicId =
        const <String, TimelineEntry>{},
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return trackedTopics.toList();
    }

    return trackedTopics.where((topic) {
      final latestEntry = latestEntriesByTopicId[topic.id] ??
          _bucketingService
              .latestEntry(entriesByTopic[topic.id] ?? const <TimelineEntry>[]);
      return matchesTopicQuery(topic, normalizedQuery) ||
          (latestEntry != null &&
              matchesEntryQuery(latestEntry, normalizedQuery));
    }).toList();
  }

  Topic? findTopicById(String topicId, List<Topic> allTopics) {
    for (final topic in allTopics) {
      if (topic.id == topicId) {
        return topic;
      }
    }
    return null;
  }

  List<String> recordViewedTopic(
    String topicId,
    List<String> historyTopicIds, {
    int limit = 12,
  }) {
    return <String>[
      topicId,
      ...historyTopicIds.where((item) => item != topicId),
    ].take(limit).toList();
  }

  bool matchesTopicQuery(Topic topic, String query) {
    final definition = topic.definition;
    final normalized = <String>[
      topic.name,
      topic.tagline,
      if (definition != null) definition.overview,
      if (definition != null) definition.includeScope,
      if (definition != null) definition.excludeScope,
      if (definition != null) ...definition.coreKeywords,
      if (definition != null) ...definition.relatedKeywords,
      if (definition != null) ...definition.excludedKeywords,
    ].join(' ').toLowerCase();
    return normalized.contains(query);
  }

  bool matchesEntryQuery(TimelineEntry entry, String query) {
    final normalized = <String>[
      entry.title,
      entry.summary,
      entry.detail,
      entry.fullText,
      entry.sourceName,
    ].join(' ').toLowerCase();
    return normalized.contains(query);
  }

  int compareTopicActivity(
    Topic a,
    Topic b, {
    required Map<String, List<TimelineEntry>> entriesByTopic,
    Map<String, TimelineEntry> latestEntriesByTopicId =
        const <String, TimelineEntry>{},
    Map<String, DateTime?> latestActivityAtByTopicId =
        const <String, DateTime?>{},
  }) {
    final aTimestamp = latestActivityAtByTopicId.containsKey(a.id)
        ? latestActivityAtByTopicId[a.id]
        : (latestEntriesByTopicId[a.id] ??
                _bucketingService.latestEntry(
                    entriesByTopic[a.id] ?? const <TimelineEntry>[]))
            ?.timestamp;
    final bTimestamp = latestActivityAtByTopicId.containsKey(b.id)
        ? latestActivityAtByTopicId[b.id]
        : (latestEntriesByTopicId[b.id] ??
                _bucketingService.latestEntry(
                    entriesByTopic[b.id] ?? const <TimelineEntry>[]))
            ?.timestamp;

    if (aTimestamp == null && bTimestamp == null) {
      return a.name.compareTo(b.name);
    }
    if (aTimestamp == null) {
      return 1;
    }
    if (bTimestamp == null) {
      return -1;
    }

    final timeCompare = bTimestamp.compareTo(aTimestamp);
    if (timeCompare != 0) {
      return timeCompare;
    }
    return a.name.compareTo(b.name);
  }
}
