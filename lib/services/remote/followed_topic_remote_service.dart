import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../dto/followed_topic_dto.dart';
import '../../models/timeline_models.dart';
import '../mock_timeline_repository.dart';
import '../timeline_bucketing_service.dart';

abstract class FollowedTopicRemoteService {
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  });

  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  });

  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  });

  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  });

  Future<FollowMutationResultDto> followTopic({
    required String userId,
    required String topicId,
  });

  Future<FollowMutationResultDto> unfollowTopic({
    required String userId,
    required String topicId,
  });

  Future<FollowMutationResultDto> pinTopic({
    required String userId,
    required String topicId,
  });

  Future<FollowMutationResultDto> unpinTopic({
    required String userId,
    required String topicId,
  });
}

class MockFollowedTopicRemoteService implements FollowedTopicRemoteService {
  MockFollowedTopicRemoteService({
    required TimelineRepository repository,
    TimelineBucketingService? bucketingService,
  })  : _repository = repository,
        _bucketingService =
            bucketingService ?? const TimelineBucketingService();

  static const _storagePrefix = 'eventTimeline.mockRemote.followedTopics';

  final TimelineRepository _repository;
  final TimelineBucketingService _bucketingService;
  SharedPreferences? _prefs;

  @override
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  }) async {
    if (userId == null || userId.isEmpty) {
      return const UserCapabilitiesDto(
        authenticated: false,
        accountTier: 'guest',
        followLimit: 5,
      );
    }

    final items = await _loadItems(userId);
    final followCount = items.length;
    const followLimit = 10;
    return UserCapabilitiesDto(
      authenticated: true,
      accountTier: 'free',
      followLimit: followLimit,
      followCount: followCount,
      remainingFollowQuota: (followLimit - followCount).clamp(0, followLimit),
    );
  }

  @override
  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  }) async {
    final items = await _loadItems(userId);
    return FollowedTopicListDto(
      items: items,
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  }) async {
    final items = await _loadItems(userId);
    final existingTopicIds = items.map((item) => item.topicId).toSet();
    const followLimit = 10;
    var followCount = items.length;
    final mergedTopicIds = <String>[];
    final alreadyFollowedTopicIds = <String>[];
    final skippedTopicIds = <String>[];
    final skippedTopics = <GuestSkippedTopicDto>[];

    for (final topicId in guestTopicIds) {
      if (existingTopicIds.contains(topicId)) {
        alreadyFollowedTopicIds.add(topicId);
        continue;
      }
      if (followCount >= followLimit) {
        skippedTopicIds.add(topicId);
        skippedTopics.add(
          GuestSkippedTopicDto(
            topicId: topicId,
            reason: 'FOLLOW_LIMIT_REACHED',
          ),
        );
        continue;
      }
      final topic = await _findKnownTopic(topicId);
      if (topic == null) {
        skippedTopicIds.add(topicId);
        skippedTopics.add(
          GuestSkippedTopicDto(
            topicId: topicId,
            reason: 'TOPIC_NOT_FOUND',
          ),
        );
        continue;
      }

      final item = await _buildItem(
        topic: topic,
        isPinned: false,
        followedAt: DateTime.now(),
      );
      items.add(item);
      existingTopicIds.add(topicId);
      mergedTopicIds.add(topicId);
      followCount += 1;
    }

    await _saveItems(userId, items);
    return GuestFollowMergeResultDto(
      mergedTopicIds: mergedTopicIds,
      alreadyFollowedTopicIds: alreadyFollowedTopicIds,
      skippedTopicIds: skippedTopicIds,
      skippedTopics: skippedTopics,
      followCount: followCount,
      followLimit: followLimit,
      remainingFollowQuota: (followLimit - followCount).clamp(0, followLimit),
    );
  }

  @override
  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    final prefs = await _ensurePrefs();
    final key = '$_storagePrefix.claimedTopics.$userId';
    final alreadyClaimed = prefs.getStringList(key)?.toSet() ?? <String>{};
    final claimedTopicIds = <String>[];
    final alreadyOwnedTopicIds = <String>[];
    final skippedTopicIds = <String>[];

    for (final topicId in topicIds) {
      if (alreadyClaimed.contains(topicId)) {
        alreadyOwnedTopicIds.add(topicId);
        continue;
      }
      alreadyClaimed.add(topicId);
      claimedTopicIds.add(topicId);
    }

    await prefs.setStringList(key, alreadyClaimed.toList(growable: false));
    final capabilities = await fetchCapabilities(userId: userId);
    return GuestTopicClaimResultDto(
      claimedTopicIds: claimedTopicIds,
      alreadyOwnedTopicIds: alreadyOwnedTopicIds,
      skippedTopicIds: skippedTopicIds,
      followCount: capabilities.followCount ?? 0,
      followLimit: capabilities.followLimit,
      remainingFollowQuota:
          capabilities.remainingFollowQuota ?? capabilities.followLimit,
    );
  }

  @override
  Future<FollowMutationResultDto> followTopic({
    required String userId,
    required String topicId,
  }) async {
    final items = await _loadItems(userId);
    final existing = _findItem(items, topicId);
    if (existing != null) {
      return FollowMutationResultDto(
        followed: true,
        topicId: topicId,
        item: existing,
        isPinned: existing.isPinned,
        capabilities: await fetchCapabilities(userId: userId),
      );
    }

    final capabilities = await fetchCapabilities(userId: userId);
    if ((capabilities.remainingFollowQuota ?? capabilities.followLimit) <= 0) {
      throw Exception('已达到当前账号可关注上限。');
    }

    final topic = await _findKnownTopic(topicId);
    if (topic == null) {
      throw Exception('未找到要关注的专题。');
    }

    final item = await _buildItem(
      topic: topic,
      isPinned: false,
      followedAt: DateTime.now(),
    );
    final nextItems = <FollowedTopicItemDto>[...items, item];
    await _saveItems(userId, nextItems);
    return FollowMutationResultDto(
      followed: true,
      topicId: topicId,
      item: item,
      isPinned: false,
      capabilities: await fetchCapabilities(userId: userId),
    );
  }

  @override
  Future<FollowMutationResultDto> unfollowTopic({
    required String userId,
    required String topicId,
  }) async {
    final items = await _loadItems(userId);
    final nextItems = items.where((item) => item.topicId != topicId).toList();
    await _saveItems(userId, nextItems);
    return FollowMutationResultDto(
      followed: false,
      topicId: topicId,
      capabilities: await fetchCapabilities(userId: userId),
    );
  }

  @override
  Future<FollowMutationResultDto> pinTopic({
    required String userId,
    required String topicId,
  }) async {
    return _setPinnedState(
      userId: userId,
      topicId: topicId,
      isPinned: true,
    );
  }

  @override
  Future<FollowMutationResultDto> unpinTopic({
    required String userId,
    required String topicId,
  }) async {
    return _setPinnedState(
      userId: userId,
      topicId: topicId,
      isPinned: false,
    );
  }

  Future<FollowMutationResultDto> _setPinnedState({
    required String userId,
    required String topicId,
    required bool isPinned,
  }) async {
    final items = await _loadItems(userId);
    final index = items.indexWhere((item) => item.topicId == topicId);
    if (index < 0) {
      throw Exception('当前专题尚未关注。');
    }

    final updatedItem = items[index].copyWith(isPinned: isPinned);
    final nextItems = <FollowedTopicItemDto>[
      ...items.sublist(0, index),
      updatedItem,
      ...items.sublist(index + 1),
    ];
    await _saveItems(userId, nextItems);
    return FollowMutationResultDto(
      followed: true,
      topicId: topicId,
      item: updatedItem,
      isPinned: isPinned,
      capabilities: await fetchCapabilities(userId: userId),
    );
  }

  Future<List<FollowedTopicItemDto>> _loadItems(String userId) async {
    final prefs = await _ensurePrefs();
    final raw = prefs.getString(_userKey(userId));
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return FollowedTopicListDto.fromJson(decoded).items;
    }

    final trackedTopics = await _repository.fetchTrackedTopics();
    final seededItems = <FollowedTopicItemDto>[];
    for (final topic in trackedTopics) {
      seededItems.add(
        await _buildItem(
          topic: topic,
          isPinned: false,
          followedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      );
    }
    await _saveItems(userId, seededItems);
    return seededItems;
  }

  Future<void> _saveItems(
      String userId, List<FollowedTopicItemDto> items) async {
    final prefs = await _ensurePrefs();
    final payload = FollowedTopicListDto(
      items: items,
      generatedAt: DateTime.now(),
    );
    await prefs.setString(_userKey(userId), jsonEncode(payload.toJson()));
  }

  Future<Topic?> _findKnownTopic(String topicId) async {
    final trackedTopics = await _repository.fetchTrackedTopics();
    final recommendedTopics = await _repository.fetchRecommendedTopics();
    final topicsById = <String, Topic>{
      for (final topic in <Topic>[...trackedTopics, ...recommendedTopics])
        topic.id: topic,
    };
    return topicsById[topicId];
  }

  Future<FollowedTopicItemDto> _buildItem({
    required Topic topic,
    required bool isPinned,
    required DateTime followedAt,
  }) async {
    final timeline = await _repository.fetchTimeline(topic.id);
    final latestEntry = _bucketingService.latestEntry(timeline);
    final latestRelevantEventAt = latestEntry?.timestamp;
    return FollowedTopicItemDto(
      followId: 'follow_${topic.id}',
      topicId: topic.id,
      title: topic.name,
      summary: topic.tagline,
      isPinned: isPinned,
      followedAt: followedAt,
      latestRelevantEventAt: latestRelevantEventAt,
      latestRelevantEventSummary: latestEntry?.summary,
      hasRecentUpdate: latestRelevantEventAt != null &&
          DateTime.now().difference(latestRelevantEventAt) <=
              const Duration(hours: 24),
      unreadSignalCount: latestEntry == null ? null : 1,
    );
  }

  FollowedTopicItemDto? _findItem(
      List<FollowedTopicItemDto> items, String topicId) {
    for (final item in items) {
      if (item.topicId == topicId) {
        return item;
      }
    }
    return null;
  }

  Future<SharedPreferences> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _userKey(String userId) => '$_storagePrefix.$userId';
}
