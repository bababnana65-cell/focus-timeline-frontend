import '../dto/topic_timeline_dto.dart';
import '../models/timeline_models.dart';

class TopicTimelineMapper {
  const TopicTimelineMapper();

  Topic toTopic(TopicDetailDto dto) {
    return Topic(
      id: dto.topicId,
      name: dto.title,
      tagline: dto.summary,
      followerCount: 0,
      isHot: false,
      primaryCategory: dto.primaryCategory,
      categories: dto.categories,
      categoryConfidence: dto.categoryConfidence,
      definition: dto.topicDefinition == null
          ? null
          : TopicDefinition(
              overview: '',
              includeScope: '',
              excludeScope: '',
              coreKeywords: dto.topicDefinition!.coreKeywords,
              relatedKeywords: dto.topicDefinition!.extendedKeywords,
              excludedKeywords: dto.topicDefinition!.excludedKeywords,
              trackingDirection: dto.topicDefinition!.trackingDirection,
              trackingQuestion: dto.topicDefinition!.trackingQuestion,
              topicObject: dto.topicDefinition!.topicObject,
              topicScope: dto.topicDefinition!.topicScope,
              timelineType: dto.topicDefinition!.timelineType,
              timelineFocus: dto.topicDefinition!.timelineFocus,
              nodeSelectionPolicy: dto.topicDefinition!.nodeSelectionPolicy,
              startDateConfidence: dto.topicDefinition!.startDateConfidence,
              timelineTypeConfidence:
                  dto.topicDefinition!.timelineTypeConfidence,
              sourceEvidenceCount: dto.topicDefinition!.sourceEvidenceCount,
              recentActivityStatus: dto.topicDefinition!.recentActivityStatus,
              recentEvidenceCount: dto.topicDefinition!.recentEvidenceCount,
              latestRelevantSourceAt:
                  dto.topicDefinition!.latestRelevantSourceAt,
              trackingViability: dto.topicDefinition!.trackingViability,
              trackingViabilityReason:
                  dto.topicDefinition!.trackingViabilityReason,
            ),
    );
  }

  List<TimelineEntry> toTimelineEntries(TopicTimelineResponseDto dto) {
    return dto.entries.map(toTimelineEntry).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<TimelineBucket> toTimelineBuckets(TopicTimelineResponseDto dto) {
    final entriesById = <String, TimelineEntry>{
      for (final entry in dto.entries)
        entry.topicEventLinkId: toTimelineEntry(entry),
    };
    final groupedEntries = <String, List<TimelineEntryDto>>{};

    for (final entry in dto.entries) {
      groupedEntries
          .putIfAbsent(entry.bucketKey, () => <TimelineEntryDto>[])
          .add(entry);
    }

    return groupedEntries.entries.map((group) {
      final bucketEntries = group.value
          .map((entry) => entriesById[entry.topicEventLinkId]!)
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final primaryEntryDto = group.value.first;
      final headlineEntry = bucketEntries.firstWhere(
        (entry) => entry.isMajor,
        orElse: () => bucketEntries.first,
      );

      return TimelineBucket(
        id: group.key,
        periodStart: primaryEntryDto.bucketStart,
        granularity: _toTimelineGranularity(primaryEntryDto.bucketGranularity),
        entries: bucketEntries,
        label: primaryEntryDto.bucketLabel,
        headline: headlineEntry.summary,
      );
    }).toList();
  }

  List<TimelineEntry> toSearchTimelineEntries(TimelineSearchResultDto dto) {
    return dto.items
        .map((item) => toSearchTimelineEntry(dto.topicId, item))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  TimelineEntry toTimelineEntry(TimelineEntryDto dto) {
    final primarySource = dto.primarySource;
    return TimelineEntry(
      id: dto.topicEventLinkId,
      topicId: dto.topicId,
      title: dto.title,
      summary: dto.summary,
      detail: dto.detail ?? dto.summary,
      fullText: dto.detail ?? dto.summary,
      sourceName: primarySource?.sourceName ?? '来源待补充',
      sourceUrl: primarySource?.sourceUrl,
      sourceProvider: primarySource?.sourceProvider,
      sourceKind: _toSourceKind(primarySource?.sourceType),
      sourceReliability: _toSourceReliability(primarySource?.reliability),
      timestamp: dto.sortTime,
      isMajor: dto.contextualMajor,
      primarySignal: dto.primarySignal,
      signals: dto.signals,
      signalConfidence: dto.signalConfidence,
    );
  }

  TimelineEntry toSearchTimelineEntry(
      String topicId, TimelineSearchItemDto dto) {
    return TimelineEntry(
      id: dto.topicEventLinkId,
      topicId: topicId,
      title: dto.title,
      summary: dto.summary,
      detail: dto.summary,
      fullText: dto.summary,
      sourceName: '搜索结果',
      sourceKind: SourceKind.aggregator,
      sourceReliability: SourceReliability.medium,
      timestamp: dto.sortTime,
      isMajor: dto.contextualMajor,
    );
  }

  SourceKind? _toSourceKind(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    final normalized = value.trim().toLowerCase();
    for (final item in SourceKind.values) {
      if (item.name == normalized) {
        return item;
      }
    }
    return SourceKind.aggregator;
  }

  SourceReliability? _toSourceReliability(double? value) {
    if (value == null) {
      return null;
    }
    if (value >= 0.9) {
      return SourceReliability.high;
    }
    if (value >= 0.65) {
      return SourceReliability.medium;
    }
    return SourceReliability.low;
  }

  TimelineGranularity _toTimelineGranularity(String value) {
    for (final granularity in TimelineGranularity.values) {
      if (granularity.name == value) {
        return granularity;
      }
    }
    return TimelineGranularity.day;
  }
}
