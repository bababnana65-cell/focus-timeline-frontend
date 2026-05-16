import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/timeline_models.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_feedback.dart';
import '../widgets/timeline_bucket_card.dart';
import '../widgets/timeline_quick_actions.dart';

class TimelineAutoExpandRequest {
  const TimelineAutoExpandRequest({
    required this.token,
    required this.topicId,
    required this.targetAt,
  });

  final int token;
  final String topicId;
  final DateTime targetAt;
}

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.controller,
    required this.onSwipeBack,
    required this.onSwipeForward,
    this.autoExpandRequest,
    this.onAutoExpandRequestConsumed,
    this.onClose,
  });

  final TimelineController controller;
  final Future<void> Function() onSwipeBack;
  final Future<void> Function() onSwipeForward;
  final TimelineAutoExpandRequest? autoExpandRequest;
  final VoidCallback? onAutoExpandRequestConsumed;
  final VoidCallback? onClose;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  static const double _timelineListBottomPadding = 88;

  final ScrollController _scrollController = ScrollController();
  String _lastSignature = '';
  int _handledAutoExpandRequestToken = 0;
  int _manualScrollRequestToken = 0;
  int _handledManualScrollRequestToken = 0;
  String? _manualScrollTargetBucketId;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final buckets = controller.visibleTimelineBuckets;
        final fullBuckets = controller.timelineBuckets;
        final timelineStats = controller.selectedTimelineStats;
        final startAt =
            timelineStats?.startedAt ?? _timelineStartAt(fullBuckets);
        final latestAt =
            timelineStats?.latestEventAt ?? _timelineLatestAt(fullBuckets);
        final selectedTopic = controller.selectedTopic;
        final initialBucket = _timelineInitialBucket(fullBuckets);
        final latestBucket = _timelineLatestBucket(fullBuckets);
        final visibleInitialBucket = _timelineInitialBucket(buckets);
        final visibleLatestBucket = _timelineLatestBucket(buckets);
        final initialBucketId = initialBucket?.id;
        final latestBucketId = latestBucket?.id;
        final majorNodeCount = timelineStats?.majorNodeCount ??
            fullBuckets.fold<int>(
              0,
              (count, bucket) =>
                  count + bucket.entries.where((entry) => entry.isMajor).length,
            );
        final startLabel = initialBucket == null
            ? formatTimelineHeaderDateLabel(startAt)
            : formatTimelineBucketDateLabel(initialBucket);
        final latestLabel = latestBucket == null
            ? formatTimelineHeaderDateLabel(
                latestAt,
                relativeRecent: true,
              )
            : formatTimelineBucketDateLabel(latestBucket);
        final favoriteNodeCount = selectedTopic == null
            ? 0
            : fullBuckets
                .where(
                  (bucket) => controller.isFavoriteTimelineNode(
                    topic: selectedTopic,
                    bucket: bucket,
                  ),
                )
                .length;
        final signature =
            '${controller.sortOrder.name}-${controller.timelineSearchQuery}-${controller.showOnlyMajorNodes}-${controller.showOnlyFavoriteNodes}-${buckets.map((bucket) => bucket.id).join('|')}';
        _scheduleAutoScrollIfNeeded(signature, controller.sortOrder);
        final autoExpandBucketId = _autoExpandBucketIdFor(controller, buckets);

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, _) {
              final summaryCard = AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<String?>(
                    '${controller.selectedTopicId}-${controller.sortOrder.name}',
                  ),
                  child: _summaryCard(
                    context,
                    controller,
                    majorNodeCount: majorNodeCount,
                    favoriteNodeCount: favoriteNodeCount,
                    startLabel: startLabel,
                    latestLabel: latestLabel,
                    onJumpToStart: visibleInitialBucket == null
                        ? null
                        : () => _requestManualScrollToBucket(
                              visibleInitialBucket.id,
                            ),
                    onJumpToLatest: visibleLatestBucket == null
                        ? null
                        : () => _requestManualScrollToBucket(
                              visibleLatestBucket.id,
                            ),
                    onToggleMajorOnly: controller.selectedTopic == null
                        ? null
                        : controller.toggleMajorNodesOnly,
                    onToggleFavoriteOnly: controller.selectedTopic == null
                        ? null
                        : controller.toggleFavoriteNodesOnly,
                  ),
                ),
              );

              return Column(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      14,
                      16,
                      12,
                    ),
                    decoration: const BoxDecoration(
                      color: AppTheme.timelineBackground,
                    ),
                    child: Column(
                      children: <Widget>[
                        AppTitleTopBar(
                          title: selectedTopic?.name ?? '时间轴',
                          subtitle: selectedTopic?.tagline,
                          subtitleLeading: selectedTopic == null
                              ? null
                              : _TimelineFollowStatusChip(
                                  followed:
                                      controller.isFollowing(selectedTopic),
                                ),
                          leading: widget.onClose == null
                              ? const SizedBox.shrink()
                              : AppTopIconButton(
                                  icon: Icons.arrow_back_rounded,
                                  onPressed: widget.onClose!,
                                  tooltip: '返回',
                                ),
                          trailing: AppTopIconButton(
                            icon: Icons.more_vert_rounded,
                            onPressed: () {
                              _showTimelineTopMenu(context, controller);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        summaryCard,
                      ],
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: AppTheme.timelineBackground,
                      child: Column(
                        children: <Widget>[
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: controller.refreshTimeline,
                              child: ListView(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  AppTheme.pageHorizontalPadding,
                                  10,
                                  AppTheme.pageHorizontalPadding,
                                  _timelineListBottomPadding,
                                ),
                                children: <Widget>[
                                  if (controller.isLoading && buckets.isEmpty)
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 80),
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    )
                                  else if (controller.selectedTopic == null)
                                    const AppEmptyStateCard(
                                      icon: Icons.inbox_outlined,
                                      title: '暂无关注事件',
                                      detail: '先去推荐页添加一个关注专题。',
                                    )
                                  else if (buckets.isEmpty)
                                    _buildTimelineEmptyContent(
                                      context,
                                      controller,
                                    )
                                  else
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 240),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      child: Column(
                                        key: ValueKey<String>(signature),
                                        children: buckets.asMap().entries.map(
                                          (entry) {
                                            final index = entry.key;
                                            final bucket = entry.value;
                                            final autoExpandToken =
                                                bucket.id == autoExpandBucketId
                                                    ? widget.autoExpandRequest
                                                        ?.token
                                                    : null;
                                            final manualScrollToken = bucket
                                                        .id ==
                                                    _manualScrollTargetBucketId
                                                ? _manualScrollRequestToken
                                                : null;
                                            return KeyedSubtree(
                                              key: ValueKey<String>(
                                                'timeline-bucket-${bucket.id}',
                                              ),
                                              child: Builder(
                                                builder: (bucketContext) {
                                                  _scheduleAutoExpandIfNeeded(
                                                    bucketContext:
                                                        bucketContext,
                                                    token: autoExpandToken,
                                                  );
                                                  _scheduleManualScrollIfNeeded(
                                                    bucketContext:
                                                        bucketContext,
                                                    token: manualScrollToken,
                                                  );
                                                  return TimelineBucketCard(
                                                    bucket: bucket,
                                                    autoExpandToken:
                                                        autoExpandToken,
                                                    favoriteButtonKey:
                                                        selectedTopic == null
                                                            ? null
                                                            : ValueKey<String>(
                                                                'favorite-node-${selectedTopic.id}-${bucket.id}',
                                                              ),
                                                    isFavoriteNode: selectedTopic !=
                                                            null &&
                                                        controller
                                                            .isFavoriteTimelineNode(
                                                          topic: selectedTopic,
                                                          bucket: bucket,
                                                        ),
                                                    onToggleFavorite:
                                                        selectedTopic == null
                                                            ? null
                                                            : () => unawaited(
                                                                  _toggleFavoriteNode(
                                                                    context,
                                                                    controller,
                                                                    selectedTopic,
                                                                    bucket,
                                                                  ),
                                                                ),
                                                    isFirst: index == 0,
                                                    isLast: index ==
                                                        buckets.length - 1,
                                                    isInitialNode: bucket.id ==
                                                        initialBucketId,
                                                    isLatestNode: bucket.id ==
                                                        latestBucketId,
                                                    latestDirectionUp: controller
                                                            .sortOrder ==
                                                        TimelineSortOrder
                                                            .reverseChronological,
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ).toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _requestManualScrollToBucket(String bucketId) {
    setState(() {
      _manualScrollTargetBucketId = bucketId;
      _manualScrollRequestToken += 1;
    });
  }

  Future<void> _toggleFavoriteNode(
    BuildContext context,
    TimelineController controller,
    Topic topic,
    TimelineBucket bucket,
  ) async {
    final favorited = await controller.toggleFavoriteTimelineNode(
      topic: topic,
      bucket: bucket,
    );
    if (!mounted || !context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      favorited ? '已收藏' : '已取消收藏',
      tone: favorited ? AppSnackBarTone.success : AppSnackBarTone.info,
    );
  }

  String? _autoExpandBucketIdFor(
    TimelineController controller,
    List<TimelineBucket> buckets,
  ) {
    final request = widget.autoExpandRequest;
    if (request == null ||
        request.token == _handledAutoExpandRequestToken ||
        controller.selectedTopicId != request.topicId ||
        buckets.isEmpty) {
      return null;
    }

    final targetMicros = request.targetAt.toUtc().microsecondsSinceEpoch;
    String? nearestBucketId;
    int? nearestDifference;
    for (final bucket in buckets) {
      for (final entry in bucket.entries) {
        final difference =
            (entry.timestamp.toUtc().microsecondsSinceEpoch - targetMicros)
                .abs();
        if (difference == 0) {
          return bucket.id;
        }
        if (nearestDifference == null || difference < nearestDifference) {
          nearestDifference = difference;
          nearestBucketId = bucket.id;
        }
      }
    }
    return nearestBucketId;
  }

  void _scheduleAutoExpandIfNeeded({
    required BuildContext bucketContext,
    required int? token,
  }) {
    final request = widget.autoExpandRequest;
    if (request == null ||
        token == null ||
        request.token == _handledAutoExpandRequestToken) {
      return;
    }
    _handledAutoExpandRequestToken = request.token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !bucketContext.mounted) {
        return;
      }
      if (!_scrollController.hasClients) {
        widget.onAutoExpandRequestConsumed?.call();
        return;
      }

      Scrollable.ensureVisible(
        bucketContext,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
      widget.onAutoExpandRequestConsumed?.call();
    });
  }

  void _scheduleManualScrollIfNeeded({
    required BuildContext bucketContext,
    required int? token,
  }) {
    if (token == null || token == _handledManualScrollRequestToken) {
      return;
    }
    _handledManualScrollRequestToken = token;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !bucketContext.mounted || !_scrollController.hasClients) {
        return;
      }
      Scrollable.ensureVisible(
        bucketContext,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.04,
      );
    });
  }

  TimelineBucket? _timelineInitialBucket(List<TimelineBucket> buckets) {
    if (buckets.isEmpty) {
      return null;
    }
    return buckets.reduce(
      (a, b) => a.periodStart.isBefore(b.periodStart) ? a : b,
    );
  }

  TimelineBucket? _timelineLatestBucket(List<TimelineBucket> buckets) {
    if (buckets.isEmpty) {
      return null;
    }
    return buckets.reduce(
      (a, b) => a.periodStart.isAfter(b.periodStart) ? a : b,
    );
  }

  DateTime? _timelineStartAt(List<TimelineBucket> buckets) {
    DateTime? startAt;
    for (final bucket in buckets) {
      for (final entry in bucket.entries) {
        if (startAt == null || entry.timestamp.isBefore(startAt)) {
          startAt = entry.timestamp;
        }
      }
    }
    return startAt;
  }

  DateTime? _timelineLatestAt(List<TimelineBucket> buckets) {
    DateTime? latestAt;
    for (final bucket in buckets) {
      for (final entry in bucket.entries) {
        if (latestAt == null || entry.timestamp.isAfter(latestAt)) {
          latestAt = entry.timestamp;
        }
      }
    }
    return latestAt;
  }

  Widget _summaryCard(
    BuildContext context,
    TimelineController controller, {
    required int majorNodeCount,
    required int favoriteNodeCount,
    required String startLabel,
    required String latestLabel,
    required VoidCallback? onJumpToStart,
    required VoidCallback? onJumpToLatest,
    required VoidCallback? onToggleMajorOnly,
    required VoidCallback? onToggleFavoriteOnly,
  }) {
    return Column(
      children: <Widget>[
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.70),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _TimelineInfoTile(
                  key: const ValueKey<String>('timeline-jump-to-start'),
                  icon: Icons.schedule_rounded,
                  label: '起始时间',
                  value: startLabel,
                  semanticsLabel: '跳转到事件起点',
                  onTap: onJumpToStart,
                ),
              ),
              const _StatsDivider(),
              Expanded(
                child: _TimelineInfoTile(
                  icon: Icons.radio_button_checked_rounded,
                  label: '重大节点',
                  value: '$majorNodeCount',
                  semanticsLabel:
                      controller.showOnlyMajorNodes ? '恢复显示全部节点' : '只显示重大事件',
                  onTap: onToggleMajorOnly,
                  selected: controller.showOnlyMajorNodes,
                ),
              ),
              const _StatsDivider(),
              Expanded(
                child: _TimelineInfoTile(
                  key: const ValueKey<String>('timeline-toggle-favorites'),
                  icon: controller.showOnlyFavoriteNodes
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  label: '收藏节点',
                  value: '$favoriteNodeCount',
                  semanticsLabel:
                      controller.showOnlyFavoriteNodes ? '恢复显示全部节点' : '只显示收藏节点',
                  onTap: onToggleFavoriteOnly,
                  selected: controller.showOnlyFavoriteNodes,
                ),
              ),
              const _StatsDivider(),
              Expanded(
                child: _TimelineInfoTile(
                  key: const ValueKey<String>('timeline-jump-to-latest'),
                  icon: Icons.update_rounded,
                  label: '最新更新',
                  value: latestLabel,
                  semanticsLabel: '跳转到最新节点',
                  onTap: onJumpToLatest,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _scheduleAutoScrollIfNeeded(
      String signature, TimelineSortOrder sortOrder) {
    if (_lastSignature == signature) {
      return;
    }
    _lastSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      if (sortOrder == TimelineSortOrder.reverseChronological) {
        _scrollController.jumpTo(position.minScrollExtent);
        return;
      }
      final target = position.maxScrollExtent - _timelineListBottomPadding + 12;
      _scrollController.jumpTo(
        target
            .clamp(position.minScrollExtent, position.maxScrollExtent)
            .toDouble(),
      );
    });
  }

  String _buildTimelineEmptyTitle(TimelineController controller) {
    final initializing = _isSelectedTopicInitializing(controller);
    final initializationFailed =
        _isSelectedTopicInitializationFailed(controller);
    final searching = controller.timelineSearchQuery.trim().isNotEmpty;
    if (searching && controller.showOnlyMajorNodes) {
      return '没有匹配的重大节点';
    }
    if (controller.showOnlyFavoriteNodes) {
      return '当前没有收藏节点';
    }
    if (searching) {
      return '没有匹配的时间线节点';
    }
    if (controller.showOnlyMajorNodes) {
      return '当前没有重大节点';
    }
    if (initializationFailed) {
      return '初始化失败';
    }
    if (initializing) {
      return controller.selectedTopicInitializationState == 'running'
          ? '时间线初始化中'
          : '时间线正在准备中';
    }
    return '当前没有可展示的事件节点';
  }

  Widget _buildTimelineEmptyContent(
    BuildContext context,
    TimelineController controller,
  ) {
    final searching = controller.timelineSearchQuery.trim().isNotEmpty;
    final showPreparingState = controller.selectedTopic != null &&
        _isSelectedTopicInitializing(controller) &&
        !searching &&
        !controller.showOnlyMajorNodes &&
        !controller.showOnlyFavoriteNodes;
    if (showPreparingState) {
      return _TimelinePreparingState(topic: controller.selectedTopic!);
    }

    return AppEmptyStateCard(
      icon: controller.showOnlyFavoriteNodes
          ? Icons.star_border_rounded
          : controller.showOnlyMajorNodes
              ? Icons.flag_outlined
              : Icons.search_off_rounded,
      title: _buildTimelineEmptyTitle(controller),
      detail: _buildTimelineEmptyDetail(controller),
    );
  }

  String _buildTimelineEmptyDetail(TimelineController controller) {
    final initializing = _isSelectedTopicInitializing(controller);
    final initializationFailed =
        _isSelectedTopicInitializationFailed(controller);
    final searching = controller.timelineSearchQuery.trim().isNotEmpty;
    if (searching && controller.showOnlyMajorNodes) {
      return '换个关键词试试，或在右上角菜单选择“展开全部”。';
    }
    if (controller.showOnlyFavoriteNodes) {
      return '再次点击“收藏节点”即可恢复全部节点。';
    }
    if (searching) {
      return '换个关键词试试，或清空搜索后查看全部节点。';
    }
    if (controller.showOnlyMajorNodes) {
      return '在右上角菜单选择“展开全部”即可恢复全部节点。';
    }
    if (initializationFailed) {
      return '服务器初始化失败，可点击重试重新请求服务端初始化。';
    }
    if (initializing) {
      return controller.selectedTopicInitializationState == 'running'
          ? '服务器正在核验证据并生成首批节点，页面会自动刷新最新进展。'
          : '专题已进入服务端初始化队列，页面会自动轮询状态。';
    }
    return '稍后重试，或切换到其他专题查看。';
  }

  bool _isSelectedTopicInitializing(TimelineController controller) {
    final initializationState = controller.selectedTopicInitializationState;
    final status = controller.selectedTopicStatus;
    if (initializationState == 'failed') {
      return false;
    }
    return initializationState == 'pending' ||
        initializationState == 'running' ||
        (status == 'draft' &&
            (initializationState == null || initializationState.isEmpty));
  }

  bool _isSelectedTopicInitializationFailed(TimelineController controller) {
    final initializationState = controller.selectedTopicInitializationState;
    return initializationState == 'failed';
  }

  Future<void> _showTimelineTopMenu(
    BuildContext context,
    TimelineController controller,
  ) async {
    final selectedAction = await showMenu<_TimelineTopAction>(
      context: context,
      position: _timelineTopMenuPosition(context),
      color: AppTheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      constraints: const BoxConstraints(minWidth: 282, maxWidth: 282),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: const BorderSide(color: AppTheme.border),
      ),
      items: _buildTimelineTopMenuItems(context, controller),
    );
    if (selectedAction == null || !mounted) {
      return;
    }
    await _handleTimelineTopAction(selectedAction, controller);
  }

  RelativeRect _timelineTopMenuPosition(BuildContext context) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final topBar = context.findRenderObject()! as RenderBox;
    final topLeft = topBar.localToGlobal(Offset.zero, ancestor: overlay);
    return RelativeRect.fromLTRB(
      overlay.size.width - AppTheme.pageHorizontalPadding - 260,
      topLeft.dy + 54,
      AppTheme.pageHorizontalPadding,
      0,
    );
  }

  List<PopupMenuEntry<_TimelineTopAction>> _buildTimelineTopMenuItems(
    BuildContext context,
    TimelineController controller,
  ) {
    final topic = controller.selectedTopic;
    final following = topic != null && controller.isFollowing(topic);
    final followLoading =
        topic != null && controller.isFollowMutationInFlight(topic);
    final sortOrder = controller.sortOrder;
    final nextSortOrder = sortOrder == TimelineSortOrder.chronological
        ? TimelineSortOrder.reverseChronological
        : TimelineSortOrder.chronological;
    final majorCount = controller.selectedTimelineStats?.majorNodeCount ??
        controller.timelineBuckets
            .where((bucket) => bucket.containsMajorEvent)
            .length;
    final majorOnly = controller.showOnlyMajorNodes;

    return <PopupMenuEntry<_TimelineTopAction>>[
      const PopupMenuItem<_TimelineTopAction>(
        value: _TimelineTopAction.search,
        padding: EdgeInsets.zero,
        child: _TimelineTopMenuRow(
          icon: Icons.search_rounded,
          title: '搜索时间线节点',
          detail: '按关键词筛选当前时间轴',
        ),
      ),
      PopupMenuItem<_TimelineTopAction>(
        value: _TimelineTopAction.share,
        enabled: topic != null,
        padding: EdgeInsets.zero,
        child: _TimelineTopMenuRow(
          icon: Icons.ios_share_rounded,
          title: '分享',
          detail: topic?.name ?? '进入专题后可分享时间线',
          muted: topic == null,
        ),
      ),
      PopupMenuItem<_TimelineTopAction>(
        value: _TimelineTopAction.toggleFollow,
        enabled: topic != null && !followLoading,
        padding: EdgeInsets.zero,
        child: _TimelineTopMenuRow(
          icon: following
              ? Icons.bookmark_remove_outlined
              : Icons.bookmark_add_outlined,
          title: topic == null ? '暂无当前专题' : (following ? '取消关注' : '关注'),
          detail: topic?.name ?? '进入专题后可操作关注状态',
          muted: topic == null,
          trailing: followLoading
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
      ),
      PopupMenuItem<_TimelineTopAction>(
        value: _TimelineTopAction.toggleMajorOnly,
        enabled: topic != null,
        padding: EdgeInsets.zero,
        child: _TimelineTopMenuRow(
          icon:
              majorOnly ? Icons.unfold_more_rounded : Icons.filter_alt_outlined,
          title: majorOnly ? '展开全部' : '只看重点',
          detail: majorOnly
              ? '恢复显示所有事件节点'
              : (majorCount > 0 ? '仅显示 $majorCount 个重大节点' : '当前没有重大节点'),
          muted: topic == null,
        ),
      ),
      PopupMenuItem<_TimelineTopAction>(
        value: _TimelineTopAction.toggleSortOrder,
        padding: EdgeInsets.zero,
        child: _TimelineTopMenuRow(
          icon: Icons.swap_vert_rounded,
          title: '时间顺序',
          detail: '当前${sortOrder.label}，点击切换为${nextSortOrder.label}',
        ),
      ),
    ];
  }

  Future<void> _handleTimelineTopAction(
    _TimelineTopAction action,
    TimelineController controller,
  ) async {
    switch (action) {
      case _TimelineTopAction.search:
        showTopSearchSheet(
          context: context,
          title: '搜索时间线节点',
          hintText: '搜索时间线节点',
          value: controller.timelineSearchQuery,
          onChanged: controller.setTimelineSearchQuery,
        );
        return;
      case _TimelineTopAction.share:
        final topic = controller.selectedTopic;
        if (topic == null) {
          return;
        }
        await _shareTopic(topic);
        return;
      case _TimelineTopAction.toggleFollow:
        final topic = controller.selectedTopic;
        if (topic == null) {
          return;
        }
        await controller.toggleFollow(topic);
        return;
      case _TimelineTopAction.toggleMajorOnly:
        controller.toggleMajorNodesOnly();
        return;
      case _TimelineTopAction.toggleSortOrder:
        controller.toggleSortOrder();
        return;
    }
  }

  Future<void> _shareTopic(Topic topic) async {
    late final String shareMessage;
    try {
      shareMessage = await widget.controller.buildShareMessage(topic);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        '生成分享链接失败：$error',
        tone: AppSnackBarTone.error,
      );
      return;
    }

    try {
      await Share.share(
        shareMessage,
        subject: '事件时间线：${topic.name}',
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareMessage));
      if (!mounted) {
        return;
      }
      showAppSnackBar(
        context,
        '系统分享不可用，链接已复制。',
        tone: AppSnackBarTone.info,
      );
    }
  }
}

class _TimelineFollowStatusChip extends StatelessWidget {
  const _TimelineFollowStatusChip({
    required this.followed,
  });

  final bool followed;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey<String>('timeline-topic-follow-status'),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: followed
            ? AppTheme.accentSoft.withValues(alpha: 0.34)
            : AppTheme.surfaceMuted.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: followed
              ? AppTheme.accent.withValues(alpha: 0.18)
              : AppTheme.border.withValues(alpha: 0.86),
        ),
      ),
      child: Text(
        followed ? '已关注' : '未关注',
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: followed ? AppTheme.accentStrong : AppTheme.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
      ),
    );
  }
}

