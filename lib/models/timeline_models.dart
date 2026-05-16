enum TimelineGranularity {
  hour('小时', false, '小时节点'),
  day('天', false, '日节点'),
  month('月', true, '月度归档'),
  year('年', true, '年度归档'),
  decade('十年', true, '十年归档'),
  century('世纪', true, '世纪归档');

  const TimelineGranularity(this.unitLabel, this.isArchived, this.archiveLabel);

  final String unitLabel;
  final bool isArchived;
  final String archiveLabel;
}

enum TimelineSortOrder {
  chronological('正序', '最近事件在底部'),
  reverseChronological('倒序', '最近事件在顶部');

  const TimelineSortOrder(this.label, this.description);

  final String label;
  final String description;
}

enum SourceKind {
  official('官方'),
  media('媒体'),
  research('研报'),
  community('社区'),
  aggregator('整理'),
  unknown('来源未标注');

  const SourceKind(this.label);

  final String label;

  static SourceKind? fromName(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final item in SourceKind.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }
}

enum SourceReliability {
  high('高可信'),
  medium('待核验'),
  low('仅供参考');

  const SourceReliability(this.label);

  final String label;

  static SourceReliability? fromName(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final item in SourceReliability.values) {
      if (item.name == value) {
        return item;
      }
    }
    return null;
  }
}

class Topic {
  const Topic({
    required this.id,
    required this.name,
    required this.tagline,
    required this.followerCount,
    required this.isHot,
    this.definition,
    this.primaryCategory,
    this.categories = const <String>[],
    this.categoryConfidence,
  });

  final String id;
  final String name;
  final String tagline;
  final int followerCount;
  final bool isHot;
  final TopicDefinition? definition;
  final String? primaryCategory;
  final List<String> categories;
  final double? categoryConfidence;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'tagline': tagline,
      'followerCount': followerCount,
      'isHot': isHot,
      if (definition != null) 'definition': definition!.toJson(),
      if (primaryCategory != null) 'primaryCategory': primaryCategory,
      if (categories.isNotEmpty) 'categories': categories,
      if (categoryConfidence != null) 'categoryConfidence': categoryConfidence,
    };
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String,
      followerCount: json['followerCount'] as int,
      isHot: json['isHot'] as bool,
      definition: json['definition'] == null
          ? null
          : TopicDefinition.fromJson(
              json['definition'] as Map<String, dynamic>),
      primaryCategory: json['primaryCategory'] as String?,
      categories: _readStringList(json['categories']),
      categoryConfidence: (json['categoryConfidence'] as num?)?.toDouble(),
    );
  }
}

