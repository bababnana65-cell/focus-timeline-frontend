import '../../dto/recommendation_dto.dart';
import '../mock_timeline_repository.dart';

abstract class RecommendationRemoteService {
  Future<RecommendationResponseDto> fetchRecommendations();
}

class MockRecommendationRemoteService implements RecommendationRemoteService {
  MockRecommendationRemoteService({
    required TimelineRepository repository,
  }) : _repository = repository;

  final TimelineRepository _repository;

  @override
  Future<RecommendationResponseDto> fetchRecommendations() async {
    final trackedTopics = await _repository.fetchTrackedTopics();
    final recommendedTopics = await _repository.fetchRecommendedTopics();

    final personalized = trackedTopics
        .take(3)
        .map(
          (topic) => RecommendationItemDto(
            topicId: topic.id,
            title: topic.name,
            summary: topic.tagline,
            isFollowed: true,
            recommendationSource: 'personalized',
            reasonCode: 'RELATED_TO_FOLLOWS',
            reason: '与你已关注的专题高度相关',
            score: 0.92,
          ),
        )
        .toList();

    final hot = recommendedTopics
        .where((topic) => topic.isHot)
        .take(10)
        .map(
          (topic) => RecommendationItemDto(
            topicId: topic.id,
            title: topic.name,
            summary: topic.tagline,
            isFollowed: trackedTopics.any((tracked) => tracked.id == topic.id),
            recommendationSource: 'hot',
            reasonCode: 'GLOBAL_HEAT_UP',
            reason: '全站热度持续上升',
            score: topic.followerCount / 20000,
          ),
        )
        .toList();

    final explore = recommendedTopics
        .where((topic) => personalized.every((item) => item.topicId != topic.id))
        .take(6)
        .map(
          (topic) => RecommendationItemDto(
            topicId: topic.id,
            title: topic.name,
            summary: topic.tagline,
            isFollowed: trackedTopics.any((tracked) => tracked.id == topic.id),
            recommendationSource: 'explore',
            reasonCode: 'CONTROLLED_EXPLORATION',
            reason: '与你近期浏览主题弱相关，但值得探索',
            score: 0.61,
          ),
        )
        .toList();

    final history = trackedTopics
        .take(3)
        .toList()
        .asMap()
        .entries
        .map(
          (item) => HistoryTopicDto(
            topicId: item.value.id,
            title: item.value.name,
            viewedAt: DateTime.now().subtract(Duration(hours: item.key + 1)),
          ),
        )
        .toList();

    return RecommendationResponseDto(
      sections: <RecommendationSectionDto>[
        RecommendationSectionDto(
          sectionKey: 'personalized',
          sectionTitle: '你可能关心',
          items: personalized,
        ),
        RecommendationSectionDto(
          sectionKey: 'hot',
          sectionTitle: '当前热门',
          items: hot,
        ),
        RecommendationSectionDto(
          sectionKey: 'explore',
          sectionTitle: '值得看看',
          items: explore,
        ),
      ],
      history: history,
      generatedAt: DateTime.now(),
    );
  }
}
