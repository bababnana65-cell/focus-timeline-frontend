import 'package:event_timeline/dto/followed_topic_dto.dart';
import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/dto/topic_context_contract_dto.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/followed_topic_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  TimelineController? controller;

  tearDown(() {
    controller?.dispose();
    controller = null;
  });

  AuthSession buildSession() {
    return AuthSession(
      userId: 'user_13812345678',
      sessionToken: 'sess_001',
      issuedAt: DateTime(2026, 4, 18, 9, 0),
      expiresAt: DateTime(2026, 4, 25, 9, 0),
      identityType: 'phone',
      provider: 'sms',
      primaryPhone: '13812345678',
    );
  }

  test('loads tracked topics from remote followed-topic DTO and caches mirror',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final remoteService = _InMemoryFollowedTopicRemoteService(
      initialItems: <FollowedTopicItemDto>[
        FollowedTopicItemDto(
          followId: 'follow_ai-model-release',
          topicId: SampleData.aiTopic.id,
          title: SampleData.aiTopic.name,
          summary: SampleData.aiTopic.tagline,
          isPinned: true,
          followedAt: DateTime(2026, 4, 10, 9, 0),
          latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
          latestRelevantEventSummary: '局势出现新一轮升级信号',
          hasRecentUpdate: true,
          unreadSignalCount: 2,
        ),
        FollowedTopicItemDto(
          followId: 'follow_chip-supply-chain',
          topicId: SampleData.chipTopic.id,
          title: SampleData.chipTopic.name,
          summary: SampleData.chipTopic.tagline,
          isPinned: false,
          followedAt: DateTime(2026, 4, 9, 9, 0),
          latestRelevantEventAt: DateTime(2026, 4, 18, 7, 0),
          latestRelevantEventSummary: '先进封装产线宣布追加投资。',
          hasRecentUpdate: true,
        ),
      ],
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    expect(
      controller!.trackedTopics.map((topic) => topic.id),
      <String>[SampleData.aiTopic.id, SampleData.chipTopic.id],
    );
    expect(controller!.pinnedTopicIds, <String>[SampleData.aiTopic.id]);
    expect(controller!.latestEntryForTopic(SampleData.chipTopic.id)?.summary,
        '先进封装产线宣布追加投资。');
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .map((item) => item.topicId),
      <String>[SampleData.aiTopic.id, SampleData.chipTopic.id],
    );
    expect(controller!.hasTrackedTopicsRecentUpdate, isTrue);
  });

  test('falls back to cached followed-topic snapshot when remote fetch fails',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());
    await storage.saveFollowedTopicSnapshot(
      FollowedTopicListDto(
        generatedAt: DateTime(2026, 4, 18, 9, 0),
        items: <FollowedTopicItemDto>[
          FollowedTopicItemDto(
            followId: 'follow_chip-supply-chain',
            topicId: SampleData.chipTopic.id,
            title: SampleData.chipTopic.name,
            summary: SampleData.chipTopic.tagline,
            isPinned: false,
            followedAt: DateTime(2026, 4, 10, 9, 0),
            latestRelevantEventAt: DateTime(2026, 4, 18, 7, 0),
            latestRelevantEventSummary: '先进封装产线宣布追加投资。',
            hasRecentUpdate: true,
            unreadSignalCount: 1,
          ),
        ],
      ),
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: _FailingFollowedTopicRemoteService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    expect(controller!.trackedTopics.map((topic) => topic.id),
        <String>[SampleData.chipTopic.id]);
    expect(controller!.trackedTopics.map((topic) => topic.id),
        <String>[SampleData.chipTopic.id]);
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .map((item) => item.topicId),
      <String>[SampleData.chipTopic.id],
    );
  });

  test('opening a followed topic clears local recent-update reminder state',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: _InMemoryFollowedTopicRemoteService(
        initialItems: <FollowedTopicItemDto>[
          FollowedTopicItemDto(
            followId: 'follow_ai-model-release',
            topicId: SampleData.aiTopic.id,
            title: SampleData.aiTopic.name,
            summary: SampleData.aiTopic.tagline,
            isPinned: false,
            followedAt: DateTime(2026, 4, 10, 9, 0),
            latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
            latestRelevantEventSummary: '局势出现新一轮升级信号',
            hasRecentUpdate: true,
            unreadSignalCount: 1,
          ),
        ],
      ),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    expect(controller!.hasTrackedTopicsRecentUpdate, isTrue);
    expect(controller!.topicHasRecentUpdate(SampleData.aiTopic.id), isTrue);

    await controller!.selectTopic(SampleData.aiTopic);

    expect(controller!.hasTrackedTopicsRecentUpdate, isFalse);
    expect(controller!.topicHasRecentUpdate(SampleData.aiTopic.id), isFalse);
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .firstWhere((item) => item.topicId == SampleData.aiTopic.id)
          .hasRecentUpdate,
      isFalse,
    );
  });

  test('major-node reminder only shows red dots for major latest updates',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: _InMemoryFollowedTopicRemoteService(
        initialItems: <FollowedTopicItemDto>[
          FollowedTopicItemDto(
            followId: 'follow_ai-model-release',
            topicId: SampleData.aiTopic.id,
            title: SampleData.aiTopic.name,
            summary: SampleData.aiTopic.tagline,
            isPinned: false,
            followedAt: DateTime(2026, 4, 10, 9, 0),
            latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
            latestRelevantEventSummary: '局势出现新一轮升级信号',
            hasRecentUpdate: true,
            unreadSignalCount: 1,
            latestNode: LatestNodeDto(
              id: 'ai-major',
              occurredAt: DateTime(2026, 4, 18, 8, 0),
              headline: '重大节点',
              summary: '局势出现新一轮升级信号',
              isMajor: true,
            ),
          ),
          FollowedTopicItemDto(
            followId: 'follow_chip-supply-chain',
            topicId: SampleData.chipTopic.id,
            title: SampleData.chipTopic.name,
            summary: SampleData.chipTopic.tagline,
            isPinned: false,
            followedAt: DateTime(2026, 4, 10, 9, 0),
            latestRelevantEventAt: DateTime(2026, 4, 18, 8, 10),
            latestRelevantEventSummary: '普通更新',
            hasRecentUpdate: true,
            unreadSignalCount: 1,
            latestNode: LatestNodeDto(
              id: 'chip-minor',
              occurredAt: DateTime(2026, 4, 18, 8, 10),
              headline: '普通更新',
              summary: '普通更新',
              isMajor: false,
            ),
          ),
        ],
      ),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    controller!.markRecentUpdateReminderBaselineForTest(
      SampleData.aiTopic.id,
      DateTime(2026, 4, 18, 7, 0),
    );
    controller!.markRecentUpdateReminderBaselineForTest(
      SampleData.chipTopic.id,
      DateTime(2026, 4, 18, 7, 0),
    );
    controller!.setRecentUpdateReminderMode(
      RecentUpdateReminderMode.majorOnly,
    );

    expect(controller!.hasTrackedTopicsRecentUpdate, isTrue);
    expect(controller!.shouldShowTopicRecentUpdateDot(SampleData.aiTopic.id),
        isTrue);
    expect(controller!.shouldShowTopicRecentUpdateDot(SampleData.chipTopic.id),
        isFalse);
    expect(controller!.shouldShowTrackedTopicsRecentUpdateDot, isTrue);

    controller!.setRecentUpdateReminderMode(RecentUpdateReminderMode.all);

    expect(controller!.hasTrackedTopicsRecentUpdate, isTrue);
    expect(controller!.shouldShowTopicRecentUpdateDot(SampleData.aiTopic.id),
        isTrue);
    expect(controller!.shouldShowTopicRecentUpdateDot(SampleData.chipTopic.id),
        isTrue);

    controller!.setRecentUpdateReminderMode(RecentUpdateReminderMode.off);

    expect(controller!.hasTrackedTopicsRecentUpdate, isTrue);
    expect(controller!.shouldShowTrackedTopicsRecentUpdateDot, isFalse);
    expect(controller!.shouldShowTopicRecentUpdateDot(SampleData.aiTopic.id),
        isFalse);
  });

  test('initial followed-topic snapshot suppresses reminder red dots',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: _InMemoryFollowedTopicRemoteService(
        initialItems: <FollowedTopicItemDto>[
          FollowedTopicItemDto(
            followId: 'follow_ai-model-release',
            topicId: SampleData.aiTopic.id,
            title: SampleData.aiTopic.name,
            summary: SampleData.aiTopic.tagline,
            isPinned: false,
            followedAt: DateTime(2026, 4, 10, 9, 0),
            latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
            latestRelevantEventSummary: '首次登录时已有的最新节点',
            hasRecentUpdate: true,
            unreadSignalCount: 1,
            latestNode: LatestNodeDto(
              id: 'ai-existing-major',
              occurredAt: DateTime(2026, 4, 18, 8, 0),
              headline: '已有重大节点',
              summary: '首次登录时已有的最新节点',
              isMajor: true,
            ),
          ),
        ],
      ),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    expect(controller!.hasTrackedTopicsRecentUpdate, isTrue);
    expect(controller!.topicHasRecentUpdate(SampleData.aiTopic.id), isTrue);
    expect(controller!.shouldShowTrackedTopicsRecentUpdateDot, isFalse);
    expect(controller!.shouldShowTopicRecentUpdateDot(SampleData.aiTopic.id),
        isFalse);
  });

  test('follow, pin, and unfollow are driven by followed-topic remote service',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final remoteService = _InMemoryFollowedTopicRemoteService(
      initialItems: <FollowedTopicItemDto>[
        FollowedTopicItemDto(
          followId: 'follow_ai-model-release',
          topicId: SampleData.aiTopic.id,
          title: SampleData.aiTopic.name,
          summary: SampleData.aiTopic.tagline,
          isPinned: false,
          followedAt: DateTime(2026, 4, 10, 9, 0),
          latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
          latestRelevantEventSummary: '局势出现新一轮升级信号',
          hasRecentUpdate: true,
        ),
      ],
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    final newTopic = controller!.recommendedTopics.firstWhere(
      (topic) => controller!.trackedTopics
          .every((trackedTopic) => trackedTopic.id != topic.id),
    );

    await controller!.toggleFollow(newTopic);

    expect(remoteService.followCalls, <String>[newTopic.id]);
    expect(controller!.isFollowing(newTopic), isTrue);
    expect(controller!.capabilities?.followCount, 2);
    expect(controller!.capabilities?.remainingFollowQuota, 8);
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .any((item) => item.topicId == newTopic.id),
      isTrue,
    );

    await controller!.pinTopic(newTopic);

    expect(remoteService.pinCalls, <String>[newTopic.id]);
    expect(controller!.isPinned(newTopic), isTrue);
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .firstWhere((item) => item.topicId == newTopic.id)
          .isPinned,
      isTrue,
    );

    await controller!.removeTrackedTopic(newTopic);

    expect(remoteService.unfollowCalls, <String>[newTopic.id]);
    expect(controller!.isFollowing(newTopic), isFalse);
    expect(controller!.capabilities?.followCount, 1);
    expect(controller!.capabilities?.remainingFollowQuota, 9);
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .any((item) => item.topicId == newTopic.id),
      isFalse,
    );
  });

  test('follow mutation tolerates partial server payload item', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final remoteService = _InMemoryFollowedTopicRemoteService(
      initialItems: <FollowedTopicItemDto>[
        FollowedTopicItemDto(
          followId: 'follow_ai-model-release',
          topicId: SampleData.aiTopic.id,
          title: SampleData.aiTopic.name,
          summary: SampleData.aiTopic.tagline,
          isPinned: false,
          followedAt: DateTime(2026, 4, 10, 9, 0),
          latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
          latestRelevantEventSummary: '局势出现新一轮升级信号',
          hasRecentUpdate: true,
        ),
      ],
      returnPartialMutationItem: true,
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    final newTopic = controller!.recommendedTopics.firstWhere(
      (topic) => controller!.trackedTopics
          .every((trackedTopic) => trackedTopic.id != topic.id),
    );

    await controller!.toggleFollow(newTopic);

    expect(controller!.isFollowing(newTopic), isTrue);
    expect(
      controller!.trackedTopics
          .firstWhere((topic) => topic.id == newTopic.id)
          .name,
      newTopic.name,
    );
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .any((item) => item.topicId == newTopic.id),
      isTrue,
    );
    expect(controller!.errorMessage, isNull);
  });

  test('pin mutation accepts server payload without followed item', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final remoteService = _InMemoryFollowedTopicRemoteService(
      initialItems: <FollowedTopicItemDto>[
        FollowedTopicItemDto(
          followId: 'follow_ai-model-release',
          topicId: SampleData.aiTopic.id,
          title: SampleData.aiTopic.name,
          summary: SampleData.aiTopic.tagline,
          isPinned: false,
          followedAt: DateTime(2026, 4, 10, 9, 0),
          latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
          latestRelevantEventSummary: '局势出现新一轮升级信号',
          hasRecentUpdate: true,
        ),
      ],
      returnPinPayloadWithoutItem: true,
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller!.initialize();

    final topic = controller!.trackedTopics.first;

    await controller!.pinTopic(topic);

    expect(remoteService.pinCalls, <String>[topic.id]);
    expect(controller!.isFollowing(topic), isTrue);
    expect(controller!.isPinned(topic), isTrue);
    expect(controller!.trackedTopics.first.id, topic.id);
    expect(
      storage
          .readFollowedTopicSnapshot()
          ?.payload
          .items
          .firstWhere((item) => item.topicId == topic.id)
          .isPinned,
      isTrue,
    );
  });

  test(
      'already-followed conflict reconciles to followed state instead of retry loop',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final remoteService = _InMemoryFollowedTopicRemoteService(
      initialItems: const <FollowedTopicItemDto>[],
      conflictFollowTopicIds: <String>{SampleData.aiTopic.id},
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    await controller.toggleFollow(SampleData.aiTopic);

    expect(remoteService.followCalls, <String>[SampleData.aiTopic.id]);
    expect(controller.isFollowing(SampleData.aiTopic), isTrue);
    expect(controller.selectedTopicId, SampleData.aiTopic.id);
    expect(controller.errorMessage, contains('已同步关注状态'));
    expect(
      storage.readFollowedTopicSnapshot()?.payload.items.any(
            (item) => item.topicId == SampleData.aiTopic.id,
          ),
      isTrue,
    );
  });

  test(
      'prefers server-managed selected topic over stale cached topic in http runtime mode',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());
    await storage.saveTrackedTopicIds(<String>[SampleData.lowAltitudeTopic.id]);
    await storage.saveSelectedTopicId(SampleData.lowAltitudeTopic.id);

    final remoteService = _InMemoryFollowedTopicRemoteService(
      initialItems: <FollowedTopicItemDto>[
        FollowedTopicItemDto(
          followId: 'follow_ai-model-release',
          topicId: SampleData.aiTopic.id,
          title: SampleData.aiTopic.name,
          summary: SampleData.aiTopic.tagline,
          isPinned: false,
          followedAt: DateTime(2026, 4, 10, 9, 0),
          latestRelevantEventAt: DateTime(2026, 4, 18, 8, 0),
          latestRelevantEventSummary: '局势出现新一轮升级信号',
          hasRecentUpdate: true,
        ),
      ],
    );

    controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      followedTopicRemoteService: remoteService,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      preferServerRuntimeTopics: true,
    );
    await controller!.initialize();

    expect(controller!.selectedTopicId, SampleData.aiTopic.id);
    expect(controller!.trackedTopics.map((topic) => topic.id),
        <String>[SampleData.aiTopic.id]);
    expect(
        controller!.trackedTopics
            .any((topic) => topic.id == SampleData.lowAltitudeTopic.id),
        isFalse);
  });
}

