import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/screens/home_shell.dart';
import 'package:event_timeline/screens/profile_screen.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/profile_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:event_timeline/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  testWidgets('profile following action opens compact followed list',
      (tester) async {
    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-following')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('关注列表'), findsOneWidget);
    expect(find.text('关注额度'), findsOneWidget);
    expect(find.text('2 / 10'), findsOneWidget);
    expect(find.text(controller.trackedTopics.first.name), findsOneWidget);
    expect(find.byTooltip('取消关注'), findsWidgets);
  });

  testWidgets('profile history action opens compact history list',
      (tester) async {
    final controller = await _buildRegisteredController(
      tester,
      historyTopicIds: <String>['moon-mission'],
    );

    await _pumpProfile(tester, controller);

    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-history')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('历史列表'), findsOneWidget);
    expect(find.text('载人登月计划'), findsOneWidget);
    expect(find.byTooltip('取消关注'), findsNothing);
  });

  testWidgets('followed list confirms before unfollowing', (tester) async {
    final controller = await _buildRegisteredController(tester);
    final topic = controller.trackedTopics.first;

    await _pumpProfile(tester, controller);

    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-following')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(
        find.byKey(ValueKey<String>('profile-topic-unfollow-${topic.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('确认取消关注'), findsOneWidget);
    expect(controller.isFollowing(topic), isTrue);

    await tester.tap(find.text('取消关注'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(controller.isFollowing(topic), isFalse);
  });

  testWidgets('profile topic title opens timeline in current page stack',
      (tester) async {
    final controller = await _buildRegisteredController(tester);
    final topic = controller.trackedTopics.first;

    await _pumpProfile(tester, controller);

    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-following')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester
        .tap(find.byKey(ValueKey<String>('profile-topic-open-${topic.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text(topic.name), findsWidgets);
    expect(find.byTooltip('返回'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('关注列表'), findsOneWidget);
  });

  testWidgets('profile list back stack returns to profile tab after timeline',
      (tester) async {
    final controller = await _buildRegisteredController(tester);
    final topic = controller.trackedTopics.first;

    await _pumpHomeShell(tester, controller);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-following')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(ValueKey<String>('profile-topic-open-${topic.id}')));
    await tester.pumpAndSettle();

    expect(controller.openTopicRequestToken, 0);
    expect(find.byTooltip('返回'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('关注列表'), findsOneWidget);
    expect(tester.getTopLeft(find.text('关注列表')).dx, greaterThanOrEqualTo(0));

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('profile-action-following')),
        findsOneWidget);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets(
      'profile history back stack returns to profile tab after timeline',
      (tester) async {
    final controller = await _buildRegisteredController(
      tester,
      historyTopicIds: <String>['moon-mission'],
    );
    final topic = controller.historyTopics.first;

    await _pumpHomeShell(tester, controller);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-history')));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(ValueKey<String>('profile-topic-open-${topic.id}')));
    await tester.pumpAndSettle();

    expect(controller.openTopicRequestToken, 0);
    expect(find.byTooltip('返回'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('历史列表'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('profile-action-history')),
        findsOneWidget);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets(
      'profile favorites back stack returns to profile tab after timeline',
      (tester) async {
    final controller = await _buildRegisteredController(tester);
    final topic = controller.trackedTopics.first;
    await tester.runAsync(() async {
      await controller.selectTopic(topic, trackHistory: false);
      await controller.toggleFavoriteTimelineNode(
        topic: topic,
        bucket: controller.timelineBuckets.first,
      );
    });

    await _pumpHomeShell(tester, controller);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-favorites')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(topic.name).last);
    await tester.pumpAndSettle();

    expect(controller.openTopicRequestToken, 0);
    expect(find.byTooltip('返回'), findsOneWidget);

    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('收藏节点'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('profile-action-favorites')),
        findsOneWidget);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('profile action grid groups management and settings actions',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 858));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_ProfileQuickStats',
      ),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == '_MembershipCard',
      ),
      findsNothing,
    );
    expect(find.textContaining('当前关注额度'), findsNothing);
    expect(find.text('内容管理'), findsOneWidget);
    expect(find.text('偏好设置'), findsOneWidget);

    final following = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-following')),
    );
    final favorite = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-favorites')),
    );
    final history = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-history')),
    );
    final share = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-share-records')),
    );
    final reminder = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-reminder-settings')),
    );
    final interests = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-interests')),
    );
    final feedback = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-feedback')),
    );
    final membership = tester.getTopLeft(
      find.byKey(const ValueKey<String>('profile-action-membership')),
    );

    for (final contentAction in <Offset>[
      following,
      favorite,
      history,
      share,
    ]) {
      expect(contentAction.dy, lessThan(reminder.dy));
    }
    expect(reminder.dy, interests.dy);
    expect(feedback.dy, membership.dy);
    expect(reminder.dx, lessThan(interests.dx));
    expect(feedback.dx, lessThan(membership.dx));

    final shareBottom = tester
        .getBottomLeft(
          find.byKey(const ValueKey<String>('profile-action-share-records')),
        )
        .dy;
    final contentSection = find
        .byKey(const ValueKey<String>('profile-section-content-management'));
    expect(contentSection, findsOneWidget);
    final contentBottom = tester.getBottomLeft(contentSection).dy;
    final preferenceTop = tester.getTopLeft(find.text('偏好设置')).dy;
    expect(contentBottom - shareBottom, lessThan(30));
    expect(preferenceTop - shareBottom, lessThan(42));
  });

  testWidgets('profile reminder action detail follows selected mode',
      (tester) async {
    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    final reminderAction =
        find.byKey(const ValueKey<String>('profile-action-reminder-settings'));
    expect(
      find.descendant(of: reminderAction, matching: find.text('重大节点')),
      findsOneWidget,
    );

    controller.setRecentUpdateReminderMode(RecentUpdateReminderMode.all);
    await tester.pump();

    expect(
      find.descendant(of: reminderAction, matching: find.text('全部进展')),
      findsOneWidget,
    );

    controller.setRecentUpdateReminderMode(RecentUpdateReminderMode.off);
    await tester.pump();

    expect(
      find.descendant(of: reminderAction, matching: find.text('已关闭')),
      findsOneWidget,
    );
  });

  testWidgets('profile reminder settings action opens settings page',
      (tester) async {
    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    await _tapProfileAction(tester, 'profile-action-reminder-settings');

    expect(find.text('提醒设置'), findsOneWidget);
    expect(find.text('重大节点提醒'), findsOneWidget);
    expect(find.text('全部新进展提醒'), findsOneWidget);
    expect(find.text('新进展红点'), findsNothing);
    expect(find.text('红点提醒'), findsNothing);
    expect(find.text('专题提醒'), findsNothing);
    expect(find.text('跟随全局'), findsNothing);
    expect(find.text('未读'), findsNothing);

    await tester.tap(find.text('关闭'));
    await tester.pump();

    expect(
      controller.recentUpdateReminderMode,
      RecentUpdateReminderMode.off,
    );
  });

  testWidgets('profile share records action opens empty management page',
      (tester) async {
    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-action-share-records')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('分享记录'), findsOneWidget);
    expect(find.text('暂无分享记录'), findsOneWidget);
  });

  testWidgets('profile membership action opens capability overview',
      (tester) async {
    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    await _tapProfileAction(tester, 'profile-action-membership');

    expect(find.text('会员权益'), findsOneWidget);
    expect(find.text('当前版本'), findsOneWidget);
    expect(find.text('免费版'), findsOneWidget);
    expect(find.text('关注额度'), findsOneWidget);
    expect(find.text('2 / 10'), findsOneWidget);
    expect(find.text('升级 Pro'), findsOneWidget);

    await tester.tap(find.text('升级 Pro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('支付暂未接入'), findsOneWidget);
  });

  testWidgets('profile interests can be selected and saved', (tester) async {
    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    await _tapProfileAction(tester, 'profile-action-interests');

    expect(find.text('兴趣类别'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('profile-interest-politics')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('profile-interest-military')),
    );
    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
        controller.userInterestCategoryIds,
        containsAll(<String>[
          'politics',
          'military',
        ]));
    expect(find.text('兴趣已保存'), findsOneWidget);
  });

  testWidgets('profile feedback can be submitted', (tester) async {
    final controller = await _buildRegisteredController(tester);

    await _pumpProfile(tester, controller);

    await _tapProfileAction(tester, 'profile-action-feedback');

    expect(find.text('问题和建议'), findsOneWidget);
    expect(find.text('我的反馈记录'), findsOneWidget);
    expect(find.text('暂无反馈记录'), findsOneWidget);
    expect(find.text('处理中'), findsNothing);
    expect(find.text('已处理'), findsNothing);
    expect(find.text('已收到'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey<String>('profile-feedback-input')),
      '时间轴节点摘要希望再简洁一些',
    );
    await tester.tap(find.text('提交'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('反馈已提交'), findsOneWidget);
  });

  testWidgets('favorite nodes screen exposes management controls',
      (tester) async {
    final controller = await _buildRegisteredController(tester);
    final topic = controller.trackedTopics.first;
    await tester.runAsync(() async {
      await controller.selectTopic(topic, trackHistory: false);
      await controller.toggleFavoriteTimelineNode(
        topic: topic,
        bucket: controller.timelineBuckets.first,
      );
    });

    await _pumpProfile(tester, controller);

    await tester
        .tap(find.byKey(const ValueKey<String>('profile-action-favorites')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('收藏管理'), findsOneWidget);
    expect(find.text('全部专题'), findsOneWidget);
    expect(find.text('最新收藏优先'), findsOneWidget);
  });

  testWidgets('registered profile loads remote interest preferences',
      (tester) async {
    final profileRemoteService = _SeededProfileRemoteService(
      <String>['politics', 'military', 'history'],
    );
    final controller = await _buildRegisteredController(
      tester,
      profileRemoteService: profileRemoteService,
      skipSeedFollows: true,
    );

    await tester.runAsync(() async {
      await controller.loadInitialData(force: true);
    });

    expect(profileRemoteService.fetchCount, 1);
    expect(controller.userInterestCategoryIds, <String>[
      'politics',
      'military',
      'history',
    ]);
  });
}

Future<TimelineController> _buildRegisteredController(
  WidgetTester tester, {
  List<String> historyTopicIds = const <String>[],
  ProfileRemoteService? profileRemoteService,
  bool skipSeedFollows = false,
}) async {
  return (await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      profileRemoteService: profileRemoteService,
    );
    controller.session = _session();
    if (!skipSeedFollows) {
      await controller.toggleFollow(SampleData.aiTopic);
      await controller.toggleFollow(SampleData.moonTopic);
    }
    for (final topicId in historyTopicIds) {
      await controller.openTopicById(
        topicId,
        requestShellNavigation: false,
      );
    }
    return controller;
  }))!;
}

