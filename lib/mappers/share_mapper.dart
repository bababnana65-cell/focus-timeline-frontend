import '../dto/share_dto.dart';
import '../services/shared_topic_flow_service.dart';
import 'topic_timeline_mapper.dart';

class ShareMapper {
  const ShareMapper({
    TopicTimelineMapper? topicTimelineMapper,
  }) : _topicTimelineMapper = topicTimelineMapper ?? const TopicTimelineMapper();

  final TopicTimelineMapper _topicTimelineMapper;

  SharedTopicPreview toSharedTopicPreview(ShareResolveDto dto) {
    final topic = _topicTimelineMapper.toTopic(dto.topic);
    return SharedTopicPreview(
      topic: topic,
      alreadyFollowing: dto.alreadyFollowed,
      allowFollow: dto.allowFollow,
      fromImportedPayload: false,
    );
  }
}
