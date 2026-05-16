import '../../dto/share_dto.dart';
import '../../dto/topic_timeline_dto.dart';
import '../mock_timeline_repository.dart';

abstract class ShareRemoteService {
  Future<ShareCreateResultDto> createShare({
    required String topicId,
  });

  Future<ShareResolveDto> resolveShare(String shareToken);
}

class MockShareRemoteService implements ShareRemoteService {
  MockShareRemoteService({
    required TimelineRepository repository,
  }) : _repository = repository;

  final TimelineRepository _repository;

  @override
  Future<ShareCreateResultDto> createShare({
    required String topicId,
  }) async {
    return ShareCreateResultDto(
      shareToken: 'share_$topicId',
      shareUrl: 'https://example.com/share/share_$topicId',
      shareType: 'topic',
      allowFollow: true,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
  }

  @override
  Future<ShareResolveDto> resolveShare(String shareToken) async {
    final topicId = shareToken.replaceFirst('share_', '');
    final trackedTopics = await _repository.fetchTrackedTopics();
    final recommendedTopics = await _repository.fetchRecommendedTopics();
    TopicDetailDto? topic;
    for (final item in <dynamic>[...trackedTopics, ...recommendedTopics]) {
      if (item.id == topicId) {
        topic = TopicDetailDto(
          topicId: item.id as String,
          title: item.name as String,
          summary: item.tagline as String,
          isFollowed: trackedTopics.any((tracked) => tracked.id == item.id),
          isPinned: false,
          topicDefinition: item.definition == null
              ? null
              : TopicDefinitionDto(
                  coreKeywords: item.definition!.coreKeywords,
                  extendedKeywords: item.definition!.relatedKeywords,
                  excludedKeywords: item.definition!.excludedKeywords,
                ),
        );
        break;
      }
    }

    if (topic == null) {
      throw Exception('分享专题不存在。');
    }

    return ShareResolveDto(
      shareToken: shareToken,
      shareType: 'topic',
      allowFollow: true,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      alreadyFollowed: topic.isFollowed,
      topic: topic,
      preview: SharePreviewDto(
        latestEventAt: DateTime.now().subtract(const Duration(hours: 2)),
        majorCount: 3,
      ),
    );
  }
}
