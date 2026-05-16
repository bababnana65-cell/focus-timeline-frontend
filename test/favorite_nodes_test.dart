import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:event_timeline/dto/favorite_timeline_bucket_dto.dart';
import 'package:event_timeline/models/auth_models.dart';
import 'package:event_timeline/models/timeline_models.dart';
import 'package:event_timeline/screens/profile_screen.dart';
import 'package:event_timeline/services/app_local_storage.dart';
import 'package:event_timeline/services/mock_timeline_repository.dart';
import 'package:event_timeline/services/phone_auth_service.dart';
import 'package:event_timeline/services/remote/favorite_timeline_bucket_remote_service.dart';
import 'package:event_timeline/services/timeline_controller.dart';
import 'package:event_timeline/services/timeline_creation_service.dart';
import 'package:event_timeline/widgets/timeline_bucket_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  TimelineController buildController(
    AppLocalStorage storage, {
    FavoriteTimelineBucketRemoteService? favoriteRemoteService,
  }) {
    return TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      favoriteTimelineBucketRemoteService: favoriteRemoteService,
    );
  }

  test('favorite timeline nodes are persisted locally', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final controller = buildController(storage);
    await controller.initialize();

    final topic = controller.recommendationTopics.first;
    await controller.selectTopic(topic);
    final bucket = controller.timelineBuckets.first;

    final favorited = await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: bucket,
    );

    expect(favorited, isTrue);
    expect(controller.favoriteTimelineNodes, hasLength(1));
    expect(controller.isFavoriteTimelineNode(topic: topic, bucket: bucket),
        isTrue);

    final restoredStorage = AppLocalStorage();
    await restoredStorage.init();
    final restoredController = buildController(restoredStorage);
    await restoredController.initialize();

    expect(restoredController.favoriteTimelineNodes, hasLength(1));
    expect(restoredController.favoriteTimelineNodes.first.topicName,
        equals(topic.name));
  });

  test('bucket favorite survives later coarser timeline grouping', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final controller = buildController(storage);
    await controller.initialize();

    const topic = Topic(
      id: 'topic-bucket',
      name: '大运河历史保护与数字档案时间线',
      tagline: '追踪历史保护与数字档案开放',
      followerCount: 0,
      isHot: false,
    );
    final dayBucket = _bucket(
      id: '2026-05-03',
      start: DateTime(2026, 5, 3),
      granularity: TimelineGranularity.day,
      label: '5月3日',
    );
    final monthBucket = _bucket(
      id: '2026-05',
      start: DateTime(2026, 5),
      granularity: TimelineGranularity.month,
      label: '2026年5月',
    );

    await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: dayBucket,
    );

    expect(
      controller.favoriteTimelineNodes.single.bucketGranularity,
      TimelineGranularity.day,
    );
    expect(
      controller.isFavoriteTimelineNode(topic: topic, bucket: monthBucket),
      isTrue,
    );

    final restoredStorage = AppLocalStorage();
    await restoredStorage.init();
    final restoredController = buildController(restoredStorage);
    await restoredController.initialize();

    expect(
      restoredController.isFavoriteTimelineNode(
        topic: topic,
        bucket: monthBucket,
      ),
      isTrue,
    );
  });

  test('toggling a coarser favorite bucket removes contained favorites',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final controller = buildController(storage);
    await controller.initialize();

    const topic = Topic(
      id: 'topic-bucket',
      name: '大运河历史保护与数字档案时间线',
      tagline: '追踪历史保护与数字档案开放',
      followerCount: 0,
      isHot: false,
    );
    final dayBucket = _bucket(
      id: '2026-05-03',
      start: DateTime(2026, 5, 3),
      granularity: TimelineGranularity.day,
      label: '5月3日',
    );
    final monthBucket = _bucket(
      id: '2026-05',
      start: DateTime(2026, 5),
      granularity: TimelineGranularity.month,
      label: '2026年5月',
    );

    await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: dayBucket,
    );
    final favorited = await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: monthBucket,
    );

    expect(favorited, isFalse);
    expect(controller.favoriteTimelineNodes, isEmpty);
    expect(
      controller.isFavoriteTimelineNode(topic: topic, bucket: monthBucket),
      isFalse,
    );
  });

  test('favorite-only timeline filter shows only favorited buckets', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final controller = buildController(storage);
    await controller.initialize();

    final topic = controller.recommendationTopics.first;
    await controller.selectTopic(topic);
    final allBuckets =
        List<TimelineBucket>.from(controller.visibleTimelineBuckets);
    expect(allBuckets.length, greaterThan(1));

    await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: allBuckets[1],
    );

    final dynamic dynamicController = controller;
    dynamicController.toggleFavoriteNodesOnly();

    expect(controller.visibleTimelineBuckets, hasLength(1));
    expect(controller.visibleTimelineBuckets.single.id, allBuckets[1].id);
  });

  test('favorite bucket DTO fallback headline uses node wording', () {
    final dto = FavoriteTimelineBucketDto.fromJson(<String, dynamic>{
      'topicId': 'topic-1',
      'bucketStart': '2026-04-28T00:00:00.000',
      'bucketGranularity': 'day',
    });

    expect(dto.headline, '收藏节点');
  });

  test('registered users toggle bucket favorites through remote service',
      () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    await storage.saveSession(_session());
    final remote = _FakeFavoriteTimelineBucketRemoteService();
    final controller = TimelineController(
      repository: MockTimelineRepository(),
      authService: MockPhoneAuthService(),
      localStorage: storage,
      creationService: MockTimelineCreationService(),
      favoriteTimelineBucketRemoteService: remote,
    );
    await controller.initialize();

    final topic = controller.selectedTopic!;
    final bucket = controller.timelineBuckets.first;

    final favorited = await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: bucket,
    );

    expect(favorited, isTrue);
    expect(remote.favoriteRequests.single.bucketKey, bucket.id);
    expect(controller.isFavoriteTimelineNode(topic: topic, bucket: bucket),
        isTrue);

    final removed = await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: bucket,
    );

    expect(removed, isFalse);
    expect(remote.deleteRequests.single.bucketStart, bucket.rangeStart);
    expect(controller.isFavoriteTimelineNode(topic: topic, bucket: bucket),
        isFalse);
  });

  test('guest bucket favorites are merged after login', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final storage = AppLocalStorage();
    await storage.init();
    final remote = _FakeFavoriteTimelineBucketRemoteService();
    final controller = buildController(
      storage,
      favoriteRemoteService: remote,
    );
    await controller.initialize();

    final topic = controller.recommendationTopics.first;
    await controller.selectTopic(topic);
    final bucket = controller.timelineBuckets.first;
    await controller.toggleFavoriteTimelineNode(topic: topic, bucket: bucket);

    expect(storage.readFavoriteTimelineNodes(), hasLength(1));

    await controller.sendVerificationCode('13812345678');
    await controller.verifySmsCode(
      rawPhoneNumber: '13812345678',
      smsCode: controller.debugVerificationCode!,
    );

    expect(remote.mergeRequests.single.items, hasLength(1));
    expect(remote.mergeRequests.single.items.single.bucketKey, bucket.id);
    expect(storage.readFavoriteTimelineNodes(), isEmpty);
  });

  testWidgets('timeline card favorite button toggles with snackbar',
      (tester) async {
    var favorited = false;
    final bucket = TimelineBucket(
      id: 'node-1',
      periodStart: DateTime(2026, 4, 24),
      granularity: TimelineGranularity.day,
      label: '2026年4月24日',
      headline: '部分科技成长方向成交额回升，带动指数午后修复。',
      entries: <TimelineEntry>[
        TimelineEntry(
          id: 'entry-1',
          topicId: 'topic-1',
          title: '部分科技成长方向成交额回升',
          summary: '部分科技成长方向成交额回升，带动指数午后修复。',
          detail: '部分科技成长方向成交额回升，带动指数午后修复。',
          fullText: '部分科技成长方向成交额回升，带动指数午后修复。',
          sourceName: '测试来源',
          timestamp: DateTime(2026, 4, 24),
          isMajor: false,
          primarySignal: '数据指标',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return TimelineBucketCard(
                bucket: bucket,
                isLast: true,
                favoriteButtonKey:
                    const ValueKey<String>('favorite-node-topic-1-node-1'),
                isFavoriteNode: favorited,
                onToggleFavorite: () {
                  setState(() => favorited = !favorited);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已收藏')),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final favoriteButton = find.byKey(
      const ValueKey<String>('favorite-node-topic-1-node-1'),
    );
    expect(favoriteButton, findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

    await tester.tap(favoriteButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('已收藏'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
  });

  testWidgets('favorite node card uses selected star icons', (tester) async {
    final node = FavoriteTimelineNode(
      id: 'topic-1:node-1',
      topicId: 'topic-1',
      topicName: '人民币汇率与A股资金流向',
      label: '2026年4月28日',
      headline: '机构建议提高红利资产和现金流稳定行业权重。',
      summary: '机构建议提高红利资产和现金流稳定行业权重。',
      timestamp: DateTime(2026, 4, 28),
      isMajor: false,
      savedAt: DateTime(2026, 5, 4),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavoriteNodeCard(
            node: node,
            onRemove: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
    expect(find.byIcon(Icons.bookmark_remove_outlined), findsNothing);
  });

  testWidgets('favorite node card shows one date label and localized signal',
      (tester) async {
    final node = FavoriteTimelineNode(
      id: 'topic-1:node-1',
      topicId: 'topic-1',
      topicName: '美伊战争总体进展',
      label: '2026年4月6日',
      headline: '多家航运公司上调霍尔木兹风险等级',
      summary: '霍尔木兹航运专题开始出现实质性风险升级节点。',
      timestamp: DateTime(2026, 4, 6),
      isMajor: true,
      savedAt: DateTime(2026, 5, 4),
      primarySignal: 'risk_warning',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavoriteNodeCard(
            node: node,
            onRemove: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('4月6日'), findsOneWidget);
    expect(find.text('风险预警'), findsOneWidget);
    expect(find.text('risk_warning'), findsNothing);
  });

  testWidgets('favorite node card expands to source reading action',
      (tester) async {
    final node = FavoriteTimelineNode(
      id: 'topic-1:node-1',
      topicId: 'topic-1',
      topicName: '人民币汇率与A股资金流向',
      label: '2026年4月28日',
      headline: '机构建议提高红利资产和现金流稳定行业权重。',
      summary: '机构建议提高红利资产和现金流稳定行业权重。',
      timestamp: DateTime(2026, 4, 28),
      isMajor: false,
      savedAt: DateTime(2026, 5, 4),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavoriteNodeCard(
            node: node,
            onRemove: () async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('阅读原文'), findsNothing);

    await tester.tap(find.byType(FavoriteNodeCard));
    await tester.pumpAndSettle();

    expect(find.text('阅读原文'), findsOneWidget);
  });

  testWidgets('favorite nodes screen confirms before removing a favorite',
      (tester) async {
    var removed = false;
    final node = FavoriteTimelineNode(
      id: 'topic-1:node-1',
      topicId: 'topic-1',
      topicName: '人民币汇率与A股资金流向',
      label: '2026年4月28日',
      headline: '机构建议提高红利资产和现金流稳定行业权重。',
      summary: '机构建议提高红利资产和现金流稳定行业权重。',
      timestamp: DateTime(2026, 4, 28),
      isMajor: false,
      savedAt: DateTime(2026, 5, 4),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FavoriteNodeCard(
            node: node,
            onRemove: () async {
              removed = true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('取消收藏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('确认取消收藏'), findsOneWidget);
    expect(removed, isFalse);

    await tester.tap(find.text('取消收藏'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(removed, isTrue);
  });
}

TimelineBucket _bucket({
  required String id,
  required DateTime start,
  required TimelineGranularity granularity,
  required String label,
}) {
  return TimelineBucket(
    id: id,
    periodStart: start,
    granularity: granularity,
    label: label,
    headline: '$label 节点',
    entries: <TimelineEntry>[
      TimelineEntry(
        id: 'entry-$id',
        topicId: 'topic-bucket',
        title: '$label 节点',
        summary: '$label 节点摘要',
        detail: '$label 节点详情',
        fullText: '$label 节点详情',
        sourceName: '测试来源',
        timestamp: start,
        isMajor: false,
      ),
    ],
  );
}

AuthSession _session() {
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

class _FakeFavoriteTimelineBucketRemoteService
    implements FavoriteTimelineBucketRemoteService {
  final List<FavoriteTimelineBucketRequestDto> favoriteRequests =
      <FavoriteTimelineBucketRequestDto>[];
  final List<FavoriteTimelineBucketDeleteRequestDto> deleteRequests =
      <FavoriteTimelineBucketDeleteRequestDto>[];
  final List<FavoriteTimelineBucketMergeRequestDto> mergeRequests =
      <FavoriteTimelineBucketMergeRequestDto>[];
  final List<FavoriteTimelineBucketDto> _items = <FavoriteTimelineBucketDto>[];

  @override
  Future<FavoriteTimelineBucketDto> favoriteBucket(
    FavoriteTimelineBucketRequestDto request,
  ) async {
    favoriteRequests.add(request);
    final item = FavoriteTimelineBucketDto(
      favoriteId: 'fav-${favoriteRequests.length}',
      topicId: request.topicId,
      topicTitle: request.topicTitle ?? request.topicId,
      topicSummary: request.topicSummary,
      bucketKey: request.bucketKey,
      bucketGranularity: request.bucketGranularity,
      bucketLabel: request.bucketLabel,
      bucketStart: request.bucketStart,
      bucketEnd: request.bucketEnd,
      headline: request.headline ?? request.bucketLabel,
      summary: request.summary ?? request.bucketLabel,
      containsMajorEvent: request.containsMajorEvent,
      savedAt: DateTime(2026, 5, 5, 12),
    );
    _items.insert(0, item);
    return item;
  }

  @override
  Future<FavoriteTimelineBucketDeleteResultDto> deleteBucket(
    FavoriteTimelineBucketDeleteRequestDto request,
  ) async {
    deleteRequests.add(request);
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
  Future<FavoriteTimelineBucketListDto> fetchBuckets({
    int limit = 20,
    String? cursor,
  }) async {
    return FavoriteTimelineBucketListDto(
      items: List<FavoriteTimelineBucketDto>.from(_items),
      hasMore: false,
    );
  }

  @override
  Future<FavoriteTimelineBucketMergeResultDto> mergeGuestBuckets(
    FavoriteTimelineBucketMergeRequestDto request,
  ) async {
    mergeRequests.add(request);
    return FavoriteTimelineBucketMergeResultDto(
      merged: request.items.length,
      alreadyExists: 0,
      skipped: 0,
      skippedItems: const <FavoriteTimelineBucketSkippedDto>[],
    );
  }
}
