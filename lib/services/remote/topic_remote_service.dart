import '../../dto/topic_timeline_dto.dart';
import '../../dto/followed_topic_dto.dart';
import '../../models/timeline_models.dart';
import '../mock_timeline_repository.dart';
import '../timeline_bucketing_service.dart';

abstract class TopicRemoteService {
  Future<TopicDetailDto> fetchTopicDetail(String topicId);

  Future<TopicTimelineResponseDto> fetchTopicTimeline(String topicId);

  Future<MyTopicListDto> fetchMyTopics();

  Future<TopicCreateResultDto> createTopic(TopicCreateRequestDto request);

  Future<TopicInitializationRetryResultDto> retryTopicInitialization(
      String topicId);

  Future<TimelineSearchResultDto> searchTimeline({
    required String topicId,
    required String query,
  });
}

class MockTopicRemoteService implements TopicRemoteService {
  MockTopicRemoteService({
    required TimelineRepository repository,
    TimelineBucketingService? bucketingService,
  })  : _repository = repository,
        _bucketingService =
            bucketingService ?? const TimelineBucketingService();

  final TimelineRepository _repository;
  final TimelineBucketingService _bucketingService;
  final Map<String, TopicDetailDto> _createdTopicDetailsById =
      <String, TopicDetailDto>{};
  final Set<String> _createdFollowedTopicIds = <String>{};
  final Map<String, DateTime> _createdTopicUpdatedAtById = <String, DateTime>{};

  @override
  Future<TopicDetailDto> fetchTopicDetail(String topicId) async {
    final createdTopic = _createdTopicDetailsById[topicId];
    if (createdTopic != null) {
      return createdTopic;
    }

    final tracked = await _repository.fetchTrackedTopics();
    final recommended = await _repository.fetchRecommendedTopics();
    Topic? topic;
    for (final item in <Topic>[...tracked, ...recommended]) {
      if (item.id == topicId) {
        topic = item;
        break;
      }
    }
    if (topic == null) {
      throw Exception('专题不存在。');
    }

    return _toTopicDetailDto(
      topic,
      trackedTopics: tracked,
    );
  }

  @override
  Future<TopicTimelineResponseDto> fetchTopicTimeline(String topicId) async {
    final createdTopic = _createdTopicDetailsById[topicId];
    if (createdTopic != null) {
      return TopicTimelineResponseDto(
        topic: createdTopic,
        stats: const TopicTimelineStatsDto(
          bucketCount: 0,
          entryCount: 0,
          majorCount: 0,
        ),
        filters: const TopicTimelineFiltersDto(
          defaultOrder: 'asc',
          supportsMajorOnly: true,
        ),
        entries: const <TimelineEntryDto>[],
        page: const TopicTimelinePageDto(
          hasMore: false,
          nextCursor: null,
        ),
      );
    }

    final tracked = await _repository.fetchTrackedTopics();
    final recommended = await _repository.fetchRecommendedTopics();
    Topic? topic;
    for (final item in <Topic>[...tracked, ...recommended]) {
      if (item.id == topicId) {
        topic = item;
        break;
      }
    }
    if (topic == null) {
      throw Exception('专题不存在。');
    }

    final timeline = await _repository.fetchTimeline(topicId);
    final entries = timeline.map(_toTimelineEntryDto).toList()
      ..sort((a, b) => a.sortTime.compareTo(b.sortTime));
    final bucketIds = entries.map((item) => item.bucketKey).toSet();

    return TopicTimelineResponseDto(
      topic: _toTopicDetailDto(topic, trackedTopics: tracked),
      stats: TopicTimelineStatsDto(
        bucketCount: bucketIds.length,
        entryCount: entries.length,
        majorCount: entries.where((item) => item.contextualMajor).length,
      ),
      filters: const TopicTimelineFiltersDto(
        defaultOrder: 'asc',
        supportsMajorOnly: true,
      ),
      entries: entries,
      page: const TopicTimelinePageDto(
        hasMore: false,
        nextCursor: null,
      ),
    );
  }