class TopicDefinition {
  const TopicDefinition({
    required this.overview,
    required this.includeScope,
    required this.excludeScope,
    required this.coreKeywords,
    required this.relatedKeywords,
    required this.excludedKeywords,
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

  final String overview;
  final String includeScope;
  final String excludeScope;
  final List<String> coreKeywords;
  final List<String> relatedKeywords;
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
      'overview': overview,
      'includeScope': includeScope,
      'excludeScope': excludeScope,
      'coreKeywords': coreKeywords,
      'relatedKeywords': relatedKeywords,
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

  factory TopicDefinition.fromJson(Map<String, dynamic> json) {
    return TopicDefinition(
      overview: json['overview'] as String,
      includeScope: json['includeScope'] as String,
      excludeScope: json['excludeScope'] as String,
      coreKeywords: (json['coreKeywords'] as List<dynamic>).cast<String>(),
      relatedKeywords:
          (json['relatedKeywords'] as List<dynamic>).cast<String>(),
      excludedKeywords:
          (json['excludedKeywords'] as List<dynamic>).cast<String>(),
      trackingDirection: json['trackingDirection'] as String? ?? '',
      trackingQuestion: json['trackingQuestion'] as String? ?? '',
      topicObject: json['topicObject'] as String? ?? '',
      topicScope: json['topicScope'] as String? ?? '',
      timelineType: json['timelineType'] as String? ?? '',
      timelineFocus: json['timelineFocus'] as String? ?? '',
      nodeSelectionPolicy: _readStringListMap(json['nodeSelectionPolicy']),
      startDateConfidence: json['startDateConfidence'] as String? ?? '',
      timelineTypeConfidence: json['timelineTypeConfidence'] as String? ?? '',
      sourceEvidenceCount: _readInt(json['sourceEvidenceCount']),
      recentActivityStatus:
          json['recentActivityStatus'] as String? ?? 'unknown',
      recentEvidenceCount: _readInt(json['recentEvidenceCount']),
      latestRelevantSourceAt: _readDateTime(json['latestRelevantSourceAt']),
      trackingViability: json['trackingViability'] as String? ?? 'low',
      trackingViabilityReason: json['trackingViabilityReason'] as String? ?? '',
    );
  }
}

Map<String, List<String>> _readStringListMap(Object? value) {
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

int _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

DateTime? _readDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.parse(value).toUtc();
}

class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.topicId,
    required this.title,
    required this.summary,
    required this.detail,
    required this.fullText,
    required this.sourceName,
    this.sourceUrl,
    this.sourceProvider,
    this.sourceKind,
    this.sourceReliability,
    required this.timestamp,
    required this.isMajor,
    this.primarySignal,
    this.signals = const <String>[],
    this.signalConfidence,
  });

  final String id;
  final String topicId;
  final String title;
  final String summary;
  final String detail;
  final String fullText;
  final String sourceName;
  final String? sourceUrl;
  final String? sourceProvider;
  final SourceKind? sourceKind;
  final SourceReliability? sourceReliability;
  final DateTime timestamp;
  final bool isMajor;
  final String? primarySignal;
  final List<String> signals;
  final double? signalConfidence;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'topicId': topicId,
      'title': title,
      'summary': summary,
      'detail': detail,
      'fullText': fullText,
      'sourceName': sourceName,
      if (sourceUrl != null) 'sourceUrl': sourceUrl,
      if (sourceProvider != null) 'sourceProvider': sourceProvider,
      if (sourceKind != null) 'sourceKind': sourceKind!.name,
      if (sourceReliability != null)
        'sourceReliability': sourceReliability!.name,
      'timestamp': timestamp.toIso8601String(),
      'isMajor': isMajor,
      if (primarySignal != null) 'primarySignal': primarySignal,
      if (signals.isNotEmpty) 'signals': signals,
      if (signalConfidence != null) 'signalConfidence': signalConfidence,
    };
  }

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      detail: json['detail'] as String,
      fullText: json['fullText'] as String,
      sourceName: json['sourceName'] as String,
      sourceUrl: json['sourceUrl'] as String?,
      sourceProvider: json['sourceProvider'] as String?,
      sourceKind: SourceKind.fromName(json['sourceKind'] as String?),
      sourceReliability: SourceReliability.fromName(
        json['sourceReliability'] as String?,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isMajor: json['isMajor'] as bool,
      primarySignal: json['primarySignal'] as String?,
      signals: _readStringList(json['signals']),
      signalConfidence: (json['signalConfidence'] as num?)?.toDouble(),
    );
  }
}

class TimelineBucket {
  const TimelineBucket({
    required this.id,
    required this.periodStart,
    required this.granularity,
    required this.entries,
    required this.label,
    required this.headline,
  });

  final String id;
  final DateTime periodStart;
  final TimelineGranularity granularity;
  final List<TimelineEntry> entries;
  final String label;
  final String headline;

  bool get containsMajorEvent => entries.any((entry) => entry.isMajor);

  int get eventCount => entries.length;

  bool get isArchived => granularity.isArchived;

  String get countLabel => eventCount >= 99 ? '99' : '$eventCount';

  DateTime get rangeStart => periodStart;

  DateTime get rangeEnd => timelineBucketRangeEnd(periodStart, granularity);
}

class FavoriteTimelineNode {
  FavoriteTimelineNode({
    required this.id,
    required this.topicId,
    required this.topicName,
    required this.label,
    required this.headline,
    required this.summary,
    required this.timestamp,
    required this.isMajor,
    required this.savedAt,
    String? bucketKey,
    TimelineGranularity? bucketGranularity,
    DateTime? bucketStart,
    DateTime? bucketEnd,
    this.primarySignal,
  })  : bucketKey = bucketKey ?? id,
        bucketGranularity = bucketGranularity ?? TimelineGranularity.day,
        bucketStart = bucketStart ?? _fallbackFavoriteRangeStart(timestamp),
        bucketEnd = bucketEnd ??
            timelineBucketRangeEnd(
              bucketStart ?? _fallbackFavoriteRangeStart(timestamp),
              bucketGranularity ?? TimelineGranularity.day,
            );

