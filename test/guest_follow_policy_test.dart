import 'package:event_timeline/dto/followed_topic_dto.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/followed_topic_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TimelineController? controller;

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  test('restores guest followed topics from local storage in public mode',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveGuestTrackedTopicIds(<String>[SampleData.aiTopic.id]);
    await storage.saveSelectedTopicId(SampleData.aiTopic.id);

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();

    expect(controller!.isGuest, isTrue);
    expect(controller!.trackedTopics.map((topic) => topic.id),
        <String>[SampleData.aiTopic.id]);
    expect(controller!.selectedTopicId, SampleData.aiTopic.id);
  });

  test('guest can follow up to five topics locally before login', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    controller!.showHotRecommendations();

    final topics = controller!.recommendationTopics
        .take(TimelineController.guestFollowLimit)
        .toList();
    for (final topic in topics) {
      await controller!.toggleFollow(topic);
    }

    expect(
      controller!.trackedTopics.map((topic) => topic.id).toSet(),
      equals(topics.map((topic) => topic.id).toSet()),
    );
    expect(
      storage.readGuestTrackedTopicIds().toSet(),
      equals(topics.map((topic) => topic.id).toSet()),
    );
    expect(controller!.pendingLoginPromptReason, isNull);
    expect(controller!.capabilities?.accountTier, 'guest');
    expect(controller!.capabilities?.followLimit, 5);
  });

  test(
      'guest follow over limit prompts login and keeps only five local follows',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    controller!.showHotRecommendations();

    final topics = controller!.recommendationTopics
        .take(TimelineController.guestFollowLimit + 1)
        .toList();
    for (final topic in topics.take(TimelineController.guestFollowLimit)) {
      await controller!.toggleFollow(topic);
    }

    final initialPromptToken = controller!.pendingLoginPromptToken;
    await controller!.toggleFollow(topics.last);

    expect(
        controller!.trackedTopics.length, TimelineController.guestFollowLimit);
    expect(controller!.isFollowing(topics.last), isFalse);
    expect(
        controller!.pendingLoginPromptToken, greaterThan(initialPromptToken));
    expect(controller!.pendingLoginPromptReason, '游客最多可关注 5 个专题，登录后可关注更多。');
    expect(storage.readGuestTrackedTopicIds().length,
        TimelineController.guestFollowLimit);
  });

  test('guest cannot create a new timeline after reaching the follow limit',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    controller!.showHotRecommendations();

    final topics = controller!.recommendationTopics
        .take(TimelineController.guestFollowLimit)
        .toList();
    for (final topic in topics) {
      await controller!.toggleFollow(topic);
    }

    final draft = await controller!.expandTimelineKeywords('游客专题 额度测试');

    await expectLater(
      controller!.createTimelineFromDraft(draft),
      throwsA(isA<Exception>()),
    );

    expect(
        controller!.trackedTopics.length, TimelineController.guestFollowLimit);
    expect(controller!.customTopics, isEmpty);
    expect(controller!.pendingLoginPromptReason, '游客最多可关注 5 个专题，登录后可关注更多。');
  });

  test(
      'guest created timelines share the same five-topic follow limit and quota is freed after unfollow',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    controller!.showHotRecommendations();

    final followedTopics = controller!.recommendationTopics.take(3).toList();
    for (final topic in followedTopics) {
      await controller!.toggleFollow(topic);
    }

    final firstDraft = await controller!.expandTimelineKeywords('游客自建专题一');
    final firstCreatedTopic =
        await controller!.createTimelineFromDraft(firstDraft);
    final secondDraft = await controller!.expandTimelineKeywords('游客自建专题二');
    final secondCreatedTopic =
        await controller!.createTimelineFromDraft(secondDraft);
    final blockedDraft = await controller!.expandTimelineKeywords('游客自建专题三');

    await expectLater(
      controller!.createTimelineFromDraft(blockedDraft),
      throwsA(isA<Exception>()),
    );

    expect(
        controller!.trackedTopics.length, TimelineController.guestFollowLimit);
    expect(
      controller!.trackedTopics.map((topic) => topic.id),
      containsAll(<String>[
        ...followedTopics.map((topic) => topic.id),
        firstCreatedTopic.id,
        secondCreatedTopic.id,
      ]),
    );
    expect(controller!.pendingLoginPromptReason, '游客最多可关注 5 个专题，登录后可关注更多。');
    expect(storage.readGuestTrackedTopicIds().length,
        TimelineController.guestFollowLimit);

    controller!.clearLoginPrompt();
    await controller!.toggleFollow(followedTopics.first);

    expect(controller!.trackedTopics.length,
        TimelineController.guestFollowLimit - 1);
    expect(controller!.isFollowing(followedTopics.first), isFalse);

    final thirdCreatedTopic =
        await controller!.createTimelineFromDraft(blockedDraft);

    expect(
        controller!.trackedTopics.length, TimelineController.guestFollowLimit);
    expect(
      controller!.trackedTopics.map((topic) => topic.id),
      containsAll(<String>[
        firstCreatedTopic.id,
        secondCreatedTopic.id,
        thirdCreatedTopic.id,
      ]),
    );
    expect(storage.readGuestTrackedTopicIds().length,
        TimelineController.guestFollowLimit);
  });

  test('login merges guest follows into account and clears local guest staging',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveGuestTrackedTopicIds(
        <String>[SampleData.aiTopic.id, SampleData.chipTopic.id]);

    final authService = MockPhoneAuthService();
    final remoteService = _MergingFollowedTopicRemoteService();
    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: authService,
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    await controller!.sendVerificationCode('13812345678');
    await controller!.verifySmsCode(
      rawPhoneNumber: '13812345678',
      smsCode: controller!.debugVerificationCode!,
    );

    expect(remoteService.mergeCalls, <List<String>>[
      <String>[SampleData.aiTopic.id, SampleData.chipTopic.id],
    ]);
    expect(storage.readGuestTrackedTopicIds(), isEmpty);
    expect(controller!.isRegistered, isTrue);
    expect(controller!.capabilities?.followCount, 2);
    expect(
      controller!.trackedTopics.map((topic) => topic.id),
      containsAll(<String>[SampleData.aiTopic.id, SampleData.chipTopic.id]),
    );
  });

  test('guest over-limit follow resumes automatically after login', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final authService = MockPhoneAuthService();
    final remoteService = _MergingFollowedTopicRemoteService();
    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: authService,
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    controller!.showHotRecommendations();

    final topics = controller!.recommendationTopics.take(6).toList();
    for (final topic in topics.take(5)) {
      await controller!.toggleFollow(topic);
    }

    await controller!.toggleFollow(topics[5]);
    expect(controller!.pendingLoginPromptReason, '游客最多可关注 5 个专题，登录后可关注更多。');
    expect(controller!.isFollowing(topics[5]), isFalse);

    await controller!.sendVerificationCode('13812345680');
    await controller!.verifySmsCode(
      rawPhoneNumber: '13812345680',
      smsCode: controller!.debugVerificationCode!,
    );

    expect(controller!.isRegistered, isTrue);
    expect(controller!.trackedTopics.map((topic) => topic.id),
        contains(topics[5].id));
    expect(controller!.capabilities?.followCount, 6);
  });

  test('guest custom topics remain in followed list after login merge',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final authService = MockPhoneAuthService();
    final remoteService = _MergingFollowedTopicRemoteService();
    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: authService,
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    controller!.showHotRecommendations();

    final serverTopics = controller!.recommendationTopics.take(3).toList();
    for (final topic in serverTopics) {
      await controller!.toggleFollow(topic);
    }

    final firstDraft = await controller!.expandTimelineKeywords('游客自建专题一');
    final firstCustomTopic =
        await controller!.createTimelineFromDraft(firstDraft);
    final secondDraft = await controller!.expandTimelineKeywords('游客自建专题二');
    final secondCustomTopic =
        await controller!.createTimelineFromDraft(secondDraft);

    expect(controller!.trackedTopics.length, 5);

    await controller!.sendVerificationCode('13812345679');
    await controller!.verifySmsCode(
      rawPhoneNumber: '13812345679',
      smsCode: controller!.debugVerificationCode!,
    );

    expect(remoteService.mergeCalls, hasLength(1));
    expect(
      remoteService.mergeCalls.single.toSet(),
      equals(<String>{
        ...serverTopics.map((topic) => topic.id),
        firstCustomTopic.id,
        secondCustomTopic.id,
      }),
    );
    expect(storage.readGuestTrackedTopicIds(), isEmpty);
    expect(
        controller!.trackedTopics.map((topic) => topic.id),
        containsAll(<String>[
          ...serverTopics.map((topic) => topic.id),
          firstCustomTopic.id,
          secondCustomTopic.id,
        ]));
    expect(controller!.capabilities?.followCount, 5);
  });

  test('guest unfollowed created topics are not claimed after login', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final authService = MockPhoneAuthService();
    final remoteService = _MergingFollowedTopicRemoteService();
    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: authService,
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();

    final createdTopics = <Topic>[];
    for (final label in <String>['A', 'B', 'C', 'D', 'E']) {
      final draft = await controller!.expandTimelineKeywords('游客自建专题$label');
      createdTopics.add(await controller!.createTimelineFromDraft(draft));
    }

    for (final topic in createdTopics.skip(2).take(3)) {
      await controller!.toggleFollow(topic);
    }

    final replacementTopics = <Topic>[];
    for (final label in <String>['F', 'G', 'H']) {
      final draft = await controller!.expandTimelineKeywords('游客自建专题$label');
      replacementTopics.add(await controller!.createTimelineFromDraft(draft));
    }

    final expectedActiveIds = <String>{
      createdTopics[0].id,
      createdTopics[1].id,
      ...replacementTopics.map((topic) => topic.id),
    };
    final removedIds = <String>{
      createdTopics[2].id,
      createdTopics[3].id,
      createdTopics[4].id,
    };

    expect(controller!.trackedTopics.map((topic) => topic.id).toSet(),
        expectedActiveIds);
    expect(storage.readGuestTrackedTopicIds().toSet(), expectedActiveIds);
    expect(storage.readGuestCreatedTopicIds().toSet(),
        containsAll(<String>{...expectedActiveIds, ...removedIds}));

    await controller!.sendVerificationCode('13812345681');
    await controller!.verifySmsCode(
      rawPhoneNumber: '13812345681',
      smsCode: controller!.debugVerificationCode!,
    );

    expect(remoteService.mergeCalls, hasLength(1));
    expect(remoteService.mergeCalls.single.toSet(), expectedActiveIds);
    expect(remoteService.claimCalls, hasLength(1));
    expect(remoteService.claimCalls.single.toSet(), expectedActiveIds);
    expect(
      controller!.trackedTopics.map((topic) => topic.id).toSet(),
      expectedActiveIds,
    );
    expect(
      controller!.trackedTopics.map((topic) => topic.id).toSet(),
      isNot(containsAll(removedIds)),
    );
    expect(storage.readGuestCreatedTopicIds(), isEmpty);
  });

  test('logout preserves current followed topics and timeline content',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final authService = MockPhoneAuthService();
    final remoteService = _MergingFollowedTopicRemoteService();
    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: authService,
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    controller!.showHotRecommendations();

    final followedTopic = controller!.recommendationTopics.first;
    await controller!.toggleFollow(followedTopic);
    await controller!.sendVerificationCode('13812345682');
    await controller!.verifySmsCode(
      rawPhoneNumber: '13812345682',
      smsCode: controller!.debugVerificationCode!,
    );

    expect(controller!.isRegistered, isTrue);
    expect(controller!.trackedTopics.map((topic) => topic.id),
        contains(followedTopic.id));

    await controller!.logout();

    expect(controller!.isGuest, isTrue);
    expect(controller!.trackedTopics.map((topic) => topic.id),
        contains(followedTopic.id));
    expect(controller!.selectedTopicId, isNotNull);
    expect(storage.readGuestTrackedTopicIds(), contains(followedTopic.id));
  });

  test('full account keeps skipped guest follows and retries after unfollow',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    final pendingGuestTopicId = SampleData.moonTopic.id;
    await storage.saveGuestTrackedTopicIds(<String>[pendingGuestTopicId]);
    await storage.saveGuestCreatedTopicIds(<String>[pendingGuestTopicId]);

    final authService = MockPhoneAuthService();
    final accountTopicIds = SampleData.topics
        .where((topic) => topic.id != pendingGuestTopicId)
        .map((topic) => topic.id)
        .take(10)
        .toList();
    final remoteService = _MergingFollowedTopicRemoteService(
      initialTopicIds: accountTopicIds,
    );
    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: authService,
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );

    await controller!.initialize();
    await controller!.sendVerificationCode('13812345683');
    await controller!.verifySmsCode(
      rawPhoneNumber: '13812345683',
      smsCode: controller!.debugVerificationCode!,
    );

    expect(remoteService.topicIds, hasLength(10));
    expect(remoteService.topicIds, isNot(contains(pendingGuestTopicId)));
    expect(storage.readGuestTrackedTopicIds(), <String>[pendingGuestTopicId]);
    expect(storage.readGuestCreatedTopicIds(), <String>[pendingGuestTopicId]);
    expect(controller!.errorMessage, contains('账号关注已满'));

    final topicToUnfollow = controller!.trackedTopics.first;
    await controller!.removeTrackedTopic(topicToUnfollow);

    expect(remoteService.topicIds, hasLength(10));
    expect(remoteService.topicIds, contains(pendingGuestTopicId));
    expect(remoteService.topicIds, isNot(contains(topicToUnfollow.id)));
    expect(storage.readGuestTrackedTopicIds(), isEmpty);
    expect(storage.readGuestCreatedTopicIds(), isEmpty);
  });
}

