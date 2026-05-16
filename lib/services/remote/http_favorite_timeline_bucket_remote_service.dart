import '../../dto/favorite_timeline_bucket_dto.dart';
import 'favorite_timeline_bucket_remote_service.dart';
import 'http_api_client.dart';

class HttpFavoriteTimelineBucketRemoteService
    implements FavoriteTimelineBucketRemoteService {
  HttpFavoriteTimelineBucketRemoteService(this._client);

  final HttpApiClient _client;

  @override
  Future<FavoriteTimelineBucketListDto> fetchBuckets({
    int limit = 20,
    String? cursor,
  }) async {
    final data = await _client.get(
      '/me/favorite-timeline-buckets',
      queryParameters: <String, String>{
        'limit': '$limit',
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    return FavoriteTimelineBucketListDto.fromJson(data);
  }

  @override
  Future<FavoriteTimelineBucketDto> favoriteBucket(
    FavoriteTimelineBucketRequestDto request,
  ) async {
    final data = await _client.post(
      '/me/favorite-timeline-buckets',
      body: request.toJson(),
    );
    return FavoriteTimelineBucketDto.fromJson(data);
  }

  @override
  Future<FavoriteTimelineBucketDeleteResultDto> deleteBucket(
    FavoriteTimelineBucketDeleteRequestDto request,
  ) async {
    final data = await _client.delete(
      '/me/favorite-timeline-buckets',
      body: request.toJson(),
    );
    return FavoriteTimelineBucketDeleteResultDto.fromJson(data);
  }

  @override
  Future<FavoriteTimelineBucketMergeResultDto> mergeGuestBuckets(
    FavoriteTimelineBucketMergeRequestDto request,
  ) async {
    final data = await _client.post(
      '/me/favorite-timeline-buckets/merge',
      body: request.toJson(),
      includeGuestKey: true,
    );
    return FavoriteTimelineBucketMergeResultDto.fromJson(data);
  }
}