  final String id;
  final String topicId;
  final String topicName;
  final String label;
  final String headline;
  final String summary;
  final DateTime timestamp;
  final bool isMajor;
  final DateTime savedAt;
  final String bucketKey;
  final TimelineGranularity bucketGranularity;
  final DateTime bucketStart;
  final DateTime bucketEnd;
  final String? primarySignal;

  bool overlapsBucket(TimelineBucket bucket) {
    return timelineRangesOverlap(
      bucketStart,
      bucketEnd,
      bucket.rangeStart,
      bucket.rangeEnd,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'topicId': topicId,
      'topicName': topicName,
      'label': label,
      'headline': headline,
      'summary': summary,
      'timestamp': timestamp.toIso8601String(),
      'isMajor': isMajor,
      'savedAt': savedAt.toIso8601String(),
      'bucketKey': bucketKey,
      'bucketGranularity': bucketGranularity.name,
      'bucketStart': bucketStart.toIso8601String(),
      'bucketEnd': bucketEnd.toIso8601String(),
      if (primarySignal != null) 'primarySignal': primarySignal,
    };
  }

  factory FavoriteTimelineNode.fromJson(Map<String, dynamic> json) {
    final timestamp = DateTime.parse(json['timestamp'] as String);
    return FavoriteTimelineNode(
      id: json['id'] as String,
      topicId: json['topicId'] as String,
      topicName: json['topicName'] as String,
      label: json['label'] as String,
      headline: json['headline'] as String,
      summary: json['summary'] as String,
      timestamp: timestamp,
      isMajor: json['isMajor'] as bool,
      savedAt: DateTime.parse(json['savedAt'] as String),
      bucketKey: json['bucketKey'] as String?,
      bucketGranularity: _timelineGranularityFromName(
        json['bucketGranularity'] as String?,
      ),
      bucketStart: json['bucketStart'] == null
          ? null
          : DateTime.parse(json['bucketStart'] as String),
      bucketEnd: json['bucketEnd'] == null
          ? null
          : DateTime.parse(json['bucketEnd'] as String),
      primarySignal: json['primarySignal'] as String?,
    );
  }
}

DateTime timelineBucketRangeEnd(
  DateTime start,
  TimelineGranularity granularity,
) {
  final local = start.toLocal();
  switch (granularity) {
    case TimelineGranularity.hour:
      return start.add(const Duration(hours: 1));
    case TimelineGranularity.day:
      return start.add(const Duration(days: 1));
    case TimelineGranularity.month:
      return _dateWithZone(start, local.year, local.month + 1, local.day);
    case TimelineGranularity.year:
      return _dateWithZone(start, local.year + 1, local.month, local.day);
    case TimelineGranularity.decade:
      return _dateWithZone(start, local.year + 10, local.month, local.day);
    case TimelineGranularity.century:
      return _dateWithZone(start, local.year + 100, local.month, local.day);
  }
}

bool timelineRangesOverlap(
  DateTime firstStart,
  DateTime firstEnd,
  DateTime secondStart,
  DateTime secondEnd,
) {
  return firstStart.isBefore(secondEnd) && secondStart.isBefore(firstEnd);
}

DateTime _dateWithZone(
  DateTime source,
  int year,
  int month,
  int day,
) {
  if (source.isUtc) {
    return DateTime.utc(year, month, day);
  }
  return DateTime(year, month, day);
}

DateTime _fallbackFavoriteRangeStart(DateTime timestamp) {
  final local = timestamp.toLocal();
  if (timestamp.isUtc) {
    return DateTime.utc(local.year, local.month, local.day);
  }
  return DateTime(local.year, local.month, local.day);
}

TimelineGranularity? _timelineGranularityFromName(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  for (final granularity in TimelineGranularity.values) {
    if (granularity.name == value) {
      return granularity;
    }
  }
  return null;
}

String formatTimelineDate(
  DateTime date, {
  bool includeMonth = true,
  bool includeDay = true,
}) {
  final buffer = StringBuffer();
  if (date.year >= 100) {
    buffer.write('${date.year}年');
  } else {
    buffer.write('公元${date.year}年');
  }
  if (includeMonth) {
    buffer.write('${date.month}月');
  }
  if (includeDay) {
    buffer.write('${date.day}日');
  }
  return buffer.toString();
}

String formatTimelineDateTime(DateTime date) {
  final dateLabel = formatTimelineDate(date);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$dateLabel $hour:$minute';
}

