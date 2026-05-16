import 'topic_context_contract_dto.dart';

class HistoryTopicDto {
  const HistoryTopicDto({
    required this.topicId,
    required this.title,
    required this.viewedAt,
  });

  final String topicId;
  final String title;
  final DateTime viewedAt;

  factory HistoryTopicDto.fromJson(Map<String, dynamic> json) {
    return HistoryTopicDto(
      topicId: json['topicId'] as String,
      title: json['title'] as String,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
    );
  }
}

class RecommendationItemDto {
  const RecommendationItemDto({
    required this.topicId,
    required this.title,
    required this.summary,
    required this.isFollowed,
    required this.recommendationSource,
    required this.reasonCode,
    this.primaryCategory,
    this.categories = const <String>[],
    this.categoryConfidence,
    this.reason,
    this.score,
    this.latestNode,
    this.hasUnreadUpdate,
    this.unreadNodeCount,
  });

  final String topicId;
  final String title;
  final String summary;
  final bool isFollowed;
  final String recommendationSource;
  final String reasonCode;
  final String? primaryCategory;
  final List<String> categories;
  final double? categoryConfidence;
  final String? reason;
  final double? score;
  final LatestNodeDto? latestNode;
  final bool? hasUnreadUpdate;
  final int? unreadNodeCount;

  factory RecommendationItemDto.fromJson(Map<String, dynamic> json) {
    return RecommendationItemDto(
      topicId: json['topicId'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      isFollowed: json['isFollowed'] as bool,
      recommendationSource: json['recommendationSource'] as String,
      reasonCode: json['reasonCode'] as String,
      primaryCategory: json['primaryCategory'] as String?,
      categories: readStringList(json['categories']),
      categoryConfidence: readDouble(json['categoryConfidence']),
      reason: json['reason'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      latestNode: json['latestNode'] == null
          ? null
          : LatestNodeDto.fromJson(json['latestNode'] as Map<String, dynamic>),
      hasUnreadUpdate: json['hasUnreadUpdate'] as bool?,
      unreadNodeCount: json['unreadNodeCount'] as int?,
    );
  }
}

class RecommendationSectionDto {
  const RecommendationSectionDto({
    required this.sectionKey,
    required this.sectionTitle,
    required this.items,
  });

  final String sectionKey;
  final String sectionTitle;
  final List<RecommendationItemDto> items;

  factory RecommendationSectionDto.fromJson(Map<String, dynamic> json) {
    return RecommendationSectionDto(
      sectionKey: json['sectionKey'] as String,
      sectionTitle: json['sectionTitle'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) =>
              RecommendationItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RecommendationResponseDto {
  const RecommendationResponseDto({
    required this.sections,
    required this.history,
    this.generatedAt,
  });

  final List<RecommendationSectionDto> sections;
  final List<HistoryTopicDto> history;
  final DateTime? generatedAt;

  factory RecommendationResponseDto.fromJson(Map<String, dynamic> json) {
    return RecommendationResponseDto(
      sections: (json['sections'] as List<dynamic>)
          .map((item) =>
              RecommendationSectionDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      history: (json['history'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => HistoryTopicDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
    );
  }
}
