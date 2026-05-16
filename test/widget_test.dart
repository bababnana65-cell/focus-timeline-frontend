import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:event_timeline/app.dart';
import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/models/timeline_creation_models.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/screens/home_shell.dart';
import 'package:event_timeline/screens/tracked_topics_screen.dart';
import 'package:event_timeline/screens/timeline_screen.dart';
import 'package:event_timeline/screens/registration_gate_screen.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/topic_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:event_timeline/theme/app_theme.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  testWidgets('renders home shell with four mobile tabs for guests',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    expect(find.text('首页'), findsOneWidget);
    expect(find.text('时间轴'), findsOneWidget);
    expect(find.text('创建'), findsOneWidget);
    expect(find.text('未登录'), findsOneWidget);
    expect(find.text('我的关注'), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsWidgets);
  });

  testWidgets('guest profile tab opens phone login screen', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    await tester.tap(find.text('未登录'));
    await tester.pumpAndSettle();

    expect(find.text('手机号验证'), findsOneWidget);
  });

  testWidgets('quota login prompt omits duplicated quota comparison',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    addTearDown(controller.dispose);

    await tester.runAsync(() async {
      await controller.initialize();
      controller.showHotRecommendations();
      final topics = controller.recommendationTopics
          .take(TimelineController.guestFollowLimit + 1)
          .toList();
      for (final topic in topics.take(TimelineController.guestFollowLimit)) {
        await controller.toggleFollow(topic);
      }
      await controller.toggleFollow(topics.last);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomeShell(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('登录后继续关注'), findsOneWidget);
    expect(find.text('手机号验证'), findsOneWidget);
    expect(find.text('游客关注额度'), findsNothing);
    expect(find.text('登录免费额度'), findsNothing);
  });

  testWidgets('new tab opens create timeline flow', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    expect(find.text('创建时间轴'), findsOneWidget);
    expect(find.text('AI 扩写'), findsOneWidget);
    expect(find.text('确定'), findsNothing);
    expect(find.text('重写'), findsNothing);
    expect(find.text('建立时间线'), findsNothing);
    expect(find.text('例如：AI 大模型发布'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('create-timeline-quote')),
        findsOneWidget);

    final expandButton = find.widgetWithText(FilledButton, 'AI 扩写');
    final expandStyle = tester.widget<FilledButton>(expandButton).style;
    expect(expandStyle?.minimumSize?.resolve(<WidgetState>{})?.height, 48);
  });

  testWidgets('candidate selection creates directly without confirm page',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '美伊冲突');
    final quoteBefore = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('create-timeline-quote')))
        .data;
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final quoteAfter = tester
        .widget<Text>(
            find.byKey(const ValueKey<String>('create-timeline-quote')))
        .data;
    expect(quoteAfter, isNot(quoteBefore));
    expect(find.text('AI 再次扩写'), findsOneWidget);
    expect(find.text('AI 建议追踪方向'), findsOneWidget);
    expect(find.text('确定'), findsNothing);
    await tester.ensureVisible(find.text('美伊冲突近期关键进展时间线'));
    await tester.tap(find.text('美伊冲突近期关键进展时间线'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('创建时间轴'), findsNothing);
    expect(find.text('AI 建议追踪方向'), findsNothing);
  });

  testWidgets('candidate cards keep inferred category without edit step',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '贵州村超 融资');
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('AI 建议追踪方向'), findsOneWidget);
    expect(find.text('贵州村超融资近期关键进展时间线'), findsOneWidget);
    expect(find.text('金融'), findsWidgets);
    expect(find.text('核心关键词'), findsNothing);
    expect(find.text('已纳入扩展关键词'), findsNothing);
    expect(find.text('已排除关键词'), findsNothing);
  });

  testWidgets(
      'create sheet no longer exposes keyword edit buckets after candidates',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'spacex 发展');
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('AI 建议追踪方向'), findsOneWidget);
    expect(find.text('spacex发展近期关键进展时间线'), findsOneWidget);
    expect(find.text('核心关键词'), findsNothing);
    expect(find.text('已纳入扩展关键词'), findsNothing);
    expect(find.text('已排除关键词'), findsNothing);
    expect(find.text('官方回应'), findsNothing);
  });

  testWidgets('changing input keywords resets previous candidate directions',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const EventTimelineRoot());
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建'));
    await tester.pumpAndSettle();

    final input = find.byType(TextField).last;
    await tester.enterText(input, 'ai算力');
    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('AI 建议追踪方向'), findsOneWidget);
    expect(find.text('ai算力近期关键进展时间线'), findsOneWidget);

    await tester.enterText(input, '贵州村超');
    await tester.pump();

    expect(find.text('AI 建议追踪方向'), findsNothing);
    expect(find.text('ai算力近期关键进展时间线'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'AI 扩写'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('贵州村超近期关键进展时间线'), findsOneWidget);
    expect(find.text('ai算力近期关键进展时间线'), findsNothing);
  });

  testWidgets('keeps manual phone edits when pending phone has not changed',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    controller.pendingPhoneNumber = '13312341234';

    await tester.pumpWidget(
      MaterialApp(
        home: RegistrationGateScreen(controller: controller),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '13800138000');
    controller.errorMessage = '登录失败';
    controller.notifyListeners();
    await tester.pump();

    expect(find.text('13800138000'), findsOneWidget);
  });

  testWidgets('timeline start summary is exposed as a jump control',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          controller: controller,
          onSwipeBack: () async {},
          onSwipeForward: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey<String>('timeline-jump-to-start')),
      findsOneWidget,
    );
  });

  testWidgets('timeline latest summary is exposed as a latest jump control',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          controller: controller,
          onSwipeBack: () async {},
          onSwipeForward: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey<String>('timeline-jump-to-latest')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('timeline-jump-to-latest')),
        matching: find.text('最新更新'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('timeline-toggle-favorites')),
        matching: find.text('收藏节点'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('pending server timeline waits with automatic refresh language',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final repository = MockTimelineRepository();
    final controller = TimelineController(
      repository: repository,
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
      topicRemoteService: MockTopicRemoteService(repository: repository),
    );
    await tester.runAsync(controller.initialize);

    await tester.runAsync(() {
      return controller.createTimelineFromDirection(
        keywords: '霍尔木兹海峡封锁',
        candidate: const TimelineDirectionCandidate(
          candidateId: 'candidate_recent',
          title: '霍尔木兹海峡封锁关键进展时间线',
          trackingDirection: '追踪封锁传闻、官方回应、航运影响和后续处置。',
          trackingQuestion: '霍尔木兹海峡封锁是否发生，影响如何变化？',
          topicObject: '霍尔木兹海峡封锁',
          topicScope: '纳入官方表态、航运影响和后续处置。',
          timelineType: 'single_event_lifecycle',
          timelineTypeConfidence: 'high',
          categoryId: 'global_affairs',
          primaryCategory: '国际',
          recentActivityStatus: 'active',
          trackingViability: 'high',
          recentEvidenceCount: 2,
          reason: '近期有多个相关来源。',
          isRecommended: true,
        ),
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          controller: controller,
          onSwipeBack: () async {},
          onSwipeForward: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('正在准备中'), findsOneWidget);
    expect(find.textContaining('自动刷新到可阅读状态'), findsOneWidget);
    expect(find.textContaining('下拉刷新'), findsNothing);
    final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator).first);
    expect(progress.value, isNull);
  });

  testWidgets('timeline header shows current topic follow status',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    await tester.runAsync(() async {
      await controller.initialize();
      await controller.toggleFollow(SampleData.aiTopic);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          controller: controller,
          onSwipeBack: () async {},
          onSwipeForward: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey<String>('timeline-topic-follow-status')),
      findsOneWidget,
    );
    expect(find.text('已关注'), findsOneWidget);
  });

  testWidgets('timeline search is moved into overflow menu', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          controller: controller,
          onSwipeBack: () async {},
          onSwipeForward: () async {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byIcon(Icons.search_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    expect(find.text('搜索时间线节点'), findsOneWidget);
    expect(find.text('创建时间轴'), findsNothing);
  });

  testWidgets('timeline horizontal drag does not switch tabs', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    var swipeBackCount = 0;
    var swipeForwardCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: TimelineScreen(
          controller: controller,
          onSwipeBack: () async {
            swipeBackCount += 1;
          },
          onSwipeForward: () async {
            swipeForwardCount += 1;
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    await tester.drag(find.byType(TimelineScreen), const Offset(420, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(TimelineScreen), const Offset(-420, 0));
    await tester.pumpAndSettle();

    expect(swipeBackCount, 0);
    expect(swipeForwardCount, 0);
  });

  testWidgets('tracked topics feed owns slidable auto-close behavior',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    await tester.runAsync(() async {
      await controller.toggleFollow(SampleData.aiTopic);
      await controller.toggleFollow(SampleData.moonTopic);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TrackedTopicsFeed(
            controller: controller,
            onOpenTopic: (_) async {},
            onShareTopic: (_) async {},
            onTogglePinTopic: (_) async {},
            onUnfollowTopic: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SlidableAutoCloseBehavior), findsOneWidget);
    expect(find.byType(Slidable), findsWidgets);
  });

  testWidgets('tracked topic cards split cross-year node dates',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final now = DateTime.now();
    final crossYearTimestamp = DateTime(now.year - 1, 9, 3, 12);
    final repository = _SingleTopicRepository(
      topic: _crossYearTopic,
      latestTimestamp: crossYearTimestamp,
    );
    final controller = TimelineController(
      repository: repository,
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    addTearDown(controller.dispose);

    await tester.runAsync(() async {
      await controller.toggleFollow(_crossYearTopic);
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: TrackedTopicsFeed(
            controller: controller,
            onOpenTopic: (_) async {},
            onShareTopic: (_) async {},
            onTogglePinTopic: (_) async {},
            onUnfollowTopic: (_) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('${crossYearTimestamp.year}年\n9月3日'), findsOneWidget);
    expect(find.text('${crossYearTimestamp.year}年9月3日'), findsNothing);
  });

  testWidgets('home tab restores the last selected section after timeline',
      (tester) async {
    final controller = await _buildRegisteredController(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomeShell(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('热门'));
    await tester.pumpAndSettle();

    final topic = controller.recommendationTopics.first;
    final hotCardKey = ValueKey<String>('recommend-hot-${topic.id}');
    expect(find.byKey(hotCardKey), findsOneWidget);

    await tester.tap(find.byKey(hotCardKey));
    await tester.pumpAndSettle();
    expect(find.byType(TimelineScreen), findsOneWidget);

    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();

    expect(find.byKey(hotCardKey), findsOneWidget);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('首页'));
    await tester.pumpAndSettle();

    expect(find.byKey(hotCardKey), findsOneWidget);
  });

  testWidgets('home section switch keeps first card below pinned tabs',
      (tester) async {
    final controller = await _buildRegisteredController(tester);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: HomeShell(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(NestedScrollView), const Offset(0, -140));
    await tester.pumpAndSettle();
    await tester.tap(find.text('热门'));
    await tester.pumpAndSettle();

    final topic = controller.recommendationTopics.first;
    final hotCardKey = ValueKey<String>('recommend-hot-${topic.id}');
    final tabsBottom = tester.getBottomLeft(find.text('热门')).dy;
    final firstCardTop = tester.getTopLeft(find.byKey(hotCardKey)).dy;

    expect(firstCardTop, greaterThanOrEqualTo(tabsBottom + 14));
  });
}

Future<TimelineController> _buildRegisteredController(
  WidgetTester tester,
) async {
  return (await tester.runAsync(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final localStorage = AppLocalStorage();
    await localStorage.init();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: localStorage,
      creationService: MockTimelineCreationService(),
    );
    await controller.initialize();
    controller.session = AuthSession(
      userId: 'user_13812345678',
      sessionToken: 'sess_home',
      issuedAt: DateTime(2026, 5, 1, 9),
      expiresAt: DateTime(2026, 5, 8, 9),
      identityType: 'phone',
      provider: 'sms',
      primaryPhone: '13812345678',
    );
    controller.notifyListeners();
    return controller;
  }))!;
}

const Topic _crossYearTopic = Topic(
  id: 'cross-year-topic',
  name: '跨年日期测试专题',
  tagline: '验证首页卡片窄日期槽显示',
  followerCount: 1,
  isHot: true,
);

class _SingleTopicRepository implements TimelineRepository {
  const _SingleTopicRepository({
    required this.topic,
    required this.latestTimestamp,
  });

  final Topic topic;
  final DateTime latestTimestamp;

  @override
  Future<List<Topic>> fetchTrackedTopics() async => <Topic>[topic];

  @override
  Future<List<Topic>> fetchRecommendedTopics() async => <Topic>[topic];

  @override
  Future<List<TimelineEntry>> fetchTimeline(String topicId) async {
    if (topicId != topic.id) {
      return const <TimelineEntry>[];
    }
    return <TimelineEntry>[
      TimelineEntry(
        id: 'cross-year-entry',
        topicId: topic.id,
        title: '跨年节点',
        summary: '跨年日期节点摘要',
        detail: '跨年日期节点详情',
        fullText: '跨年日期节点全文',
        sourceName: '测试来源',
        timestamp: latestTimestamp,
        isMajor: true,
      ),
    ];
  }
}