  @override
  Future<MyTopicListDto> fetchMyTopics() async {
    final items = _createdTopicDetailsById.entries
        .map(
          (entry) => MyTopicItemDto(
            topicId: entry.key,
            title: entry.value.title,
            summary: entry.value.summary,
            status: entry.value.status ?? 'draft',
            kind: entry.value.kind ?? 'user_created',
            visibility: entry.value.visibility ?? 'private',
            initializationState: entry.value.initializationState ?? 'pending',
            updatedAt: _createdTopicUpdatedAtById[entry.key] ?? DateTime.now(),
            isFollowed: _createdFollowedTopicIds.contains(entry.key),
          ),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return MyTopicListDto(
      items: items,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<TopicCreateResultDto> createTopic(
      TopicCreateRequestDto request) async {
    final topicId = 'topic_custom_${DateTime.now().millisecondsSinceEpoch}';
    final updatedAt = DateTime.now();
    final detail = TopicDetailDto(
      topicId: topicId,
      title: request.title,
      summary: request.summary,
      isFollowed: true,
      isPinned: false,
      status: 'draft',
      kind: 'user_created',
      visibility: 'private',
      initializationState: 'pending',
      topicDefinition: request.definition,
    );
    _createdTopicDetailsById[topicId] = detail;
    _createdFollowedTopicIds.add(topicId);
    _createdTopicUpdatedAtById[topicId] = updatedAt;
    final tracked = await _repository.fetchTrackedTopics();
    final followCount = tracked.length + _createdFollowedTopicIds.length;

    return TopicCreateResultDto(
      id: topicId,
      topic: detail,
      followed: true,
      capabilities: UserCapabilitiesDto(
        authenticated: true,
        accountTier: 'free',
        followLimit: 10,
        followCount: followCount,
        remainingFollowQuota: (10 - followCount).clamp(0, 10),
      ),
      initializationState: 'pending',
    );
  }

  @override
  Future<TopicInitializationRetryResultDto> retryTopicInitialization(
      String topicId) async {
    final detail = _createdTopicDetailsById[topicId];
    if (detail == null) {
      throw Exception('专题不存在。');
    }

    _createdTopicDetailsById[topicId] = TopicDetailDto(
      topicId: detail.topicId,
      title: detail.title,
      summary: detail.summary,
      isFollowed: detail.isFollowed,
      isPinned: detail.isPinned,
      status: 'draft',
      kind: detail.kind,
      visibility: detail.visibility,
      initializationState: 'pending',
      topicDefinition: detail.topicDefinition,
    );
    _createdTopicUpdatedAtById[topicId] = DateTime.now();

    return TopicInitializationRetryResultDto(
      topicId: topicId,
      status: 'draft',
      initializationState: 'pending',
    );
  }

  @override
  Future<TimelineSearchResultDto> searchTimeline({
    required String topicId,
    required String query,
  }) async {
    if (_createdTopicDetailsById.containsKey(topicId)) {
      return TimelineSearchResultDto(
        topicId: topicId,
        query: query,
        items: const <TimelineSearchItemDto>[],
      );
    }

    final normalizedQuery = query.trim().toLowerCase();
    final timeline = await _repository.fetchTimeline(topicId);
    final matches = timeline
        .where((entry) {
          final normalized = <String>[
            entry.title,
            entry.summary,
            entry.detail,
            entry.fullText,
            entry.sourceName,
          ].join(' ').toLowerCase();
          return normalized.contains(normalizedQuery);
        })
        .map(_toTimelineEntryDto)
        .map(
          (entry) => TimelineSearchItemDto(
            timelineEntryId: entry.timelineEntryId,
            eventNodeId: entry.eventNodeId,
            topicEventLinkId: entry.topicEventLinkId,
            title: entry.title,
            summary: entry.summary,
            eventTime: entry.eventTime,
            sortTime: entry.sortTime,
            relationType: entry.relationType,
            relevanceScore: entry.relevanceScore,
            importanceLevel: entry.importanceLevel,
            reviewStatus: entry.reviewStatus,
            contextualMajor: entry.contextualMajor,
          ),
        )
        .toList()
      ..sort((a, b) => a.sortTime.compareTo(b.sortTime));

    return TimelineSearchResultDto(
      topicId: topicId,
      query: query,
      items: matches,
    );
  }

  TopicDetailDto _toTopicDetailDto(
    Topic topic, {
    required List<Topic> trackedTopics,
  }) {
    return TopicDetailDto(
      topicId: topic.id,
      title: topic.name,
      summary: topic.tagline,
      isFollowed:
          trackedTopics.any((trackedTopic) => trackedTopic.id == topic.id),
      isPinned: false,
      topicDefinition: topic.definition == null
          ? null
          : TopicDefinitionDto(
              coreKeywords: topic.definition!.coreKeywords,
              extendedKeywords: topic.definition!.relatedKeywords,
              excludedKeywords: topic.definition!.excludedKeywords,
              trackingDirection: topic.definition!.trackingDirection,
              trackingQuestion: topic.definition!.trackingQuestion,
              topicObject: topic.definition!.topicObject,
              topicScope: topic.definition!.topicScope,
              timelineType: topic.definition!.timelineType,
              timelineFocus: topic.definition!.timelineFocus,
              nodeSelectionPolicy: topic.definition!.nodeSelectionPolicy,
              startDateConfidence: topic.definition!.startDateConfidence,
              timelineTypeConfidence: topic.definition!.timelineTypeConfidence,
              sourceEvidenceCount: topic.definition!.sourceEvidenceCount,
              recentActivityStatus: topic.definition!.recentActivityStatus,
              recentEvidenceCount: topic.definition!.recentEvidenceCount,
              latestRelevantSourceAt: topic.definition!.latestRelevantSourceAt,
              trackingViability: topic.definition!.trackingViability,
              trackingViabilityReason:
                  topic.definition!.trackingViabilityReason,
            ),
    );
  }

  TimelineEntryDto _toTimelineEntryDto(TimelineEntry entry) {
    final granularity =
        _bucketingService.granularityFor(entry.timestamp, DateTime.now());
    final bucketStart =
        _bucketingService.bucketStartFor(entry.timestamp, granularity);
    final bucketLabel = _bucketingService.labelFor(bucketStart, granularity);
    final sourceType = entry.sourceKind?.name ?? 'aggregator';
    final reliability = switch (entry.sourceReliability) {
      SourceReliability.high => 0.95,
      SourceReliability.medium => 0.72,
      SourceReliability.low => 0.45,
      null => null,
    };
    final sourceDto = SourceDto(
      sourceId: 'src-${entry.id}',
      sourceName: entry.sourceName,
      sourceType: sourceType,
      sourceUrl: entry.sourceUrl ?? _fallbackSourceUrl(entry),
      sourceProvider: entry.sourceProvider,
      reliability: reliability,
    );

    return TimelineEntryDto(
      timelineEntryId: 'timeline-${entry.id}',
      eventNodeId: 'event-${entry.id}',
      topicEventLinkId: 'link-${entry.id}',
      topicId: entry.topicId,
      title: entry.title,
      summary: entry.summary,
      detail: entry.detail,
      eventTime: entry.timestamp,
      sortTime: entry.timestamp,
      displayDateLabel: formatTimelineDateTime(entry.timestamp),
      precision: granularity.name,
      relationType: entry.isMajor ? 'primary' : 'contextual',
      relevanceScore: entry.isMajor ? 0.92 : 0.71,
      importanceLevel: entry.isMajor ? 'critical' : 'medium',
      reviewStatus: _reviewStatusFor(entry),
      contextualMajor: entry.isMajor,
      contextTag: entry.isMajor ? '关键转折' : null,
      bucketKey: '${granularity.name}-${bucketStart.millisecondsSinceEpoch}',
      bucketLabel: bucketLabel,
      bucketStart: bucketStart,
      bucketGranularity: granularity.name,
      primarySource: sourceDto,
      sources: <SourceDto>[sourceDto],
      dynamicCount: 1,
    );
  }

  String _fallbackSourceUrl(TimelineEntry entry) {
    final query = Uri.encodeComponent('${entry.sourceName} ${entry.title}');
    return 'https://www.google.com/search?q=$query';
  }

  String _reviewStatusFor(TimelineEntry entry) {
    switch (entry.sourceReliability) {
      case SourceReliability.high:
        return 'verified';
      case SourceReliability.low:
        return 'disputed';
      case SourceReliability.medium:
      case null:
        return 'pending';
    }
  }
}