class _MergingFollowedTopicRemoteService implements FollowedTopicRemoteService {
  _MergingFollowedTopicRemoteService({
    int followLimit = 10,
    List<String> initialTopicIds = const <String>[],
  })  : _followLimit = followLimit,
        _items = initialTopicIds
            .map(
              (topicId) => _itemForTopicId(
                topicId,
                summarySuffix: '已关注',
              ),
            )
            .toList();

  final int _followLimit;
  final List<FollowedTopicItemDto> _items;
  final List<List<String>> mergeCalls = <List<String>>[];
  final List<List<String>> claimCalls = <List<String>>[];

  List<String> get topicIds => _items.map((item) => item.topicId).toList();

  static FollowedTopicItemDto _itemForTopicId(
    String topicId, {
    required String summarySuffix,
  }) {
    final topic = SampleData.topics.cast<Topic?>().firstWhere(
          (item) => item?.id == topicId,
          orElse: () => null,
        );
    return FollowedTopicItemDto(
      followId: 'follow_$topicId',
      topicId: topicId,
      title: topic?.name ?? topicId,
      summary: topic?.tagline ?? '游客自建专题',
      isPinned: false,
      followedAt: DateTime(2026, 4, 19, 9, 0),
      latestRelevantEventAt: DateTime(2026, 4, 19, 9, 0),
      latestRelevantEventSummary: '${topic?.name ?? topicId} $summarySuffix',
      hasRecentUpdate: true,
    );
  }

