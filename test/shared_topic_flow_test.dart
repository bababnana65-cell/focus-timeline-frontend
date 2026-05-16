import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:event_timeline/services/topic_share_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  test('pins multiple tracked topics and can unpin individually', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final secondTopic = controller.trackedTopics[1];
    final firstPin = await controller.pinTopic(secondTopic);

    expect(firstPin, isTrue);
    expect(controller.isPinned(secondTopic), isTrue);
    expect(controller.trackedTopics.first.id, secondTopic.id);

    final thirdTopic = controller.recommendedTopics.firstWhere(
      (topic) =>
          controller.trackedTopics.every((tracked) => tracked.id != topic.id),
    );
    await controller.toggleFollow(thirdTopic);

    final secondPin = await controller.pinTopic(thirdTopic);

    expect(secondPin, isTrue);
    expect(controller.isPinned(secondTopic), isTrue);
    expect(controller.isPinned(thirdTopic), isTrue);
    expect(
      controller.trackedTopics.take(2).map((topic) => topic.id),
      orderedEquals(<String>[thirdTopic.id, secondTopic.id]),
    );

    final restoredController = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: AppLocalStorage(),
      creationService: MockTimelineCreationService(),
    );
    await restoredController.initialize();

    expect(restoredController.isPinned(secondTopic), isTrue);
    expect(restoredController.isPinned(thirdTopic), isTrue);
    expect(
      restoredController.trackedTopics.take(2).map((topic) => topic.id),
      orderedEquals(<String>[thirdTopic.id, secondTopic.id]),
    );

    final unpinned = await restoredController.unpinTopic(thirdTopic);

    expect(unpinned, isTrue);
    expect(restoredController.isPinned(thirdTopic), isFalse);
    expect(restoredController.isPinned(secondTopic), isTrue);
    expect(restoredController.trackedTopics.first.id, secondTopic.id);
  });

  test('imports shared custom topic and follows it', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    const topic = Topic(
      id: 'custom-shared-war',
      name: '伊朗 / 美国战事进展追踪',
      tagline: '围绕冲突升级、信号与潜在转折持续整理进展',
      followerCount: 1,
      isHot: false,
    );
    final entries = <TimelineEntry>[
      TimelineEntry(
        id: 'shared-1',
        topicId: topic.id,
        title: '关键节点',
        summary: '外部信号开始明显集中。',
        detail: '关键节点详情。',
        fullText: '关键节点全文。',
        sourceName: '分享导入',
        timestamp: DateTime(2026, 4, 12, 10, 30),
        isMajor: true,
      ),
    ];
    final link = TopicShareService().buildShareLink(
      topic: topic,
      entries: entries,
    );

    await controller.handleIncomingRoute(link);

    expect(controller.pendingSharedTopic?.topic.id, topic.id);
    expect(controller.isFollowing(topic), isFalse);

    await controller.openPendingSharedTopic(follow: true);

    expect(controller.isFollowing(topic), isTrue);
    expect(controller.selectedTopicId, topic.id);
    expect(controller.latestEntryForTopic(topic.id)?.summary,
        entries.single.summary);
  });

  test('restores viewed timeline history for recommendations', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final trackedTopic = controller.trackedTopics.first;
    final recommendedTopic = controller.recommendedTopics.firstWhere(
      (topic) => topic.id != trackedTopic.id,
    );

    await controller.selectTopic(trackedTopic);
    await controller.selectTopic(recommendedTopic);
    controller.showHistoryRecommendations();

    expect(controller.recommendationMode, RecommendationMode.history);
    expect(controller.historyTopics.map((topic) => topic.id),
        contains(recommendedTopic.id));
    expect(controller.historyTopics.map((topic) => topic.id),
        contains(trackedTopic.id));
    expect(controller.recommendationTopics.map((topic) => topic.id),
        contains(recommendedTopic.id));
    expect(controller.recommendationTopics.map((topic) => topic.id),
        contains(trackedTopic.id));

    final restoredController = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: AppLocalStorage(),
      creationService: MockTimelineCreationService(),
    );
    await restoredController.initialize();

    expect(restoredController.historyTopics.map((topic) => topic.id),
        contains(recommendedTopic.id));
    expect(restoredController.historyTopics.map((topic) => topic.id),
        contains(trackedTopic.id));
  });

  test('restores viewed shared topic history after restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    const topic = Topic(
      id: 'custom-history-shared',
      name: '古代帝国更替时间线',
      tagline: '整理关键年代、制度变化与重大转折',
      followerCount: 1,
      isHot: false,
    );
    final entries = <TimelineEntry>[
      TimelineEntry(
        id: 'shared-history-1',
        topicId: topic.id,
        title: '帝国开端',
        summary: '从这一年开始进入长期演进阶段。',
        detail: '历史背景细节。',
        fullText: '历史背景全文。',
        sourceName: '分享导入',
        timestamp: DateTime(26, 4, 12),
        isMajor: true,
      ),
    ];

    final link = TopicShareService().buildShareLink(
      topic: topic,
      entries: entries,
    );

    await controller.handleIncomingRoute(link);
    await controller.openPendingSharedTopic(follow: false);
    controller.showHistoryRecommendations();

    expect(controller.historyTopics.map((item) => item.id), contains(topic.id));
    expect(controller.selectedTopicId, topic.id);

    final restoredController = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: AppLocalStorage(),
      creationService: MockTimelineCreationService(),
    );
    await restoredController.initialize();
    restoredController.showHistoryRecommendations();

    expect(restoredController.historyTopics.map((item) => item.id),
        contains(topic.id));
    expect(restoredController.recommendationTopics.map((item) => item.id),
        contains(topic.id));
    expect(restoredController.selectedTopicId, topic.id);
    expect(
        restoredController.latestEntryForTopic(topic.id)?.timestamp.year, 26);
  });

  test(
      'unfollowing the current timeline keeps it visible and switches back to follow state',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final currentTopic = controller.trackedTopics.first;
    await controller.selectTopic(currentTopic);
    final latestEntry = controller.latestEntryForTopic(currentTopic.id);

    await controller.removeTrackedTopic(currentTopic);

    expect(controller.isFollowing(currentTopic), isFalse);
    expect(controller.selectedTopicId, currentTopic.id);
    expect(controller.selectedTopic?.id, currentTopic.id);
    expect(
        controller.latestEntryForTopic(currentTopic.id)?.id, latestEntry?.id);
    expect(controller.visibleTimelineBuckets, isNotEmpty);
  });

  test('explicitly empty tracked topics stay empty after restart', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final topicsToRemove = controller.trackedTopics.toList();
    for (final topic in topicsToRemove) {
      await controller.removeTrackedTopic(topic);
    }

    expect(controller.trackedTopics, isEmpty);

    final restoredController = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: AppLocalStorage(),
      creationService: MockTimelineCreationService(),
    );
    await restoredController.initialize();

    expect(restoredController.trackedTopics, isEmpty);
  });

  test('logout preserves visible timeline state for same phone re-login',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final draft = await controller.expandTimelineKeywords('伊朗美国战争');
    final createdTopic = await controller.createTimelineFromDraft(draft);
    await controller.selectTopic(createdTopic);

    await controller.sendVerificationCode('13812345678');
    await controller.verifySmsCode(
      rawPhoneNumber: '13812345678',
      smsCode: controller.debugVerificationCode!,
    );

    expect(controller.session, isNotNull);
    expect(controller.trackedTopics, isNotEmpty);
    final visibleTopicIdsAfterLogin =
        controller.trackedTopics.map((topic) => topic.id).toList();
    expect(controller.historyTopicIds, isNotEmpty);

    await controller.logout();

    expect(controller.session, isNull);
    expect(
      controller.trackedTopics.map((topic) => topic.id),
      visibleTopicIdsAfterLogin,
    );
    expect(storage.readSession(), isNull);
    expect(storage.readGuestTrackedTopicIds(), visibleTopicIdsAfterLogin);
    expect(storage.readRetainedCachePolicy()?.phoneNumber, '13812345678');

    await controller.sendVerificationCode('13812345678');
    await controller.verifySmsCode(
      rawPhoneNumber: '13812345678',
      smsCode: controller.debugVerificationCode!,
    );

    expect(controller.session?.phoneNumber, '13812345678');
    expect(
      controller.trackedTopics.map((topic) => topic.id),
      visibleTopicIdsAfterLogin,
    );
    expect(controller.historyTopicIds, isNotEmpty);
    expect(storage.readRetainedCachePolicy(), isNull);
  });

  test('logout clears retained cache policy after a different phone login',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();

    final draft = await controller.expandTimelineKeywords('伊朗美国战争');
    final createdTopic = await controller.createTimelineFromDraft(draft);
    await controller.selectTopic(createdTopic);

    await controller.sendVerificationCode('13812345678');
    await controller.verifySmsCode(
      rawPhoneNumber: '13812345678',
      smsCode: controller.debugVerificationCode!,
    );

    final visibleTopicIdsAfterLogin =
        controller.trackedTopics.map((topic) => topic.id).toList();

    await controller.logout();

    expect(storage.readGuestTrackedTopicIds(), visibleTopicIdsAfterLogin);
    expect(storage.readRetainedCachePolicy()?.phoneNumber, '13812345678');

    await controller.sendVerificationCode('13912345678');
    await controller.verifySmsCode(
      rawPhoneNumber: '13912345678',
      smsCode: controller.debugVerificationCode!,
    );

    expect(controller.session?.phoneNumber, '13912345678');
    expect(controller.pinnedTopicIds, isEmpty);
    expect(storage.readRetainedCachePolicy(), isNull);
  });

  test('major node toggle filters timeline to major entries and toggles back',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(
      AuthSession(
        phoneNumber: '13812345678',
        loggedInAt: DateTime(2026, 4, 13, 9, 0),
      ),
    );

    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();
    await controller.selectTopic(controller.trackedTopics.first);

    final fullBuckets = controller.visibleTimelineBuckets;
    final fullEventCount = fullBuckets.fold<int>(
        0, (count, bucket) => count + bucket.entries.length);

    controller.toggleMajorNodesOnly();

    final majorOnlyBuckets = controller.visibleTimelineBuckets;
    final majorOnlyEventCount = majorOnlyBuckets.fold<int>(
        0, (count, bucket) => count + bucket.entries.length);

    expect(controller.showOnlyMajorNodes, isTrue);
    expect(majorOnlyBuckets, isNotEmpty);
    expect(
      majorOnlyBuckets.every(
        (bucket) => bucket.entries.every((entry) => entry.isMajor),
      ),
      isTrue,
    );
    expect(majorOnlyEventCount, lessThan(fullEventCount));

    controller.toggleMajorNodesOnly();

    final restoredBuckets = controller.visibleTimelineBuckets;
    final restoredEventCount = restoredBuckets.fold<int>(
        0, (count, bucket) => count + bucket.entries.length);

    expect(controller.showOnlyMajorNodes, isFalse);
    expect(restoredEventCount, fullEventCount);
    expect(restoredBuckets.length, fullBuckets.length);
  });
}
