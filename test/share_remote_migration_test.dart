import 'package:event_timeline/dto/share_dto.dart';
import 'package:event_timeline/dto/followed_topic_dto.dart';
import 'package:event_timeline/dto/topic_timeline_dto.dart';
import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/followed_topic_remote_service.dart';
import 'package:event_timeline/services/remote/share_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
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

  test('buildShareMessage uses remote share token flow for server managed topics', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());
    final shareRemote = _InMemoryShareRemoteService();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      shareRemoteService: shareRemote,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final message = await controller.buildShareMessage(controller.trackedTopics.first);

    expect(shareRemote.createCalls, <String>[controller.trackedTopics.first.id]);
    expect(message, contains('https://example.com/share/share_${controller.trackedTopics.first.id}'));
  });

  test('handleIncomingRoute resolves share token through remote service', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());
    final shareRemote = _InMemoryShareRemoteService();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      shareRemoteService: shareRemote,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    await controller.handleIncomingRoute('https://example.com/share/share_${SampleData.aiTopic.id}');

    expect(shareRemote.resolveCalls, <String>['share_${SampleData.aiTopic.id}']);
    expect(controller.pendingSharedTopic?.topic.id, SampleData.aiTopic.id);
    expect(controller.pendingSharedTopic?.allowFollow, isTrue);
  });

  test('openPendingSharedTopic with follow uses followed-topic remote service for server managed topics', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());
    final shareRemote = _InMemoryShareRemoteService();
    final followedRemote = _FollowFromShareRemoteService();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      shareRemoteService: shareRemote,
      followedTopicRemoteService: followedRemote,
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final topicToShare = controller.recommendedTopics.firstWhere(
      (topic) => !controller.isFollowing(topic),
    );

    await controller.handleIncomingRoute('https://example.com/share/share_${topicToShare.id}');
    await controller.openPendingSharedTopic(follow: true);

    expect(followedRemote.followCalls, <String>[topicToShare.id]);
    expect(controller.isFollowing(topicToShare), isTrue);
    expect(controller.selectedTopicId, topicToShare.id);
  });

  test('buildShareMessage no longer falls back to local payload for server managed topics', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(buildSession());

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      shareRemoteService: _FailingShareRemoteService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    await expectLater(
      controller.buildShareMessage(controller.trackedTopics.first),
      throwsException,
    );
  });
}

class _FollowFromShareRemoteService implements FollowedTopicRemoteService {
  final List<String> followCalls = <String>[];

  @override
  Future<UserCapabilitiesDto> fetchCapabilities({
    String? userId,
  }) async {
    return const UserCapabilitiesDto(
      authenticated: true,
      accountTier: 'free',
      followLimit: 10,
      followCount: 1,
      remainingFollowQuota: 9,
    );
  }

  @override
  Future<FollowedTopicListDto> fetchFollowedTopics({
    required String userId,
  }) async {
    return const FollowedTopicListDto(items: <FollowedTopicItemDto>[]);
  }

  @override
  Future<GuestFollowMergeResultDto> mergeGuestFollows({
    required String userId,
    required List<String> guestTopicIds,
  }) async {
    return const GuestFollowMergeResultDto(
      mergedTopicIds: <String>[],
      alreadyFollowedTopicIds: <String>[],
      skippedTopicIds: <String>[],
      followCount: 1,
      followLimit: 10,
      remainingFollowQuota: 9,
    );
  }

  @override
  Future<GuestTopicClaimResultDto> claimGuestTopics({
    required String userId,
    required List<String> topicIds,
  }) async {
    return const GuestTopicClaimResultDto(
      claimedTopicIds: <String>[],
      alreadyOwnedTopicIds: <String>[],
      skippedTopicIds: <String>[],
      followCount: 1,
      followLimit: 10,
      remainingFollowQuota: 9,
    );
  }

  @override
  Future<FollowMutationResultDto> followTopic({
    required String userId,
    required String topicId,
  }) async {
    followCalls.add(topicId);
    final topic = SampleData.topics.firstWhere((item) => item.id == topicId);
    return FollowMutationResultDto(
      followed: true,
      topicId: topicId,
      item: FollowedTopicItemDto(
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
      isPinned: false,
      capabilities: const UserCapabilitiesDto(
        authenticated: true,
        accountTier: 'free',
        followLimit: 10,
        followCount: 2,
        remainingFollowQuota: 8,
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
  Future<FollowMutationResultDto> unfollowTopic({
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

class _InMemoryShareRemoteService implements ShareRemoteService {
  final List<String> createCalls = <String>[];
  final List<String> resolveCalls = <String>[];

  @override
  Future<ShareCreateResultDto> createShare({
    required String topicId,
  }) async {
    createCalls.add(topicId);
    return ShareCreateResultDto(
      shareToken: 'share_$topicId',
      shareUrl: 'https://example.com/share/share_$topicId',
      shareType: 'topic',
      allowFollow: true,
      expiresAt: DateTime(2026, 5, 18, 9, 0),
    );
  }

  @override
  Future<ShareResolveDto> resolveShare(String shareToken) async {
    resolveCalls.add(shareToken);
    final topicId = shareToken.replaceFirst('share_', '');
    return ShareResolveDto(
      shareToken: shareToken,
      shareType: 'topic',
      allowFollow: true,
      expiresAt: DateTime(2026, 5, 18, 9, 0),
      alreadyFollowed: false,
      topic: TopicDetailDto(
        topicId: topicId,
        title: SampleData.aiTopic.name,
        summary: SampleData.aiTopic.tagline,
        isFollowed: false,
      ),
      preview: SharePreviewDto(
        latestEventAt: DateTime(2026, 4, 18, 8, 0),
        majorCount: 3,
      ),
    );
  }
}

class _FailingShareRemoteService implements ShareRemoteService {
  @override
  Future<ShareCreateResultDto> createShare({
    required String topicId,
  }) async {
    throw Exception('share api down');
  }

  @override
  Future<ShareResolveDto> resolveShare(String shareToken) async {
    throw Exception('share api down');
  }
}
