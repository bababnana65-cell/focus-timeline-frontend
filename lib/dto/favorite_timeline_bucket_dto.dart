import '../models/timeline_models.dart';

class FavoriteTimelineBucketRequestDto {
  const FavoriteTimelineBucketRequestDto({
    required this.topicId,
    required this.bucketKey,
    required this.bucketGranularity,
    required this.bucketLabel,
    required this.bucketStart,
    required this.bucketEnd,
    this.topicTitle,
    this.topicSummary,
    this.headline,
    this.summary,
    this.primarySignal,
    this.containsMajorEvent = false,
    this.savedAt,
  });

  final String topicId;
  final String bucketKey;
  final TimelineGranularity bucketGranularity;
  final String bucketLabel;
  final DateTime bucketStart;
  final DateTime bucketEnd;
  final String? topicTitle;
  final String? topicSummary;
  final String? headline;
  final String? summary;
  final String? primarySignal;
  final bool containsMajorEvent;
  final DateTime? savedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'topicId': topicId,
      'bucketKey': bucketKey,
      'bucketGranularity': bucketGranularity.name,
      'bucketLabel': bucketLabel,
      'bucketStart': bucketStart.toIso8601String(),
      'bucketEnd': bucketEnd.toIso8601String(),
      if (topicTitle != null) 'topicTitle': topicTitle,
      if (topicSummary != null) 'topicSummary': topicSummary,
      if (headline != null) 'headline': headline,
      if (summary != null) 'summary': summary,
      if (primarySignal != null) 'primarySignal': primarySignal,
      'containsMajorEvent': containsMajorEvent,
      if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
    };
  }
}

class FavoriteTimelineBucketDeleteRequestDto {
  const FavoriteTimelineBucketDeleteRequestDto({
    required this.topicId,
    required this.bucketGranularity,
    required this.bucketStart,
    required this.bucketEnd,
  });

  final String topicId;
  final TimelineGranularity bucketGranularity;
  final DateTime bucketStart;
  final DateTime bucketEnd;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'topicId': topicId,
      'bucketGranularity': bucketGranularity.name,
      'bucketStart': bucketStart.toIso8601String(),
      'bucketEnd': bucketEnd.toIso8601String(),
    };
  }
}

class FavoriteTimelineBucketDto {
  const FavoriteTimelineBucketDto({
    required this.favoriteId,
    required this.topicId,
    required this.bucketKey,
    required this.bucketGranularity,
    required this.bucketLabel,
    required this.bucketStart,
    required this.bucketEnd,
    required this.headline,
    required this.summary,
    required this.containsMajorEvent,
    required this.savedAt,
    this.topicTitle,
    this.topicSummary,
    this.primarySignal,
  });

  final String favoriteId;
  final String topicId;
  final String? topicTitle;
  final String? topicSummary;
  final String bucketKey;
  final TimelineGranularity bucketGranularity;
  final String bucketLabel;
  final DateTime bucketStart;
  final DateTime bucketEnd;
  final String headline;
  final String summary;
  final String? primarySignal;
  final bool containsMajorEvent;
  final DateTime savedAt;

  factory FavoriteTimelineBucketDto.fromJson(Map<String, dynamic> json) {
    final bucketStart = DateTime.parse(json['bucketStart'] as String);
    final granularity =
        _timelineGranularityFromName(json['bucketGranularity'] as String?);
    return FavoriteTimelineBucketDto(
      favoriteId: json['favoriteId'] as String? ??
          '${json['topicId'] ?? ''}:${json['bucketKey'] ?? bucketStart.toIso8601String()}',
      topicId: json['topicId'] as String? ?? '',
      topicTitle: json['topicTitle'] as String? ?? json['topicName'] as String?,
      topicSummary: json['topicSummary'] as String?,
      bucketKey: json['bucketKey'] as String? ?? bucketStart.toIso8601String(),
      bucketGranularity: granularity,
      bucketLabel: json['bucketLabel'] as String? ??
          formatTimelineGranularityLabel(bucketStart, granularity),
      bucketStart: bucketStart,
      bucketEnd: json['bucketEnd'] == null
          ? timelineBucketRangeEnd(bucketStart, granularity)
          : DateTime.parse(json['bucketEnd'] as String),
      headline: json['headline'] as String? ??
          json['title'] as String? ??
          json['bucketLabel'] as String? ??
          '收藏节点',
      summary: json['summary'] as String? ?? '',
      primarySignal: json['primarySignal'] as String?,
      containsMajorEvent: json['containsMajorEvent'] as bool? ??
          json['contextualMajor'] as bool? ??
          false,
      savedAt: json['savedAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['savedAt'] as String),
    );
  }
}

class FavoriteTimelineBucketListDto {
  const FavoriteTimelineBucketListDto({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<FavoriteTimelineBucketDto> items;
  final bool hasMore;
  final String? nextCursor;

  factory FavoriteTimelineBucketListDto.fromJson(Map<String, dynamic> json) {
    return FavoriteTimelineBucketListDto(
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) =>
              FavoriteTimelineBucketDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      hasMore: json['hasMore'] as bool? ?? false,
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

class FavoriteTimelineBucketDeleteResultDto {
  const FavoriteTimelineBucketDeleteResultDto({
    required this.removed,
  });

  final int removed;

  factory FavoriteTimelineBucketDeleteResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return FavoriteTimelineBucketDeleteResultDto(
      removed: json['removed'] as int? ?? 0,
    );
  }
}

class FavoriteTimelineBucketMergeRequestDto {
  const FavoriteTimelineBucketMergeRequestDto({
    required this.items,
  });

  final List<FavoriteTimelineBucketRequestDto> items;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class FavoriteTimelineBucketMergeResultDto {
  const FavoriteTimelineBucketMergeResultDto({
    required this.merged,
    required this.alreadyExists,
    required this.skipped,
    required this.skippedItems,
  });

  final int merged;
  final int alreadyExists;
  final int skipped;
  final List<FavoriteTimelineBucketSkippedDto> skippedItems;

  factory FavoriteTimelineBucketMergeResultDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return FavoriteTimelineBucketMergeResultDto(
      merged: json['merged'] as int? ?? 0,
      alreadyExists: json['alreadyExists'] as int? ?? 0,
      skipped: json['skipped'] as int? ?? 0,
      skippedItems:
          (json['skippedItems'] as List<dynamic>? ?? const <dynamic>[])
              .map((item) => FavoriteTimelineBucketSkippedDto.fromJson(
                  item as Map<String, dynamic>))
              .toList(),
    );
  }
}

class FavoriteTimelineBucketSkippedDto {
  const FavoriteTimelineBucketSkippedDto({
    required this.topicId,
    required this.bucketKey,
    required this.reason,
  });

  final String topicId;
  final String bucketKey;
  final String reason;

  factory FavoriteTimelineBucketSkippedDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return FavoriteTimelineBucketSkippedDto(
      topicId: json['topicId'] as String? ?? '',
      bucketKey: json['bucketKey'] as String? ?? '',
      reason: json['reason'] as String? ?? 'unknown',
    );
  }
}

TimelineGranularity _timelineGranularityFromName(String? value) {
  if (value == null || value.isEmpty) {
    return TimelineGranularity.day;
  }
  for (final granularity in TimelineGranularity.values) {
    if (granularity.name == value) {
      return granularity;
    }
  }
  return TimelineGranularity.day;
}