  @override
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  }) async {
    return UserCapabilitiesDto(
      authenticated: userId != null,
      accountTier: userId == null ? 'guest' : 'free',
      followLimit: userId == null ? 5 : _followLimit,
      followCount: userId == null ? null : _items.length,
      remainingFollowQuota: userId == null
          ? null
          : (_followLimit - _items.length).clamp(0, _followLimit),
    );
  }

  @override
  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  }) async {
    return FollowedTopicListDto(
      items: List<FollowedTopicItemDto>.from(_items),
      generatedAt: DateTime(2026, 4, 19, 9, 0),
    );
  }

  @override
  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  }) async {
    mergeCalls.add(List<String>.from(guestTopicIds));
    final existingIds = _items.map((item) => item.topicId).toSet();
    final mergedIds = <String>[];
    final alreadyFollowedIds = <String>[];
    final skippedIds = <String>[];
    final skippedTopics = <GuestSkippedTopicDto>[];
    var followCount = _items.length;
    for (final topicId in guestTopicIds) {
      if (existingIds.contains(topicId)) {
        alreadyFollowedIds.add(topicId);
        continue;
      }
      if (followCount >= _followLimit) {
        skippedIds.add(topicId);
        skippedTopics.add(
          GuestSkippedTopicDto(
            topicId: topicId,
            reason: 'FOLLOW_LIMIT_REACHED',
          ),
        );
        continue;
      }
      _items.add(_itemForTopicId(topicId, summarySuffix: '已合并'));
      existingIds.add(topicId);
      mergedIds.add(topicId);
      followCount += 1;
    }
    return GuestFollowMergeResultDto(
      mergedTopicIds: mergedIds,
      alreadyFollowedTopicIds: alreadyFollowedIds,
      skippedTopicIds: skippedIds,
      skippedTopics: skippedTopics,
      followCount: followCount,
      followLimit: _followLimit,
      remainingFollowQuota: (_followLimit - followCount).clamp(0, _followLimit),
    );
  }

  @override
  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    claimCalls.add(List<String>.from(topicIds));
    final followedIds = _items.map((item) => item.topicId).toSet();
    final claimedIds = <String>[];
    final skippedIds = <String>[];
    final skippedTopics = <GuestSkippedTopicDto>[];
    for (final topicId in topicIds) {
      if (followedIds.contains(topicId)) {
        claimedIds.add(topicId);
        continue;
      }
      skippedIds.add(topicId);
      skippedTopics.add(
        GuestSkippedTopicDto(
          topicId: topicId,
          reason: 'FOLLOW_LIMIT_REACHED',
        ),
      );
    }
    return GuestTopicClaimResultDto(
      claimedTopicIds: claimedIds,
      alreadyOwnedTopicIds: const <String>[],
      skippedTopicIds: skippedIds,
      skippedTopics: skippedTopics,
      followCount: _items.length,
      followLimit: _followLimit,
      remainingFollowQuota:
          (_followLimit - _items.length).clamp(0, _followLimit),
    );
  }

  @override
  Future<FollowMutationResultDto> followTopic({
    required String userId,
    required String topicId,
  }) async {
    final existingIndex = _items.indexWhere((item) => item.topicId == topicId);
    if (existingIndex >= 0) {
      return FollowMutationResultDto(
        followed: true,
        topicId: topicId,
        item: _items[existingIndex],
        capabilities: UserCapabilitiesDto(
          authenticated: true,
          accountTier: 'free',
          followLimit: _followLimit,
          followCount: _items.length,
          remainingFollowQuota:
              (_followLimit - _items.length).clamp(0, _followLimit),
        ),
      );
    }

    final topic = SampleData.topics.firstWhere((item) => item.id == topicId);
    final followedItem = _itemForTopicId(topic.id, summarySuffix: '已关注');
    _items.add(followedItem);
    return FollowMutationResultDto(
      followed: true,
      topicId: topicId,
      item: followedItem,
      capabilities: UserCapabilitiesDto(
        authenticated: true,
        accountTier: 'free',
        followLimit: _followLimit,
        followCount: _items.length,
        remainingFollowQuota:
            (_followLimit - _items.length).clamp(0, _followLimit),
      ),
    );
  }

  @override
  Future<FollowMutationResultDto> unfollowTopic({
    required String userId,
    required String topicId,
  }) async {
    _items.removeWhere((item) => item.topicId == topicId);
    return FollowMutationResultDto(
      followed: false,
      topicId: topicId,
      capabilities: UserCapabilitiesDto(
        authenticated: true,
        accountTier: 'free',
        followLimit: _followLimit,
        followCount: _items.length,
        remainingFollowQuota:
            (_followLimit - _items.length).clamp(0, _followLimit),
      ),
    );
  }

  @override
  Future<FollowMutationResultDto> pinTopic({
    required String userId,
    required String topicId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FollowMutationResultDto> unpinTopic({
    required String userId,
    required String topicId,
  }) async {
    throw UnimplementedError();
  }
}
