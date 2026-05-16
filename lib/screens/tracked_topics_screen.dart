import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:share_plus/share_plus.dart';

import '../models/timeline_models.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_topic_card_parts.dart';
import '../widgets/timeline_quick_actions.dart';
import '../widgets/topic_icon_resolver.dart';

class TrackedTopicsScreen extends StatelessWidget {
  const TrackedTopicsScreen({
    super.key,
    required this.controller,
    required this.onOpenTopic,
  });

  final TimelineController controller;
  final Future<void> Function(Topic topic) onOpenTopic;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return SafeArea(
          child: SlidableAutoCloseBehavior(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pageHorizontalPadding,
                    14,
                    AppTheme.pageHorizontalPadding,
                    0,
                  ),
                  child: Column(
                    children: <Widget>[
                      AppTitleTopBar(
                        title: '我的关注',
                        leading: AppTopIconButton(
                          icon: Icons.person_rounded,
                          onPressed: () =>
                              showTimelineAccountSheet(context, controller),
                          backgroundColor: AppTheme.surface,
                          borderColor: AppTheme.warmHairline,
                        ),
                        trailing: AppTopIconButton(
                          icon: Icons.add_rounded,
                          onPressed: () => _openCreateTimelineSheet(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _TrackedSummaryBar(controller: controller),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TrackedTopicsFeed(
                    controller: controller,
                    onOpenTopic: onOpenTopic,
                    onShareTopic: (topic) => _shareTopic(context, topic),
                    onTogglePinTopic: (topic) =>
                        _togglePinTopic(context, topic),
                    onUnfollowTopic: (topic) => _unfollowTopic(context, topic),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmRemoval(BuildContext context, Topic topic) async {
    return showAppConfirmDialog(
      context,
      title: '确认取消关注',
      message: '取消关注后，「${topic.name}」将不再在“我的关注”中显示，但当前专题内容仍会保留。是否继续？',
      confirmLabel: '取消关注',
      destructive: true,
    );
  }

  Future<void> _openCreateTimelineSheet(BuildContext context) async {
    final createdTopic = await showTimelineCreateSheet(context, controller);

    if (createdTopic == null) {
      return;
    }

    await onOpenTopic(createdTopic);
  }

  Future<void> _unfollowTopic(BuildContext context, Topic topic) async {
    final shouldRemove = await _confirmRemoval(context, topic);
    if (!shouldRemove) {
      return;
    }

    await controller.removeTrackedTopic(topic);
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      '已取消关注「${topic.name}」',
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _togglePinTopic(BuildContext context, Topic topic) async {
    final pinned = controller.isPinned(topic);
    final changed = pinned
        ? await controller.unpinTopic(topic)
        : await controller.pinTopic(topic);
    if (!context.mounted) {
      return;
    }
    showAppSnackBar(
      context,
      changed
          ? (pinned ? '已取消置顶「${topic.name}」' : '已置顶「${topic.name}」')
          : (pinned ? '「${topic.name}」当前未置顶' : '「${topic.name}」已经置顶'),
      tone: changed ? AppSnackBarTone.success : AppSnackBarTone.warning,
    );
  }

  Future<void> _shareTopic(BuildContext context, Topic topic) async {
    late final String shareMessage;
    try {
      shareMessage = await controller.buildShareMessage(topic);
    } catch (error) {
      if (!context.mounted) {
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
      if (!context.mounted) {
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

class TrackedTopicsFeed extends StatelessWidget {
  const TrackedTopicsFeed({
    super.key,
    required this.controller,
    required this.onOpenTopic,
    required this.onShareTopic,
    required this.onTogglePinTopic,
    required this.onUnfollowTopic,
    this.topPadding = 0,
    this.bottomPadding = 120,
    this.leadingSlivers = const <Widget>[],
  });

  final TimelineController controller;
  final Future<void> Function(Topic topic) onOpenTopic;
  final Future<void> Function(Topic topic) onShareTopic;
  final Future<void> Function(Topic topic) onTogglePinTopic;
  final Future<void> Function(Topic topic) onUnfollowTopic;
  final double topPadding;
  final double bottomPadding;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    final visibleTopics = controller.visibleTrackedTopics;
    final content = <Widget>[
      if (controller.trackedTopics.isEmpty)
        const AppEmptyStateCard(
          icon: Icons.bookmark_add_outlined,
          title: '还没有关注事件',
          detail: '去推荐页挑选几个正在升温的事件，再回来从首页直接进入它们的时间线。',
        )
      else if (visibleTopics.isEmpty)
        const AppEmptyStateCard(
          icon: Icons.search_off_rounded,
          title: '没有匹配的关注事件',
          detail: '换个关键词试试，或清空搜索后查看全部关注事件。',
        )
      else
        ...visibleTopics.map(
          (topic) => Padding(
            padding: const EdgeInsets.only(
              bottom: AppTheme.cardVerticalGap,
            ),
            child: Slidable(
              key: ValueKey<String>('tracked-${topic.id}'),
              groupTag: 'tracked-topic-cards',
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.58,
                children: <Widget>[
                  _TrackedSwipeAction(
                    onPressed: (_) {
                      unawaited(onShareTopic(topic));
                    },
                    icon: Icons.ios_share_rounded,
                    label: '分享',
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.accentStrong,
                    borderColor: AppTheme.borderStrong.withValues(alpha: 0.32),
                  ),
                  _TrackedSwipeAction(
                    onPressed: (_) {
                      unawaited(onTogglePinTopic(topic));
                    },
                    icon: controller.isPinned(topic)
                        ? Icons.push_pin_outlined
                        : Icons.vertical_align_top_rounded,
                    label: controller.isPinned(topic) ? '取消置顶' : '置顶',
                    backgroundColor: controller.isPinned(topic)
                        ? AppTheme.surfaceMuted
                        : AppTheme.accentSoft.withValues(alpha: 0.72),
                    foregroundColor: controller.isPinned(topic)
                        ? AppTheme.textSecondary
                        : AppTheme.accentStrong,
                    borderColor: controller.isPinned(topic)
                        ? AppTheme.border
                        : AppTheme.accent.withValues(alpha: 0.20),
                  ),
                  _TrackedSwipeAction(
                    onPressed: (_) {
                      unawaited(onUnfollowTopic(topic));
                    },
                    icon: Icons.bookmark_remove_outlined,
                    label: '取消关注',
                    backgroundColor: AppTheme.highlightSoft,
                    foregroundColor: AppTheme.highlightStrong,
                    borderColor: AppTheme.danger.withValues(alpha: 0.28),
                  ),
                ],
              ),
              child: _TrackedTopicCard(
                controller: controller,
                topic: topic,
                pinned: controller.isPinned(topic),
                latestEntry: controller.latestEntryForTopic(topic.id),
                onOpen: () {
                  unawaited(onOpenTopic(topic));
                },
              ),
            ),
          ),
        ),
    ];

    return SlidableAutoCloseBehavior(
      child: RefreshIndicator(
        onRefresh: () async {
          await controller.refreshTrackedTopics();
          if (!context.mounted) {
            return;
          }
          final notice = controller.trackedTopicsRefreshNotice;
          if (notice == null || notice.isEmpty) {
            return;
          }
          showAppSnackBar(
            context,
            notice,
            tone: controller.trackedTopicsRefreshNoticeIsError
                ? AppSnackBarTone.warning
                : AppSnackBarTone.success,
          );
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            ...leadingSlivers,
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.pageHorizontalPadding,
                topPadding,
                AppTheme.pageHorizontalPadding,
                bottomPadding,
              ),
              sliver: SliverList.list(children: content),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackedSwipeAction extends StatelessWidget {
  const _TrackedSwipeAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final void Function(BuildContext context) onPressed;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return CustomSlidableAction(
      onPressed: onPressed,
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusControl),
          border: Border.all(color: borderColor),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: AppTheme.shadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: foregroundColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 17, color: foregroundColor),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: foregroundColor,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackedTopicCard extends StatelessWidget {
  const _TrackedTopicCard({
    required this.controller,
    required this.topic,
    required this.pinned,
    required this.latestEntry,
    required this.onOpen,
  });

  final TimelineController controller;
  final Topic topic;
  final bool pinned;
  final TimelineEntry? latestEntry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final followedTopic = controller.followedTopicItemFor(topic.id);
    final initializationState =
        controller.topicInitializationStateFor(topic.id);
    final status = controller.topicStatusFor(topic.id);
    final isPreparing = latestEntry == null &&
        (initializationState == 'pending' ||
            initializationState == 'running' ||
            (status == 'draft' &&
                (initializationState == null || initializationState.isEmpty)));
    final isInitializationFailed =
        latestEntry == null && initializationState == 'failed';
    final hasRecentUpdate = followedTopic?.hasRecentUpdate ?? false;
    final showRecentUpdateDot =
        controller.shouldShowTopicRecentUpdateDot(topic.id);
    final recentUpdateSummary = (() {
      final summary = followedTopic?.latestRelevantEventSummary?.trim();
      if (summary != null && summary.isNotEmpty) {
        return summary;
      }
      return latestEntry?.summary ?? topic.tagline;
    })();
    final recentUpdateAt = followedTopic?.latestRelevantEventAt;
    final latestStatusText = latestEntry == null
        ? isInitializationFailed
            ? '初始化失败'
            : initializationState == 'running'
                ? '初始化中'
                : (isPreparing ? '正在准备中' : '正在同步')
        : null;
    final latestTime = hasRecentUpdate
        ? (recentUpdateAt == null
            ? '刚刚更新'
            : _formatFollowedTopicDate(recentUpdateAt))
        : (latestEntry == null
            ? latestStatusText!
            : _formatFollowedTopicDate(latestEntry!.timestamp));
    final latestSummaryText = latestEntry?.summary ??
        (isInitializationFailed
            ? '服务器初始化失败，请稍后重试'
            : initializationState == 'running'
                ? '服务器正在初始化时间线'
                : (isPreparing ? '时间线正在准备中' : '等待首条进展'));

    final latestTone =
        hasRecentUpdate ? AppTheme.highlightStrong : AppTheme.accentStrong;
    final iconStyle = isInitializationFailed
        ? TopicIconResolver.failed
        : (pinned
            ? TopicIconResolver.pinned
            : TopicIconResolver.resolve(topic));
    const cardColor = AppTheme.surface;
    const cardBorderColor = AppTheme.border;

    return AppTopicCardSurface(
      onTap: onOpen,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: cardBorderColor),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 142),
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 42,
                        child: AppTopicIconBadge(
                          icon: iconStyle.icon,
                          backgroundColor: iconStyle.backgroundColor,
                          iconColor: iconStyle.foregroundColor,
                          borderColor: iconStyle.borderColor,
                          size: 40,
                          iconSize: 19,
                          radius: 14,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                topic.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.05,
                                      height: 1.3,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                topic.tagline,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                              ),
                              if (isPreparing) ...<Widget>[
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: const LinearProgressIndicator(
                                    minHeight: 6,
                                    value: 0.58,
                                    backgroundColor: AppTheme.surfaceMuted,
                                    color: AppTheme.highlight,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isPreparing) ...<Widget>[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        SizedBox(
                          width: 42,
                          height: latestTime.contains('\n') ? 30 : 22,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  latestTime,
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: latestTone,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _NodePreviewBar(
                            text: hasRecentUpdate
                                ? recentUpdateSummary
                                : latestSummaryText,
                            barColor: hasRecentUpdate
                                ? AppTheme.highlight
                                : AppTheme.accent,
                            textColor: isInitializationFailed
                                ? Theme.of(context).colorScheme.error
                                : AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (showRecentUpdateDot)
              Positioned(
                right: 17,
                top: 18,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.highlight,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: AppTheme.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFollowedTopicDate(DateTime timestamp) {
    return formatTopicCardNodeTimeLabel(timestamp);
  }
}

class _TrackedSummaryBar extends StatelessWidget {
  const _TrackedSummaryBar({
    required this.controller,
  });

  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    final followedCount = controller.trackedTopics.length;
    final unreadCount = controller.trackedTopics
        .where((topic) => controller.topicHasRecentUpdate(topic.id))
        .length;
    final todayUpdateCount = controller.trackedTopics
        .where((topic) => _topicUpdatedToday(controller, topic))
        .length;
    final summary = _summaryText(
      followedCount: followedCount,
      unreadCount: unreadCount,
      todayUpdateCount: todayUpdateCount,
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.66),
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.84)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            unreadCount > 0
                ? Icons.mark_unread_chat_alt_rounded
                : Icons.check_circle_outline_rounded,
            size: 15,
            color: unreadCount > 0
                ? AppTheme.highlightStrong
                : AppTheme.accentStrong,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  bool _topicUpdatedToday(TimelineController controller, Topic topic) {
    final timestamp = controller.topicLatestRelevantEventAt(topic.id) ??
        controller.latestEntryForTopic(topic.id)?.timestamp;
    if (timestamp == null) {
      return false;
    }
    final local = timestamp.toLocal();
    final now = DateTime.now().toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  String _summaryText({
    required int followedCount,
    required int unreadCount,
    required int todayUpdateCount,
  }) {
    if (followedCount == 0) {
      return '还没有关注专题';
    }
    if (unreadCount > 0 && todayUpdateCount > 0) {
      return '今日 $todayUpdateCount 个专题更新，$unreadCount 个有新进展';
    }
    if (unreadCount > 0) {
      return '$unreadCount 个专题有新进展';
    }
    if (todayUpdateCount > 0) {
      return '今日 $todayUpdateCount 个专题更新';
    }
    return '已关注 $followedCount 个专题，暂无新进展';
  }
}

class _NodePreviewBar extends StatelessWidget {
  const _NodePreviewBar({
    required this.text,
    required this.barColor,
    required this.textColor,
  });

  final String text;
  final Color barColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(width: 3, color: barColor),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 8, 7),
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.45,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