String formatTimelineHeaderDateLabel(
  DateTime? date, {
  String? bucketLabel,
  TimelineGranularity? granularity,
  DateTime? now,
  bool relativeRecent = false,
}) {
  if (date == null) {
    final semanticLabel = bucketLabel?.trim();
    return semanticLabel == null || semanticLabel.isEmpty
        ? '--'
        : semanticLabel;
  }

  final local = date.toLocal();
  if (relativeRecent) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final eventDay = DateTime(local.year, local.month, local.day);
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final dayDifference = today.difference(eventDay).inDays;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    if (dayDifference == 0) {
      return '今天 $hour:$minute';
    }
    if (dayDifference == 1) {
      return '昨天 $hour:$minute';
    }
    if (local.year == localNow.year) {
      return '${local.month}月${local.day}日';
    }
  }

  if (granularity != null && granularity.isArchived) {
    return formatTimelineGranularityLabel(local, granularity);
  }

  return '${local.year}.${local.month.toString().padLeft(2, '0')}.${local.day.toString().padLeft(2, '0')}';
}

String formatTimelineGranularityLabel(
  DateTime date,
  TimelineGranularity granularity,
) {
  final local = date.toLocal();
  switch (granularity) {
    case TimelineGranularity.hour:
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '${local.year}年${local.month}月${local.day}日 $hour:$minute';
    case TimelineGranularity.day:
      return '${local.year}年${local.month}月${local.day}日';
    case TimelineGranularity.month:
      return '${local.year}年${local.month}月';
    case TimelineGranularity.year:
      return '${local.year}年';
    case TimelineGranularity.decade:
      return '${local.year}年代';
    case TimelineGranularity.century:
      return '${((local.year - 1) ~/ 100) + 1}世纪';
  }
}

String formatTimelineBucketDateLabel(
  TimelineBucket bucket, {
  DateTime? now,
}) {
  final nodeTime = bucket.entries.isNotEmpty
      ? bucket.entries.first.timestamp
      : bucket.periodStart;
  final compactNodeTime = formatCompactNodeTimeLabel(
    nodeTime,
    now: now,
    singleLine: true,
    todayLabel: '今天',
    yesterdayLabel: '昨天',
  );
  if (compactNodeTime.contains(' ')) {
    return compactNodeTime;
  }
  return formatTimelineGranularityLabel(bucket.periodStart, bucket.granularity);
}

String formatTimelineTrackingDuration(
  DateTime? startAt, {
  DateTime? latestAt,
  DateTime? now,
  int? trackingDays,
}) {
  final days = _timelineTrackingDays(
    startAt,
    latestAt: latestAt,
    now: now,
    trackingDays: trackingDays,
  );
  if (days == null) {
    return '--';
  }
  if (days >= 365 * 2) {
    final years = (days / 365.2425).round().clamp(1, 9999);
    return '约$years年';
  }
  if (days >= 90) {
    final months = (days / 30.436875).round().clamp(1, 999);
    return '约$months个月';
  }
  return '${days.clamp(1, 89)}天';
}

String formatCompactNodeTimeLabel(
  DateTime date, {
  DateTime? now,
  bool singleLine = false,
  String todayLabel = '今日',
  String yesterdayLabel = '昨日',
}) {
  final localDate = date.toLocal();
  final localNow = (now ?? DateTime.now()).toLocal();
  final eventDay = DateTime(localDate.year, localDate.month, localDate.day);
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  final dayDifference = today.difference(eventDay).inDays;
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');
  final divider = singleLine ? ' ' : '\n';

  if (dayDifference == 0) {
    return '$todayLabel$divider$hour:$minute';
  }
  if (dayDifference == 1) {
    return '$yesterdayLabel$divider$hour:$minute';
  }
  if (localDate.year == localNow.year) {
    return '${localDate.month}月${localDate.day}日';
  }
  return formatTimelineDate(localDate);
}

int? _timelineTrackingDays(
  DateTime? startAt, {
  DateTime? latestAt,
  DateTime? now,
  int? trackingDays,
}) {
  if (startAt != null) {
    final start = startAt.toLocal();
    final end = (latestAt ?? now ?? DateTime.now()).toLocal();
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    return endDay.difference(startDay).inDays + 1;
  }
  return trackingDays;
}

List<String> _readStringList(dynamic value) {
  return (value as List<dynamic>? ?? const <dynamic>[])
      .whereType<String>()
      .toList(growable: false);
}
