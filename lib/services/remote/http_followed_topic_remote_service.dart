import '../../dto/followed_topic_dto.dart';
import 'followed_topic_remote_service.dart';
import 'http_api_client.dart';

class HttpFollowedTopicRemoteService implements FollowedTopicRemoteService {
  HttpFollowedTopicRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  }) async {
    final data = await _client.get('/users/capabilities');
    return UserCapabilitiesDto.fromJson(data);
  }

  @override
  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  }) async {
    final data = await _client.get('/topics/followed');
    return FollowedTopicListDto.fromJson(data);
  }

  @override
  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  }) async {
    final data = await _client.post(
      '/users/merge-guest-follows',
      body: <String, dynamic>{
        'guestTopicIds': guestTopicIds,
      },
      includeGuestKey: true,
    );
    return GuestFollowMergeResultDto.fromJson(data);
  }

  @override
  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    final data = await _client.post(
      '/users/claim-guest-topics',
      body: <String, dynamic>{
        'topicIds': topicIds,
      },
      includeGuestKey: true,
    );
    return GuestTopicClaimResultDto.fromJson(data);
  }

  @override
  Future<FollowMutationResultDto> followTopic({
    required String userId,
    required String topicId,
  }) async {
    final data = await _client.post('/topics/$topicId/follow');
    return FollowMutationResultDto.fromJson(data);
  }

  @override
  Future<FollowMutationResultDto> pinTopic({
    required String userId,
    required String topicId,
  }) async {
    final data = await _client.post('/topics/$topicId/pin');
    return FollowMutationResultDto.fromJson(<String, dynamic>{
      'followed': true,
      ...data,
    });
  }

  @override
  Future<FollowMutationResultDto> unfollowTopic({
    required String userId,
    required String topicId,
  }) async {
    final data = await _client.delete('/topics/$topicId/follow');
    return FollowMutationResultDto.fromJson(data);
  }

  @override
  Future<FollowMutationResultDto> unpinTopic({
    required String userId,
    required String topicId,
  }) async {
    final data = await _client.delete('/topics/$topicId/pin');
    return FollowMutationResultDto.fromJson(<String, dynamic>{
      'followed': true,
      ...data,
    });
  }
}
