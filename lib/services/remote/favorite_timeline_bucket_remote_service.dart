import '../../dto/favorite_timeline_bucket_dto.dart';
import '../../models/timeline_models.dart';

abstract class FavoriteTimelineBucketRemoteService {
  Future<FavoriteTimelineBucketListDto> fetchBuckets({
    int limit = 20,
    String? cursor,
  });

  Future<FavoriteTimelineBucketDto> favoriteBucket(
    FavoriteTimelineBucketRequestDto request,
  );

  Future<FavoriteTimelineBucketDeleteResultDto> deleteBucket(
    FavoriteTimelineBucketDeleteRequestDto request,
  );

  Future<FavoriteTimelineBucketMergeResultDto> mergeGuestBuckets(
    FavoriteTimelineBucketMergeRequestDto request,
  );
}

class MockFavoriteTimelineBucketRemoteService
    implements FavoriteTimelineBucketRemoteService {
  final List<FavoriteTimelineBucketDto> _items = <FavoriteTimelineBucketDto>[];
  int _nextId = 1;

  @override
  Future<FavoriteTimelineBucketListDto> fetchBuckets({
    int limit = 20,
    String? cursor,
  }) async {
    return FavoriteTimelineBucketListDto(
      items: _items.take(limit).toList(),
      hasMore: _items.length > limit,
    );
  }

  @override
  Future<FavoriteTimelineBucketDto> favoriteBucket(
    FavoriteTimelineBucketRequestDto request,
  ) async {
    for (final item in _items) {
      if (_overlapsRequest(item, request)) {
        return item;
      }
    }

    final item = FavoriteTimelineBucketDto(
      favoriteId: 'mock-fav-${_nextId++}',
      topicId: request.topicId,
      topicTitle: request.topicTitle,
      topicSummary: request.topicSummary,
      bucketKey: request.bucketKey,
      bucketGranularity: request.bucketGranularity,
      bucketLabel: request.bucketLabel,
      bucketStart: request.bucketStart,
      bucketEnd: request.bucketEnd,
      headline: request.headline ?? request.bucketLabel,
      summary: request.summary ?? '',
      primarySignal: request.primarySignal,
      containsMajorEvent: request.containsMajorEvent,
      savedAt: request.savedAt ?? DateTime.now(),
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<FavoriteTimelineBucketDeleteResultDto> deleteBucket(
    FavoriteTimelineBucketDeleteRequestDto request,
  ) async {
    final before = _items.length;
    _items.removeWhere(
      (item) =>
          item.topicId == request.topicId &&
          timelineRangesOverlap(
            item.bucketStart,
            item.bucketEnd,
            request.bucketStart,
            request.bucketEnd,
          ),
    );
    return FavoriteTimelineBucketDeleteResultDto(
      removed: before - _items.length,
    );
  }

  @override
  Future<FavoriteTimelineBucketMergeResultDto> mergeGuestBuckets(
    FavoriteTimelineBucketMergeRequestDto request,
  ) async {
    var merged = 0;
    var alreadyExists = 0;
    for (final item in request.items) {
      final exists = _items.any((existing) => _overlapsRequest(existing, item));
      if (exists) {
        alreadyExists += 1;
        continue;
      }
      await favoriteBucket(item);
      merged += 1;
    }
    return FavoriteTimelineBucketMergeResultDto(
      merged: merged,
      alreadyExists: alreadyExists,
      skipped: 0,
      skippedItems: const <FavoriteTimelineBucketSkippedDto>[],
    );
  }

  bool _overlapsRequest(
    FavoriteTimelineBucketDto item,
    FavoriteTimelineBucketRequestDto request,
  ) {
    return item.topicId == request.topicId &&
        timelineRangesOverlap(
          item.bucketStart,
          item.bucketEnd,
          request.bucketStart,
          request.bucketEnd,
        );
  }
}
