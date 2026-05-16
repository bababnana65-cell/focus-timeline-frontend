import '../../dto/topic_timeline_dto.dart';
import 'http_api_client.dart';
import 'topic_remote_service.dart';

class HttpTopicRemoteService implements TopicRemoteService {
  HttpTopicRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<TopicDetailDto> fetchTopicDetail(String topicId) async {
    final data = await _client.get('/topics/$topicId');
    return TopicDetailDto.fromJson(data);
  }

  @override
  Future<TopicTimelineResponseDto> fetchTopicTimeline(String topicId) async {
    final data = await _client.get('/topics/$topicId/timeline');
    return TopicTimelineResponseDto.fromJson(data);
  }

  @override
  Future<MyTopicListDto> fetchMyTopics() async {
    final data = await _client.get('/topics/mine');
    return MyTopicListDto.fromJson(data);
  }

  @override
  Future<TopicCreateResultDto> createTopic(TopicCreateRequestDto request) async {
    final data = await _client.post(
      '/topics/create',
      body: request.toJson(),
    );
    return TopicCreateResultDto.fromJson(data);
  }

  @override
  Future<TopicInitializationRetryResultDto> retryTopicInitialization(String topicId) async {
    final data = await _client.post('/topics/$topicId/retry-initialization');
    return TopicInitializationRetryResultDto.fromJson(data);
  }

  @override
  Future<TimelineSearchResultDto> searchTimeline({
    required String topicId,
    required String query,
  }) async {
    final data = await _client.get(
      '/topics/$topicId/timeline/search',
      queryParameters: <String, String>{
        'q': query,
      },
    );
    return TimelineSearchResultDto.fromJson(data);
  }
}
