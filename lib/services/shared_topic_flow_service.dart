import '../models/timeline_models.dart';
import 'topic_catalog_service.dart';
import 'topic_share_service.dart';

class SharedTopicFlowService {
  const SharedTopicFlowService({
    TopicCatalogService? topicCatalogService,
  }) : _topicCatalogService = topicCatalogService ?? const TopicCatalogService();

  final TopicCatalogService _topicCatalogService;

  SharedTopicPreview? resolveReferencePreview({
    required ParsedTopicShare parsed,
    required List<Topic> allTopics,
    required bool Function(Topic topic) isFollowing,
  }) {
    final topicId = parsed.topicId;
    if (topicId == null) {
      return null;
    }
    final topic = _topicCatalogService.findTopicById(topicId, allTopics);
    if (topic == null) {
      return null;
    }
    return SharedTopicPreview(
      topic: topic,
      alreadyFollowing: isFollowing(topic),
      allowFollow: true,
      fromImportedPayload: false,
    );
  }

  ImportedSharedTopicResolution? resolveImportedShare({
    required ParsedTopicShare parsed,
    required List<Topic> allTopics,
    required List<Topic> recommendedTopics,
    required List<Topic> customTopics,
    required bool Function(Topic topic) isFollowing,
  }) {
    final importedTopic = parsed.importedTopic;
    if (importedTopic == null) {
      return null;
    }

    final sortedEntries = parsed.importedEntries.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final knownTopic = _topicCatalogService.findTopicById(importedTopic.id, allTopics);
    final resolvedTopic = knownTopic ?? importedTopic;
    final shouldStageAsShared = !isFollowing(resolvedTopic) &&
        recommendedTopics.every((topic) => topic.id != resolvedTopic.id) &&
        customTopics.every((topic) => topic.id != resolvedTopic.id);

    return ImportedSharedTopicResolution(
      topic: resolvedTopic,
      sortedEntries: sortedEntries,
      shouldStageAsShared: shouldStageAsShared,
      preview: SharedTopicPreview(
        topic: resolvedTopic,
        alreadyFollowing: isFollowing(resolvedTopic),
        allowFollow: true,
        fromImportedPayload: true,
      ),
    );
  }

  SharedTopicOpenPlan buildOpenPlan({
    required SharedTopicPreview preview,
    required bool follow,
    required List<Topic> allTopics,
    required List<String> historyTopicIds,
    required bool Function(Topic topic) isFollowing,
    required bool Function(String topicId) hasCustomTopic,
  }) {
    final topic = _topicCatalogService.findTopicById(preview.topic.id, allTopics) ?? preview.topic;
    final shouldAddToTracked = follow && preview.allowFollow && !isFollowing(topic);
    final shouldAddToCustom = shouldAddToTracked &&
        topic.id.startsWith('custom-') &&
        !hasCustomTopic(topic.id);

    return SharedTopicOpenPlan(
      topic: topic,
      shouldAddToTracked: shouldAddToTracked,
      shouldAddToCustom: shouldAddToCustom,
      shouldRemoveFromShared: shouldAddToTracked,
      nextHistoryTopicIds: _topicCatalogService.recordViewedTopic(topic.id, historyTopicIds),
    );
  }
}

class ImportedSharedTopicResolution {
  const ImportedSharedTopicResolution({
    required this.topic,
    required this.sortedEntries,
    required this.shouldStageAsShared,
    required this.preview,
  });

  final Topic topic;
  final List<TimelineEntry> sortedEntries;
  final bool shouldStageAsShared;
  final SharedTopicPreview preview;
}

class SharedTopicOpenPlan {
  const SharedTopicOpenPlan({
    required this.topic,
    required this.shouldAddToTracked,
    required this.shouldAddToCustom,
    required this.shouldRemoveFromShared,
    required this.nextHistoryTopicIds,
  });

  final Topic topic;
  final bool shouldAddToTracked;
  final bool shouldAddToCustom;
  final bool shouldRemoveFromShared;
  final List<String> nextHistoryTopicIds;
}

class SharedTopicPreview {
  const SharedTopicPreview({
    required this.topic,
    required this.alreadyFollowing,
    required this.allowFollow,
    required this.fromImportedPayload,
  });

  final Topic topic;
  final bool alreadyFollowing;
  final bool allowFollow;
  final bool fromImportedPayload;
}