enum _TimelineTopAction {
  search,
  share,
  toggleFollow,
  toggleMajorOnly,
  toggleSortOrder,
}

class _TimelineTopMenuRow extends StatelessWidget {
  const _TimelineTopMenuRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.muted = false,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool muted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final iconColor = muted ? AppTheme.textTertiary : AppTheme.textSecondary;
    final titleColor = muted ? AppTheme.textTertiary : AppTheme.textPrimary;

    return SizedBox(
      width: 282,
      height: 58,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 14),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(icon, size: 19, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: muted
                            ? AppTheme.textTertiary
                            : AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          if (trailing != null) trailing!,
          if (trailing != null) const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _TimelinePreparingState extends StatelessWidget {
  const _TimelinePreparingState({
    required this.topic,
  });

  final Topic topic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppTheme.shadow,
                  blurRadius: 18,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        topic.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                  height: 1.2,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const _StatusPill(
                      label: '正在准备中',
                      foreground: AppTheme.highlight,
                      background: AppTheme.highlightSoft,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  topic.tagline,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    minHeight: 7,
                    backgroundColor: AppTheme.accentSoft,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: AppTheme.accentSoft.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.28),
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _StatusPill(
                  label: '初始化中',
                  foreground: AppTheme.highlight,
                  background: AppTheme.highlightSoft,
                ),
                SizedBox(height: 14),
                _PreparingStepRow(
                  index: '1',
                  title: '确认专题定义',
                  detail: '标题、摘要和关键词已确定',
                  status: '完成',
                ),
                SizedBox(height: 12),
                _PreparingStepRow(
                  index: '2',
                  title: '核验初始节点',
                  detail: '检索来源并生成首批可核验时间线',
                  status: '进行中',
                ),
                SizedBox(height: 12),
                _PreparingStepRow(
                  index: '3',
                  title: '同步最新状态',
                  detail: '完成后自动刷新到可阅读状态',
                  status: '等待',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreparingStepRow extends StatelessWidget {
  const _PreparingStepRow({
    required this.index,
    required this.title,
    required this.detail,
    required this.status,
  });

  final String index;
  final String title;
  final String detail;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 18,
          child: Text(
            index,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppTheme.accentStrong,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTheme.accentStrong,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.2,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            status,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: status == '完成'
                      ? AppTheme.highlight
                      : (status == '进行中'
                          ? AppTheme.accentStrong
                          : AppTheme.textSecondary),
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

class _StatsDivider extends StatelessWidget {
  const _StatsDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      color: AppTheme.border,
    );
  }
}

class _TimelineInfoTile extends StatelessWidget {
  const _TimelineInfoTile({
    required this.icon,
    required this.value,
    required this.label,
    this.onTap,
    this.semanticsLabel,
    this.selected = false,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final labelColor =
        selected ? AppTheme.accentStrong : AppTheme.textSecondary;
    final iconColor = selected ? AppTheme.accentStrong : AppTheme.textTertiary;
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? AppTheme.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.36)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    icon,
                    size: 13,
                    color: iconColor,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontSize: 10.2,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.05,
                      height: 1,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
    if (onTap == null) {
      return child;
    }
    return Semantics(
      button: true,
      label: semanticsLabel ?? label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
      ),
    );
  }
}
