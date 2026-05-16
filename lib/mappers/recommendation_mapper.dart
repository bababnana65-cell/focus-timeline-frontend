import '../dto/recommendation_dto.dart';
import '../models/timeline_models.dart';

class RecommendationMapper {
  const RecommendationMapper();

  RecommendationProjection project(
    RecommendationResponseDto dto, {
    required List<Topic> existingTopics,
  }) {
    final topicsById = <String, Topic>{
      for (final topic in existingTopics) topic.id: topic,
    };

    final personalizedTopics = _mapRecommendationItems(
      _sectionItems(dto.sections, 'personalized'),
      topicsById,
    );
    final hotTopics = _mapRecommendationItems(
      _sectionItems(dto.sections, 'hot'),
      topicsById,
    );
    final exploreTopics = _mapRecommendationItems(
      _sectionItems(dto.sections, 'explore'),
      topicsById,
    );

    final projectedTopicsById = <String, Topic>{
      for (final topic in <Topic>[
        ...personalizedTopics,
        ...hotTopics,
        ...exploreTopics,
      ])
        topic.id: topic,
    };
    final historyTopics = dto.history
        .map(
          (item) => toHistoryTopic(
            item,
            fallbackTopic:
                projectedTopicsById[item.topicId] ?? topicsById[item.topicId],
          ),
        )
        .toList();
    final latestEntriesByTopicId = _latestEntriesByTopicId(
      dto.sections.expand((section) => section.items),
      projectedTopicsById,
    );

    return RecommendationProjection(
      personalizedTopics: personalizedTopics,
      hotTopics: hotTopics,
      exploreTopics: exploreTopics,
      historyTopics: historyTopics,
      mergedTopics: _mergeTopics(
        <Topic>[
          ...personalizedTopics,
          ...hotTopics,
          ...exploreTopics,
          ...historyTopics,
        ],
      ),
      remoteHistoryTopicIds: historyTopics.map((topic) => topic.id).toList(),
      generatedAt: dto.generatedAt,
      latestEntriesByTopicId: latestEntriesByTopicId,
    );
  }

  Topic toTopic(
    RecommendationItemDto dto, {
    Topic? fallbackTopic,
  }) {
    return Topic(
      id: dto.topicId,
      name: dto.title,
      tagline: dto.summary,
      followerCount: fallbackTopic?.followerCount ?? 0,
      isHot:
          dto.recommendationSource == 'hot' || (fallbackTopic?.isHot ?? false),
      definition: fallbackTopic?.definition,
      primaryCategory: dto.primaryCategory ?? fallbackTopic?.primaryCategory,
      categories: dto.categories.isNotEmpty
          ? dto.categories
          : (fallbackTopic?.categories ?? const <String>[]),
      categoryConfidence:
          dto.categoryConfidence ?? fallbackTopic?.categoryConfidence,
    );
  }

  Topic toHistoryTopic(
    HistoryTopicDto dto, {
    Topic? fallbackTopic,
  }) {
    return fallbackTopic ??
        Topic(
          id: dto.topicId,
          name: dto.title,
          tagline: '最近浏览的时间线',
          followerCount: 0,
          isHot: false,
        );
  }

  List<RecommendationItemDto> _sectionItems(
    List<RecommendationSectionDto> sections,
    String key,
  ) {
    for (final section in sections) {
      if (section.sectionKey == key) {
        return section.items;
      }
    }
    return const <RecommendationItemDto>[];
  }

  List<Topic> _mapRecommendationItems(
    List<RecommendationItemDto> items,
    Map<String, Topic> topicsById,
  ) {
    return items
        .map((item) => toTopic(item, fallbackTopic: topicsById[item.topicId]))
        .toList();
  }

  List<Topic> _mergeTopics(List<Topic> topics) {
    final seen = <String>{};
    return topics.where((topic) => seen.add(topic.id)).toList();
  }

  Map<String, TimelineEntry> _latestEntriesByTopicId(
    Iterable<RecommendationItemDto> items,
    Map<String, Topic> topicsById,
  ) {
    final mapped = <String, TimelineEntry>{};
    for (final item in items) {
      final topic = topicsById[item.topicId];
      final latestNode = item.latestNode;
      if (topic == null || latestNode == null) {
        continue;
      }
      final summary = latestNode.summary.trim().isNotEmpty
          ? latestNode.summary.trim()
          : latestNode.headline.trim();
      mapped[item.topicId] = TimelineEntry(
        id: latestNode.id.isNotEmpty
            ? latestNode.id
            : 'recommendation-${item.topicId}',
        topicId: item.topicId,
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
    return mapped;
  }
}

class RecommendationProjection {
  const RecommendationProjection({
    required this.personalizedTopics,
    required this.hotTopics,
    required this.exploreTopics,
    required this.historyTopics,
    required this.mergedTopics,
    required this.remoteHistoryTopicIds,
    this.latestEntriesByTopicId = const <String, TimelineEntry>{},
    this.generatedAt,
  });

  final List<Topic> personalizedTopics;
  final List<Topic> hotTopics;
  final List<Topic> exploreTopics;
  final List<Topic> historyTopics;
  final List<Topic> mergedTopics;
  final List<String> remoteHistoryTopicIds;
  final Map<String, TimelineEntry> latestEntriesByTopicId;
  final DateTime? generatedAt;
}