class _InMemoryFollowedTopicRemoteService
    implements FollowedTopicRemoteService {
  _InMemoryFollowedTopicRemoteService({
    required List<FollowedTopicItemDto> initialItems,
    this.returnPartialMutationItem = false,
    this.returnPinPayloadWithoutItem = false,
    Set<String>? conflictFollowTopicIds,
  })  : _items = List<FollowedTopicItemDto>.from(initialItems),
        conflictFollowTopicIds = conflictFollowTopicIds ?? <String>{};

  final List<FollowedTopicItemDto> _items;
  final bool returnPartialMutationItem;
  final bool returnPinPayloadWithoutItem;
  final Set<String> conflictFollowTopicIds;
  final List<String> followCalls = <String>[];
  final List<String> unfollowCalls = <String>[];
  final List<String> pinCalls = <String>[];
  final List<String> unpinCalls = <String>[];

  @override
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  }) async {
    const followLimit = 10;
    return UserCapabilitiesDto(
      authenticated: true,
      accountTier: 'free',
      followLimit: followLimit,
      followCount: _items.length,
      remainingFollowQuota: (followLimit - _items.length).clamp(0, followLimit),
    );
  }

  @override
  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  }) async {
    return FollowedTopicListDto(
      items: List<FollowedTopicItemDto>.from(_items),
      generatedAt: DateTime(2026, 4, 18, 9, 0),
    );
  }

  @override
  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  }) async {
    final existingIds = _items.map((item) => item.topicId).toSet();
    final merged = <String>[];
    final alreadyFollowed = <String>[];
    final skipped = <String>[];
    const followLimit = 10;

    for (final topicId in guestTopicIds) {
      if (existingIds.contains(topicId)) {
        alreadyFollowed.add(topicId);
        continue;
      }
      if (_items.length >= followLimit) {
        skipped.add(topicId);
        continue;
      }
      final topic = SampleData.topics.firstWhere((item) => item.id == topicId);
      _items.add(
        FollowedTopicItemDto(
          followId: 'follow_$topicId',
          topicId: topicId,
          title: topic.name,
          summary: topic.tagline,
          isPinned: false,
          followedAt: DateTime(2026, 4, 18, 9, 5),
          latestRelevantEventAt: DateTime(2026, 4, 18, 9, 5),
          latestRelevantEventSummary: '${topic.name} 已加入关注列表',
          hasRecentUpdate: true,
        ),
      );
      existingIds.add(topicId);
      merged.add(topicId);
    }

    return GuestFollowMergeResultDto(
      mergedTopicIds: merged,
      alreadyFollowedTopicIds: alreadyFollowed,
      skippedTopicIds: skipped,
      followCount: _items.length,
      followLimit: followLimit,
      remainingFollowQuota: (followLimit - _items.length).clamp(0, followLimit),
    );
  }

  @override
  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    final capabilities = await fetchCapabilities(userId: userId);
    return GuestTopicClaimResultDto(
      claimedTopicIds: List<String>.from(topicIds),
      alreadyOwnedTopicIds: const <String>[],
      skippedTopicIds: const <String>[],
      followCount: capabilities.followCount ?? _items.length,
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
    followCalls.add(topicId);
    final topic = SampleData.topics.firstWhere((item) => item.id == topicId);
    if (conflictFollowTopicIds.contains(topicId)) {
      if (_items.every((item) => item.topicId != topicId)) {
        _items.add(
          FollowedTopicItemDto(
            followId: 'follow_$topicId',
            topicId: topicId,
            title: topic.name,
            summary: topic.tagline,
            isPinned: false,
            followedAt: DateTime(2026, 4, 18, 9, 5),
            latestRelevantEventAt: DateTime(2026, 4, 18, 9, 5),
            latestRelevantEventSummary: '${topic.name} 已加入关注列表',
            hasRecentUpdate: true,
          ),
        );
      }
      throw Exception('[TOPIC_ALREADY_FOLLOWED] Topic already followed');
    }
    final item = FollowedTopicItemDto(
      followId: 'follow_$topicId',
      topicId: topicId,
      title: topic.name,
      summary: topic.tagline,
      isPinned: false,
      followedAt: DateTime(2026, 4, 18, 9, 5),
      latestRelevantEventAt: DateTime(2026, 4, 18, 9, 5),
      latestRelevantEventSummary: '${topic.name} 已加入关注列表',
      hasRecentUpdate: true,
    );
    _items.add(item);
    return FollowMutationResultDto(
      followed: true,
      topicId: topicId,
      item: returnPartialMutationItem
          ? FollowedTopicItemDto(
              followId: item.followId,
              topicId: item.topicId,
              title: '',
              summary: '',
              isPinned: item.isPinned,
              followedAt: item.followedAt,
              hasRecentUpdate: false,
            )
          : item,
      isPinned: false,
      capabilities: await fetchCapabilities(userId: userId),
    );
  }

  @override
  Future<FollowMutationResultDto> unfollowTopic({
    required String userId,
    required String topicId,
  }) async {
    unfollowCalls.add(topicId);
    _items.removeWhere((item) => item.topicId == topicId);
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
    pinCalls.add(topicId);
    final index = _items.indexWhere((item) => item.topicId == topicId);
    _items[index] = _items[index].copyWith(isPinned: true);
    if (returnPinPayloadWithoutItem) {
      return FollowMutationResultDto(
        followed: true,
        topicId: topicId,
        isPinned: true,
        capabilities: await fetchCapabilities(userId: userId),
      );
    }
    return FollowMutationResultDto(
      followed: true,
      topicId: topicId,
      item: _items[index],
      isPinned: true,
      capabilities: await fetchCapabilities(userId: userId),
    );
  }

  @override
  Future<FollowMutationResultDto> unpinTopic({
    required String userId,
    required String topicId,
  }) async {
    unpinCalls.add(topicId);
    final index = _items.indexWhere((item) => item.topicId == topicId);
    _items[index] = _items[index].copyWith(isPinned: false);
    return FollowMutationResultDto(
      followed: true,
      topicId: topicId,
      item: _items[index],
      isPinned: false,
      capabilities: await fetchCapabilities(userId: userId),
    );
  }
}

class _FailingFollowedTopicRemoteService implements FollowedTopicRemoteService {
  @override
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  }) async {
    throw Exception('remote unavailable');
  }

  @override
  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  }) async {
    throw Exception('remote unavailable');
  }

  @override
  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FollowMutationResultDto> followTopic({
    required String userId,
    required String topicId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FollowMutationResultDto> unfollowTopic({
    required String userId,
    required String topicId,
  }) async {
    throw UnimplementedError();
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