Future<void> _pumpProfile(
  WidgetTester tester,
  TimelineController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: ProfileScreen(
          controller: controller,
          onOpenLogin: () {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _tapProfileAction(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey<String>(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Future<void> _pumpHomeShell(
  WidgetTester tester,
  TimelineController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => HomeShell(controller: controller),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

AuthSession _session() {
  return AuthSession(
    userId: 'user_13812345678',
    sessionToken: 'sess_profile',
    issuedAt: DateTime(2026, 5, 1, 9),
    expiresAt: DateTime(2026, 5, 8, 9),
    identityType: 'phone',
    provider: 'sms',
    primaryPhone: '13812345678',
  );
}

class _SeededProfileRemoteService implements ProfileRemoteService {
  _SeededProfileRemoteService(this._categoryIds);

  final List<String> _categoryIds;
  int fetchCount = 0;

  @override
  Future<List<String>> fetchInterestCategoryIds() async {
    fetchCount += 1;
    return List<String>.from(_categoryIds);
  }

  @override
  Future<List<String>> saveInterestCategoryIds(List<String> categoryIds) async {
    _categoryIds
      ..clear()
      ..addAll(categoryIds);
    return List<String>.from(_categoryIds);
  }

  @override
  Future<void> submitFeedback({
    required String message,
    String category = 'suggestion',
  }) async {}
}
