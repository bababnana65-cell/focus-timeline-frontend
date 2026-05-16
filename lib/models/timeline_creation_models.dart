import 'timeline_models.dart';

class TimelineExpansionProgressItem {
  const TimelineExpansionProgressItem({
    required this.title,
    this.date,
    this.sourceTier = 'general_web',
    this.url = '',
  });

  final String title;
  final DateTime? date;
  final String sourceTier;
  final String url;
}

class TimelineExpansionProgress {
  const TimelineExpansionProgress({
    required this.status,
    required this.stage,
    this.items = const <TimelineExpansionProgressItem>[],
  });

  final String status;
  final String stage;
  final List<TimelineExpansionProgressItem> items;
}

class TimelineDirectionCandidate {
  const TimelineDirectionCandidate({
    required this.candidateId,
    required this.title,
    required this.trackingDirection,
    required this.trackingQuestion,
    required this.topicObject,
    required this.topicScope,
    this.timelineType = '',
    this.timelineTypeConfidence = '',
    required this.categoryId,
    required this.primaryCategory,
    required this.recentActivityStatus,
    required this.trackingViability,
    this.sourceEvidenceCount = 0,
    required this.recentEvidenceCount,
    this.latestRelevantSourceAt,
    required this.reason,
    this.isRecommended = false,
  });

  final String candidateId;
  final String title;
  final String trackingDirection;
  final String trackingQuestion;
  final String topicObject;
  final String topicScope;
  final String timelineType;
  final String timelineTypeConfidence;
  final String categoryId;
  final String primaryCategory;
  final String recentActivityStatus;
  final String trackingViability;
  final int sourceEvidenceCount;
  final int recentEvidenceCount;
  final DateTime? latestRelevantSourceAt;
  final String reason;
  final bool isRecommended;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'candidateId': candidateId,
      'title': title,
      'trackingDirection': trackingDirection,
      'trackingQuestion': trackingQuestion,
      'topicObject': topicObject,
      'topicScope': topicScope,
      if (timelineType.trim().isNotEmpty) 'timelineType': timelineType,
      if (timelineTypeConfidence.trim().isNotEmpty)
        'timelineTypeConfidence': timelineTypeConfidence,
      'categoryId': categoryId,
      'primaryCategory': primaryCategory,
      'recentActivityStatus': recentActivityStatus,
      'trackingViability': trackingViability,
      if (sourceEvidenceCount > 0) 'sourceEvidenceCount': sourceEvidenceCount,
      'recentEvidenceCount': recentEvidenceCount,
      if (latestRelevantSourceAt != null)
        'latestRelevantSourceAt':
            latestRelevantSourceAt!.toUtc().toIso8601String(),
      'reason': reason,
      'isRecommended': isRecommended,
    };
  }
}

class TimelineDraft {
  const TimelineDraft({
    required this.keywords,
    required this.topicName,
    required this.tagline,
    required this.summary,
    required this.categoryId,
    required this.definition,
    required this.seedEntries,
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

  final String keywords;
  final String topicName;
  final String tagline;
  final String summary;
  final String categoryId;
  final TopicDefinition definition;
  final List<TimelineEntry> seedEntries;
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

  DateTime get startDate {
    var start = seedEntries.first.timestamp;
    for (final entry in seedEntries.skip(1)) {
      if (entry.timestamp.isBefore(start)) {
        start = entry.timestamp;
      }
    }
    return start;
  }
}
