import 'favorite_timeline_bucket_dto.dart';
import 'followed_topic_dto.dart';
import '../models/timeline_creation_models.dart';
import 'topic_context_contract_dto.dart';

class TopicDefinitionDto {
  const TopicDefinitionDto({
    this.coreKeywords = const <String>[],
    this.extendedKeywords = const <String>[],
    this.excludedKeywords = const <String>[],
    this.trackingDirection = '',
    this.trackingQuestion = '',
    this.topicObject = '',
    this.topicScope = '',
    this.timelineType = '',
    this.timelineFocus = '',
    this.nodeSelectionPolicy = const <String, List<String>>{},
    this.startDateConfidence = '',
    this.timelineTypeConfidence = '',
    this.sourceEvidenceCount = 0,
    this.recentActivityStatus = 'unknown',
    this.recentEvidenceCount = 0,
    this.latestRelevantSourceAt,
    this.trackingViability = 'low',
    this.trackingViabilityReason = '',
  });

  final List<String> coreKeywords;
  final List<String> extendedKeywords;
  final List<String> excludedKeywords;
  final String trackingDirection;
  final String trackingQuestion;
  final String topicObject;
  final String topicScope;
  final String timelineType;
  final String timelineFocus;
  final Map<String, List<String>> nodeSelectionPolicy;
  final String startDateConfidence;
  final String timelineTypeConfidence;
  final int sourceEvidenceCount;
  final String recentActivityStatus;
  final int recentEvidenceCount;
  final DateTime? latestRelevantSourceAt;
  final String trackingViability;
  final String trackingViabilityReason;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'coreKeywords': coreKeywords,
      'extendedKeywords': extendedKeywords,
      'excludedKeywords': excludedKeywords,
      'trackingDirection': trackingDirection,
      'trackingQuestion': trackingQuestion,
      'topicObject': topicObject,
      'topicScope': topicScope,
      'timelineType': timelineType,
      'timelineFocus': timelineFocus,
      'nodeSelectionPolicy': nodeSelectionPolicy,
      'startDateConfidence': startDateConfidence,
      'timelineTypeConfidence': timelineTypeConfidence,
      'sourceEvidenceCount': sourceEvidenceCount,
      'recentActivityStatus': recentActivityStatus,
      'recentEvidenceCount': recentEvidenceCount,
      if (latestRelevantSourceAt != null)
        'latestRelevantSourceAt':
            latestRelevantSourceAt!.toUtc().toIso8601String(),
      'trackingViability': trackingViability,
      'trackingViabilityReason': trackingViabilityReason,
    };
  }

  factory TopicDefinitionDto.fromJson(Map<String, dynamic> json) {
    return TopicDefinitionDto(
      coreKeywords:
          (json['coreKeywords'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
      extendedKeywords:
          (json['extendedKeywords'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
      excludedKeywords:
          (json['excludedKeywords'] as List<dynamic>? ?? const <dynamic>[])
              .cast<String>(),
      trackingDirection: json['trackingDirection'] as String? ?? '',
      trackingQuestion: json['trackingQuestion'] as String? ?? '',
      topicObject: json['topicObject'] as String? ?? '',
      topicScope: json['topicScope'] as String? ?? '',
      timelineType: json['timelineType'] as String? ?? '',
      timelineFocus: json['timelineFocus'] as String? ?? '',
      nodeSelectionPolicy: readStringListMap(json['nodeSelectionPolicy']),
      startDateConfidence: json['startDateConfidence'] as String? ?? '',
      timelineTypeConfidence: json['timelineTypeConfidence'] as String? ?? '',
      sourceEvidenceCount: readInt(json['sourceEvidenceCount']),
      recentActivityStatus:
          json['recentActivityStatus'] as String? ?? 'unknown',
      recentEvidenceCount: readInt(json['recentEvidenceCount']),
      latestRelevantSourceAt: readDateTime(json['latestRelevantSourceAt']),
      trackingViability: json['trackingViability'] as String? ?? 'low',
      trackingViabilityReason: json['trackingViabilityReason'] as String? ?? '',
    );
  }
}

Map<String, List<String>> readStringListMap(Object? value) {
  if (value is! Map) {
    return const <String, List<String>>{};
  }
  final result = <String, List<String>>{};
  value.forEach((key, rawItems) {
    if (key is! String || rawItems is! List) {
      return;
    }
    result[key] = rawItems.whereType<String>().toList(growable: false);
  });
  return result;
}

int readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

class TopicDetailDto {
  const TopicDetailDto({
    required this.topicId,
    required this.title,
    required this.summary,
    required this.isFollowed,
    this.isPinned,
    this.status,
    this.kind,
    this.visibility,
    this.initializationState,
    this.topicDefinition,
    this.primaryCategory,
    this.categories = const <String>[],
    this.categoryConfidence,
  });

  final String topicId;
  final String title;
  final String summary;
  final bool isFollowed;
  final bool? isPinned;
  final String? status;
  final String? kind;
  final String? visibility;
  final String? initializationState;
  final TopicDefinitionDto? topicDefinition;
  final String? primaryCategory;
  final List<String> categories;
  final double? categoryConfidence;

  factory TopicDetailDto.fromJson(Map<String, dynamic> json) {
    return TopicDetailDto(
      topicId: json['topicId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      isFollowed: json['isFollowed'] as bool? ?? false,
      isPinned: json['isPinned'] as bool?,
      status: json['status'] as String?,
      kind: json['kind'] as String?,
      visibility: json['visibility'] as String?,
      initializationState: json['initializationState'] as String?,
      topicDefinition: json['topicDefinition'] == null
          ? null
          : TopicDefinitionDto.fromJson(
              json['topicDefinition'] as Map<String, dynamic>),
      primaryCategory: json['primaryCategory'] as String?,
      categories: readStringList(json['categories']),
      categoryConfidence: readDouble(json['categoryConfidence']),
    );
  }
}

class TopicCreateRequestDto {
  const TopicCreateRequestDto({
    required this.title,
    required this.summary,
    required this.definition,
    this.startDate,
    this.keywords = '',
    this.selectedDirection,
  });

  final String title;
  final String summary;
  final TopicDefinitionDto definition;
  final DateTime? startDate;
  final String keywords;
  final TimelineDirectionCandidate? selectedDirection;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'title': title,
      'summary': summary,
      'definition': definition.toJson(),
      if (startDate != null) 'startDate': _formatDate(startDate!),
      if (keywords.trim().isNotEmpty) 'keywords': keywords.trim(),
      if (selectedDirection != null)
        'selectedDirection': selectedDirection!.toJson(),
    };
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class TopicCreateResultDto {
  const TopicCreateResultDto({
    required this.id,
    required this.topic,
    required this.followed,
    this.capabilities,
    this.initializationState,
  });

  final String id;
  final TopicDetailDto topic;
  final bool followed;
  final UserCapabilitiesDto? capabilities;
  final String? initializationState;

  factory TopicCreateResultDto.fromJson(Map<String, dynamic> json) {
    return TopicCreateResultDto(
      id: json['id'] as String,
      topic: TopicDetailDto.fromJson(json['topic'] as Map<String, dynamic>),
      followed: json['followed'] as bool? ?? false,
      capabilities: json['capabilities'] == null
          ? null
          : UserCapabilitiesDto.fromJson(
              json['capabilities'] as Map<String, dynamic>),
      initializationState: json['initializationState'] as String?,
    );
  }
}

class MyTopicItemDto {
  const MyTopicItemDto({
    required this.topicId,
    required this.title,
    required this.summary,
    required this.status,
    required this.kind,
    required this.visibility,
    required this.initializationState,
    required this.updatedAt,
    required this.isFollowed,
    this.primaryCategory,
    this.categories = const <String>[],
    this.categoryConfidence,
  });

  final String topicId;
  final String title;
  final String summary;
  final String status;
  final String kind;
  final String visibility;
  final String initializationState;
  final DateTime updatedAt;
  final bool isFollowed;
  final String? primaryCategory;
  final List<String> categories;
  final double? categoryConfidence;

  bool get isReadable => status == 'active' && initializationState == 'ready';

  bool get canRetry => status == 'draft' && initializationState == 'failed';

  factory MyTopicItemDto.fromJson(Map<String, dynamic> json) {
    return MyTopicItemDto(
      topicId: json['topicId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      status: json['status'] as String? ?? 'draft',
      kind: json['kind'] as String? ?? 'user_created',
      visibility: json['visibility'] as String? ?? 'private',
      initializationState: json['initializationState'] as String? ?? 'pending',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isFollowed: json['isFollowed'] as bool? ?? false,
      primaryCategory: json['primaryCategory'] as String?,
      categories: readStringList(json['categories']),
      categoryConfidence: readDouble(json['categoryConfidence']),
    );
  }
}

class MyTopicListDto {
  const MyTopicListDto({
    required this.items,
    this.generatedAt,
  });

  final List<MyTopicItemDto> items;
  final DateTime? generatedAt;

  factory MyTopicListDto.fromJson(Map<String, dynamic> json) {
    return MyTopicListDto(
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => MyTopicItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
    );
  }
}

class TopicInitializationRetryResultDto {
  const TopicInitializationRetryResultDto({
    required this.topicId,
    required this.status,
    required this.initializationState,
  });

  final String topicId;
  final String status;
  final String initializationState;

  factory TopicInitializationRetryResultDto.fromJson(
      Map<String, dynamic> json) {
    return TopicInitializationRetryResultDto(
      topicId: json['topicId'] as String,
      status: json['status'] as String? ?? 'draft',
      initializationState: json['initializationState'] as String? ?? 'pending',
    );
  }
}

class SourceDto {
  const SourceDto({
    required this.sourceId,
    required this.sourceName,
    required this.sourceType,
    required this.sourceUrl,
    this.sourceProvider,
    this.reliability,
  });

  final String sourceId;
  final String sourceName;
  final String sourceType;
  final String sourceUrl;
  final String? sourceProvider;
  final double? reliability;

  factory SourceDto.fromJson(Map<String, dynamic> json) {
    return SourceDto(
      sourceId: json['sourceId'] as String,
      sourceName: json['sourceName'] as String,
      sourceType: json['sourceType'] as String,
      sourceUrl: json['sourceUrl'] as String? ?? '',
      sourceProvider: json['sourceProvider'] as String?,
      reliability: (json['reliability'] as num?)?.toDouble(),
    );
  }
}

class TimelineEntryDto {
  const TimelineEntryDto({
    required this.timelineEntryId,
    required this.eventNodeId,
    required this.topicEventLinkId,
    required this.topicId,
    required this.title,
    required this.summary,
    required this.eventTime,
    required this.sortTime,
    required this.displayDateLabel,
    required this.precision,
    required this.relationType,
    required this.importanceLevel,
    required this.reviewStatus,
    required this.contextualMajor,
    required this.bucketKey,
    required this.bucketLabel,
    required this.bucketStart,
    required this.bucketGranularity,
    this.detail,
    this.relevanceScore,
    this.contextTag,
    this.primarySource,
    this.sources = const <SourceDto>[],
    this.dynamicCount,
    this.primarySignal,
    this.signals = const <String>[],
    this.signalConfidence,
  });

  final String timelineEntryId;
  final String eventNodeId;
  final String topicEventLinkId;
  final String topicId;
  final String title;
  final String summary;
  final String? detail;
  final DateTime eventTime;
  final DateTime sortTime;
  final String displayDateLabel;
  final String precision;
  final String relationType;
  final double? relevanceScore;
  final String importanceLevel;
  final String reviewStatus;
  final bool contextualMajor;
  final String? contextTag;
  final String bucketKey;
  final String bucketLabel;
  final DateTime bucketStart;
  final String bucketGranularity;
  final SourceDto? primarySource;
  final List<SourceDto> sources;
  final int? dynamicCount;
  final String? primarySignal;
  final List<String> signals;
  final double? signalConfidence;

  factory TimelineEntryDto.fromJson(Map<String, dynamic> json) {
    return TimelineEntryDto(
      timelineEntryId: json['timelineEntryId'] as String,
      eventNodeId: json['eventNodeId'] as String,
      topicEventLinkId: json['topicEventLinkId'] as String,
      topicId: json['topicId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      detail: json['detail'] as String?,
      eventTime: DateTime.parse(json['eventTime'] as String),
      sortTime: DateTime.parse(json['sortTime'] as String),
      displayDateLabel: json['displayDateLabel'] as String,
      precision: json['precision'] as String,
      relationType: json['relationType'] as String,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble(),
      importanceLevel: json['importanceLevel'] as String,
      reviewStatus: json['reviewStatus'] as String,
      contextualMajor: json['contextualMajor'] as bool,
      contextTag: json['contextTag'] as String?,
      bucketKey: json['bucketKey'] as String,
      bucketLabel: json['bucketLabel'] as String,
      bucketStart: DateTime.parse(json['bucketStart'] as String),
      bucketGranularity: json['bucketGranularity'] as String,
      primarySource: json['primarySource'] == null
          ? null
          : SourceDto.fromJson(json['primarySource'] as Map<String, dynamic>),
      sources: (json['sources'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => SourceDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      dynamicCount: json['dynamicCount'] as int?,
      primarySignal: json['primarySignal'] as String?,
      signals: readStringList(json['signals']),
      signalConfidence: readDouble(json['signalConfidence']),
    );
  }
}

class TopicTimelineResponseDto {
  const TopicTimelineResponseDto({
    required this.topic,
    required this.stats,
    required this.filters,
    required this.entries,
    this.favoriteBuckets = const <FavoriteTimelineBucketDto>[],
    this.page,
  });

  final TopicDetailDto topic;
  final TopicTimelineStatsDto stats;
  final TopicTimelineFiltersDto filters;
  final List<TimelineEntryDto> entries;
  final List<FavoriteTimelineBucketDto> favoriteBuckets;
  final TopicTimelinePageDto? page;

  factory TopicTimelineResponseDto.fromJson(Map<String, dynamic> json) {
    return TopicTimelineResponseDto(
      topic: TopicDetailDto.fromJson(json['topic'] as Map<String, dynamic>),
      stats:
          TopicTimelineStatsDto.fromJson(json['stats'] as Map<String, dynamic>),
      filters: TopicTimelineFiltersDto.fromJson(
          json['filters'] as Map<String, dynamic>),
      entries: (json['entries'] as List<dynamic>)
          .map(
              (item) => TimelineEntryDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      favoriteBuckets: (json['favoriteBuckets'] as List<dynamic>? ??
              const <dynamic>[])
          .map((item) =>
              FavoriteTimelineBucketDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] == null
          ? null
          : TopicTimelinePageDto.fromJson(json['page'] as Map<String, dynamic>),
    );
  }
}

class TopicTimelineStatsDto {
  const TopicTimelineStatsDto({
    required this.bucketCount,
    required this.entryCount,
    required this.majorCount,
    this.startedAt,
    this.eventNodeCount,
    this.dynamicCount,
    this.majorNodeCount,
    this.latestEventAt,
    this.trackingDays,
  });

  final int bucketCount;
  final int entryCount;
  final int majorCount;
  final DateTime? startedAt;
  final int? eventNodeCount;
  final int? dynamicCount;
  final int? majorNodeCount;
  final DateTime? latestEventAt;
  final int? trackingDays;

  factory TopicTimelineStatsDto.fromJson(Map<String, dynamic> json) {
    return TopicTimelineStatsDto(
      bucketCount: json['bucketCount'] as int,
      entryCount: json['entryCount'] as int,
      majorCount: json['majorCount'] as int,
      startedAt: readDateTime(json['startedAt']),
      eventNodeCount: json['eventNodeCount'] as int?,
      dynamicCount: json['dynamicCount'] as int?,
      majorNodeCount: json['majorNodeCount'] as int?,
      latestEventAt: readDateTime(json['latestEventAt']),
      trackingDays: json['trackingDays'] as int?,
    );
  }
}

class TopicTimelineFiltersDto {
  const TopicTimelineFiltersDto({
    required this.defaultOrder,
    required this.supportsMajorOnly,
  });

  final String defaultOrder;
  final bool supportsMajorOnly;

  factory TopicTimelineFiltersDto.fromJson(Map<String, dynamic> json) {
    return TopicTimelineFiltersDto(
      defaultOrder: json['defaultOrder'] as String,
      supportsMajorOnly: json['supportsMajorOnly'] as bool,
    );
  }
}

class TopicTimelinePageDto {
  const TopicTimelinePageDto({
    required this.hasMore,
    this.nextCursor,
  });

  final bool hasMore;
  final String? nextCursor;

  factory TopicTimelinePageDto.fromJson(Map<String, dynamic> json) {
    return TopicTimelinePageDto(
      hasMore: json['hasMore'] as bool,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class TimelineSearchItemDto {
  const TimelineSearchItemDto({
    required this.timelineEntryId,
    required this.eventNodeId,
    required this.topicEventLinkId,
    required this.title,
    required this.summary,
    required this.eventTime,
    required this.sortTime,
    required this.relationType,
    required this.importanceLevel,
    required this.reviewStatus,
    required this.contextualMajor,
    this.relevanceScore,
  });

  final String timelineEntryId;
  final String eventNodeId;
  final String topicEventLinkId;
  final String title;
  final String summary;
  final DateTime eventTime;
  final DateTime sortTime;
  final String relationType;
  final double? relevanceScore;
  final String importanceLevel;
  final String reviewStatus;
  final bool contextualMajor;

  factory TimelineSearchItemDto.fromJson(Map<String, dynamic> json) {
    return TimelineSearchItemDto(
      timelineEntryId: json['timelineEntryId'] as String,
      eventNodeId: json['eventNodeId'] as String,
      topicEventLinkId: json['topicEventLinkId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      eventTime: DateTime.parse(json['eventTime'] as String),
      sortTime: DateTime.parse(json['sortTime'] as String),
      relationType: json['relationType'] as String,
      relevanceScore: (json['relevanceScore'] as num?)?.toDouble(),
      importanceLevel: json['importanceLevel'] as String,
      reviewStatus: json['reviewStatus'] as String,
      contextualMajor: json['contextualMajor'] as bool,
    );
  }
}

class TimelineSearchResultDto {
  const TimelineSearchResultDto({
    required this.topicId,
    required this.query,
    required this.items,
  });

  final String topicId;
  final String query;
  final List<TimelineSearchItemDto> items;

  factory TimelineSearchResultDto.fromJson(Map<String, dynamic> json) {
    return TimelineSearchResultDto(
      topicId: json['topicId'] as String,
      query: json['query'] as String,
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              TimelineSearchItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
