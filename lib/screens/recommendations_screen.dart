import 'dart:async';

import 'package:flutter/material.dart';

import '../models/timeline_models.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_topic_card_parts.dart';
import '../widgets/topic_icon_resolver.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({
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
                    _RecommendationsModeBar(
                      mode: controller.recommendationMode,
                      onShowPersonalized:
                          controller.showPersonalizedRecommendations,
                      onShowHot: controller.showHotRecommendations,
                      onShowExplore: controller.showExploreRecommendations,
                      onShowHistory: controller.showHistoryRecommendations,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: RecommendationsFeed(
                  controller: controller,
                  onOpenTopic: onOpenTopic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class RecommendationsFeed extends StatelessWidget {
  const RecommendationsFeed({
    super.key,
    required this.controller,
    required this.onOpenTopic,
    this.topPadding = 0,
    this.bottomPadding = 120,
    this.leadingSlivers = const <Widget>[],
  });

  final TimelineController controller;
  final Future<void> Function(Topic topic) onOpenTopic;
  final double topPadding;
  final double bottomPadding;
  final List<Widget> leadingSlivers;

  @override
  Widget build(BuildContext context) {
    final topics = controller.recommendationTopics;
    final isSearching = controller.recommendationSearchQuery.trim().isNotEmpty;
    final content = <Widget>[
      if (isSearching && topics.isEmpty)
        const AppEmptyStateCard(
          icon: Icons.search_off_rounded,
          title: '没有找到匹配事件',
          detail: '当前事件库里没有匹配结果，换个关键词试试。',
          centered: false,
          boxedIcon: true,
          backgroundColor: AppTheme.surface,
          borderColor: AppTheme.border,
        )
      else if (controller.isHistoryRecommendationMode && topics.isEmpty)
        const AppEmptyStateCard(
          icon: Icons.history_rounded,
          title: '还没有浏览历史',
          detail: '当你点开任意事件时间线后，这里会自动保留最近浏览记录，方便你回溯。',
          centered: false,
          boxedIcon: true,
          backgroundColor: AppTheme.surface,
          borderColor: AppTheme.border,
        )
      else
        ...topics.asMap().entries.map(
          (item) {
            final topic = item.value;
            final following = controller.isFollowing(topic);
            final latestNode = _recommendationLatestNode(controller, topic);
            return Padding(
              padding: const EdgeInsets.only(
                bottom: AppTheme.cardVerticalGap,
              ),
              child: _RecommendationSwipeCard(
                key: ValueKey<String>(
                  'recommend-${controller.recommendationMode.name}-${topic.id}',
                ),
                rank: item.key + 1,
                mode: controller.recommendationMode,
                topic: topic,
                latestNode: latestNode,
                following: following,
                followLoading: controller.isFollowMutationInFlight(topic),
                onOpenPressed: () => onOpenTopic(topic),
                onToggleFollow: () => controller.toggleFollow(topic),
              ),
            );
          },
        ),
    ];

    return RefreshIndicator(
      onRefresh: () async {
        await controller.refreshRecommendations();
        if (!context.mounted) {
          return;
        }
        final notice = controller.recommendationRefreshNotice;
        if (notice == null || notice.isEmpty) {
          return;
        }
        showAppSnackBar(
          context,
          notice,
          tone: controller.recommendationRefreshNoticeIsError
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
    );
  }
}

class _RecommendationLatestNode {
  const _RecommendationLatestNode({
    required this.summary,
    required this.timeLabel,
  });

  final String summary;
  final String timeLabel;
}

_RecommendationLatestNode _recommendationLatestNode(
  TimelineController controller,
  Topic topic,
) {
  final followedSummary =
      controller.topicLatestRelevantEventSummary(topic.id)?.trim();
  final followedAt = controller.topicLatestRelevantEventAt(topic.id);
  if (followedSummary != null && followedSummary.isNotEmpty) {
    return _RecommendationLatestNode(
      summary: followedSummary,
      timeLabel: _formatRecommendationNodeTime(followedAt),
    );
  }

  final latestEntry = controller.latestEntryForTopic(topic.id);
  final latestEntrySummary = latestEntry?.summary.trim();
  if (latestEntry != null &&
      latestEntrySummary != null &&
      latestEntrySummary.isNotEmpty) {
    return _RecommendationLatestNode(
      summary: latestEntrySummary,
      timeLabel: _formatRecommendationNodeTime(latestEntry.timestamp),
    );
  }

  return _RecommendationLatestNode(
    summary: topic.tagline,
    timeLabel: '最新',
  );
}

String _formatRecommendationNodeTime(DateTime? timestamp) {
  if (timestamp == null) {
    return '最新';
  }

  return formatTopicCardNodeTimeLabel(timestamp);
}

class _RecommendationSwipeCard extends StatelessWidget {
  const _RecommendationSwipeCard({
    super.key,
    required this.rank,
    required this.mode,
    required this.topic,
    required this.latestNode,
    required this.following,
    required this.followLoading,
    required this.onOpenPressed,
    required this.onToggleFollow,
  });

  final int rank;
  final RecommendationMode mode;
  final Topic topic;
  final _RecommendationLatestNode latestNode;
  final bool following;
  final bool followLoading;
  final Future<void> Function() onOpenPressed;
  final Future<void> Function() onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final showRank = mode == RecommendationMode.hot;

    return AppTopicCardSurface(
      onTap: () => unawaited(onOpenPressed()),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 142),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
            child: _RecommendationCardContent(
              rank: rank,
              mode: mode,
              topic: topic,
              latestNode: latestNode,
              following: following,
              followLoading: followLoading,
              showRank: showRank,
              onToggleFollow: onToggleFollow,
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationCardContent extends StatelessWidget {
  const _RecommendationCardContent({
    required this.rank,
    required this.mode,
    required this.topic,
    required this.latestNode,
    required this.following,
    required this.followLoading,
    required this.showRank,
    required this.onToggleFollow,
  });

  final int rank;
  final RecommendationMode mode;
  final Topic topic;
  final _RecommendationLatestNode latestNode;
  final bool following;
  final bool followLoading;
  final bool showRank;
  final Future<void> Function() onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 42,
              child: _RecommendationBadge(
                topic: topic,
                mode: mode,
                rank: rank,
                showRank: showRank,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 42,
              child: _RecommendationNodeTime(label: latestNode.timeLabel),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RecommendationNodePreviewBar(
                text: latestNode.summary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 56),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${topic.followerCount} 人关注',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              _FollowedTag(
                loading: followLoading,
                following: following,
                onPressed:
                    followLoading ? null : () => unawaited(onToggleFollow()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecommendationNodeTime extends StatelessWidget {
  const _RecommendationNodeTime({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: label.contains('\n') ? 30 : 22,
      child: Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Align(
          alignment: Alignment.topCenter,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accentStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowedTag extends StatelessWidget {
  const _FollowedTag({
    required this.loading,
    required this.following,
    required this.onPressed,
  });

  final bool loading;
  final bool following;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final background = following ? AppTheme.accentSoft : AppTheme.surface;
    final foreground =
        following ? AppTheme.accentStrong : AppTheme.textSecondary;
    final border =
        following ? AppTheme.accent.withValues(alpha: 0.34) : AppTheme.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(color: border),
          ),
          child: loading
              ? const SizedBox.square(
                  dimension: 11,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  following ? '已关注' : '未关注',
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: foreground,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                ),
        ),
      ),
    );
  }
}

class _RecommendationsModeBar extends StatelessWidget {
  const _RecommendationsModeBar({
    required this.mode,
    required this.onShowPersonalized,
    required this.onShowHot,
    required this.onShowExplore,
    required this.onShowHistory,
  });

  final RecommendationMode mode;
  final VoidCallback onShowPersonalized;
  final VoidCallback onShowHot;
  final VoidCallback onShowExplore;
  final VoidCallback onShowHistory;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.58)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _HeroModeButton(
              label: '可能关心',
              icon: Icons.auto_awesome_rounded,
              selected: mode == RecommendationMode.personalized,
              onPressed: onShowPersonalized,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _HeroModeButton(
              label: '当前热门',
              icon: Icons.trending_up_rounded,
              selected: mode == RecommendationMode.hot,
              onPressed: onShowHot,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _HeroModeButton(
              label: '探索惊喜',
              icon: Icons.explore_rounded,
              selected: mode == RecommendationMode.explore,
              onPressed: onShowExplore,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _HeroModeButton(
              label: '历史记录',
              icon: Icons.history_rounded,
              selected: mode == RecommendationMode.history,
              onPressed: onShowHistory,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroModeButton extends StatelessWidget {
  const _HeroModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final contentColor =
        selected ? AppTheme.accentStrong : AppTheme.textSecondary;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(11),
        child: Ink(
          height: 32,
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.accentSoft.withValues(alpha: 0.72)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected
                  ? AppTheme.accent.withValues(alpha: 0.10)
                  : Colors.transparent,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 13, color: contentColor),
                  const SizedBox(width: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: contentColor,
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          height: 1,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationBadge extends StatelessWidget {
  const _RecommendationBadge({
    required this.topic,
    required this.mode,
    required this.rank,
    required this.showRank,
  });

  final Topic topic;
  final RecommendationMode mode;
  final int rank;
  final bool showRank;

  @override
  Widget build(BuildContext context) {
    final iconStyle = TopicIconResolver.resolve(topic);

    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        AppTopicIconBadge(
          icon: iconStyle.icon,
          backgroundColor: iconStyle.backgroundColor,
          iconColor: iconStyle.foregroundColor,
          borderColor: iconStyle.borderColor,
          size: 36,
          iconSize: 18,
          radius: AppTheme.radiusControl,
        ),
        if (showRank && rank <= 9)
          Positioned(
            left: -2,
            top: -2,
            child: Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(color: iconStyle.borderColor),
              ),
              child: Text(
                '$rank',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: iconStyle.foregroundColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RecommendationNodePreviewBar extends StatelessWidget {
  const _RecommendationNodePreviewBar({required this.text});

  final String text;

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
            Container(width: 3, color: AppTheme.accent),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 6, 8, 7),
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary,
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
