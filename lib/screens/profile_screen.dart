import 'dart:async';

import 'package:flutter/material.dart';

import '../models/interest_category.dart';
import '../models/timeline_models.dart';
import '../services/source_article_service.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_topic_card_parts.dart';
import '../widgets/timeline_signal_resolver.dart';
import '../widgets/topic_icon_resolver.dart';
import 'source_article_screen.dart';
import 'timeline_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
    required this.onOpenLogin,
  });

  final TimelineController controller;
  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.isRegistered) {
          return _GuestProfileView(onOpenLogin: onOpenLogin);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pageHorizontalPadding,
            18,
            AppTheme.pageHorizontalPadding,
            120,
          ),
          children: <Widget>[
            _ProfileHeader(controller: controller),
            const SizedBox(height: 16),
            _ProfileActionGrid(controller: controller),
          ],
        );
      },
    );
  }
}

enum _ProfileTopicListKind {
  following,
  history,
}

class _ProfileTopicListScreen extends StatelessWidget {
  const _ProfileTopicListScreen({
    required this.controller,
    required this.kind,
  });

  final TimelineController controller;
  final _ProfileTopicListKind kind;

  String get title => switch (kind) {
        _ProfileTopicListKind.following => '关注列表',
        _ProfileTopicListKind.history => '历史列表',
      };

  IconData get emptyIcon => switch (kind) {
        _ProfileTopicListKind.following => Icons.bookmark_add_outlined,
        _ProfileTopicListKind.history => Icons.history_toggle_off_rounded,
      };

  String get emptyTitle => switch (kind) {
        _ProfileTopicListKind.following => '还没有关注专题',
        _ProfileTopicListKind.history => '还没有浏览历史',
      };

  String get emptyDetail => switch (kind) {
        _ProfileTopicListKind.following => '关注专题后，会在这里集中管理。',
        _ProfileTopicListKind.history => '打开过的专题会出现在这里，方便继续阅读。',
      };

  bool get allowUnfollow => kind == _ProfileTopicListKind.following;

  List<Topic> _topicsForController(TimelineController controller) {
    return switch (kind) {
      _ProfileTopicListKind.following => List<Topic>.from(
          controller.trackedTopics,
        ),
      _ProfileTopicListKind.history => List<Topic>.from(
          controller.historyTopics,
        ),
    };
  }

  Future<void> _openTopicTimeline(BuildContext context, Topic topic) async {
    await controller.openTopicById(
      topic.id,
      requestShellNavigation: false,
    );
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => Scaffold(
          body: TimelineScreen(
            controller: controller,
            onSwipeBack: () async {},
            onSwipeForward: () async {},
            onClose: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndUnfollow(
    BuildContext context,
    Topic topic,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: '确认取消关注',
      message: '取消关注后，「${topic.name}」将不再出现在关注列表。是否继续？',
      confirmLabel: '取消关注',
      destructive: true,
    );
    if (!confirmed || !context.mounted) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppTheme.followingBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final topics = _topicsForController(controller);
          final showQuota = kind == _ProfileTopicListKind.following;
          if (topics.isEmpty) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pageHorizontalPadding,
                18,
                AppTheme.pageHorizontalPadding,
                120,
              ),
              children: <Widget>[
                if (showQuota) ...<Widget>[
                  _FollowQuotaSummaryCard(controller: controller),
                  const SizedBox(height: AppTheme.cardVerticalGap),
                ],
                AppEmptyStateCard(
                  icon: emptyIcon,
                  title: emptyTitle,
                  detail: emptyDetail,
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pageHorizontalPadding,
              18,
              AppTheme.pageHorizontalPadding,
              120,
            ),
            itemCount: topics.length + (showQuota ? 1 : 0),
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppTheme.cardVerticalGap),
            itemBuilder: (context, index) {
              if (showQuota && index == 0) {
                return _FollowQuotaSummaryCard(controller: controller);
              }
              final topic = topics[index - (showQuota ? 1 : 0)];
              return _ProfileTopicListCard(
                topic: topic,
                latestSummary: controller.topicLatestRelevantEventSummary(
                  topic.id,
                ),
                onOpen: () => _openTopicTimeline(context, topic),
                onUnfollow: allowUnfollow
                    ? () => _confirmAndUnfollow(context, topic)
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _FollowQuotaSummaryCard extends StatelessWidget {
  const _FollowQuotaSummaryCard({required this.controller});

  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    final followCount = controller.trackedTopics.length;
    final followLimit = controller.effectiveFollowLimit;
    final remaining = (followLimit - followCount).clamp(0, followLimit);
    final progress =
        followLimit <= 0 ? 0.0 : (followCount / followLimit).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentSoft.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.bookmark_rounded,
              color: AppTheme.accentStrong,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      '关注额度',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      '$followCount / $followLimit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.accentStrong,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: AppTheme.surface,
                    color: AppTheme.accentStrong,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '还可关注 $remaining 个专题，取消关注后额度会释放。',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.2,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTopicListCard extends StatelessWidget {
  const _ProfileTopicListCard({
    required this.topic,
    required this.latestSummary,
    required this.onOpen,
    this.onUnfollow,
  });

  final Topic topic;
  final String? latestSummary;
  final Future<void> Function() onOpen;
  final Future<void> Function()? onUnfollow;

  @override
  Widget build(BuildContext context) {
    final iconStyle = TopicIconResolver.resolve(topic);
    final trimmedLatest = latestSummary?.trim();
    final secondaryText = trimmedLatest == null || trimmedLatest.isEmpty
        ? topic.tagline
        : trimmedLatest;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppTopicIconBadge(
            icon: iconStyle.icon,
            backgroundColor: iconStyle.backgroundColor,
            iconColor: iconStyle.foregroundColor,
            borderColor: iconStyle.borderColor,
            size: 34,
            iconSize: 18,
            radius: 10,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                InkWell(
                  key: ValueKey<String>('profile-topic-open-${topic.id}'),
                  onTap: () => unawaited(onOpen()),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1, bottom: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            topic.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 15,
                                  height: 1.25,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 13,
                          color: AppTheme.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  secondaryText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.38,
                      ),
                ),
                const SizedBox(height: 9),
                AppTopicMetaItem(
                  icon: Icons.group_outlined,
                  text: '${topic.followerCount} 人关注',
                  fontSize: 11.5,
                  textColor: AppTheme.textTertiary,
                ),
              ],
            ),
          ),
          if (onUnfollow != null) ...<Widget>[
            const SizedBox(width: 8),
            IconButton(
              key: ValueKey<String>('profile-topic-unfollow-${topic.id}'),
              onPressed: () => unawaited(onUnfollow!()),
              icon: const Icon(Icons.bookmark_remove_outlined),
              color: AppTheme.textSecondary,
              tooltip: '取消关注',
              constraints: const BoxConstraints.tightFor(
                width: 40,
                height: 40,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InterestCategoryScreen extends StatefulWidget {
  const _InterestCategoryScreen({required this.controller});

  final TimelineController controller;

  @override
  State<_InterestCategoryScreen> createState() =>
      _InterestCategoryScreenState();
}

class _InterestCategoryScreenState extends State<_InterestCategoryScreen> {
  late final Set<String> _selectedCategoryIds;

  @override
  void initState() {
    super.initState();
    _selectedCategoryIds = widget.controller.userInterestCategoryIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      appBar: AppBar(
        title: const Text('兴趣类别'),
        backgroundColor: AppTheme.followingBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pageHorizontalPadding,
              18,
              AppTheme.pageHorizontalPadding,
              120,
            ),
            children: <Widget>[
              const _ProfilePageIntroCard(
                icon: Icons.tune_rounded,
                title: '选择你关心的事件类别',
                detail: '用于优化推荐和推送内容。可以随时回来调整。',
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Wrap(
                  spacing: 9,
                  runSpacing: 10,
                  children: <Widget>[
                    for (final category in interestCategories)
                      FilterChip(
                        key: ValueKey<String>(
                          'profile-interest-${category.id}',
                        ),
                        selected: _selectedCategoryIds.contains(category.id),
                        showCheckmark: false,
                        avatar: Icon(
                          _interestCategoryIcon(category.id),
                          size: 16,
                          color: _selectedCategoryIds.contains(category.id)
                              ? AppTheme.accentStrong
                              : AppTheme.textSecondary,
                        ),
                        label: Text(category.label),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                        },
                        selectedColor: AppTheme.accentSoft,
                        backgroundColor: AppTheme.backgroundRaised,
                        side: BorderSide(
                          color: _selectedCategoryIds.contains(category.id)
                              ? AppTheme.accent.withValues(alpha: 0.36)
                              : AppTheme.border,
                        ),
                        labelStyle:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: widget.controller.isSavingUserInterests
                    ? null
                    : () => unawaited(_save(context)),
                child: Text(
                  widget.controller.isSavingUserInterests ? '保存中' : '保存',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    try {
      await widget.controller.saveUserInterestCategoryIds(
        _selectedCategoryIds.toList(growable: false),
      );
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        '兴趣已保存',
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        '保存失败：$error',
        tone: AppSnackBarTone.error,
      );
    }
  }
}

class _FeedbackScreen extends StatefulWidget {
  const _FeedbackScreen({required this.controller});

  final TimelineController controller;

  @override
  State<_FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<_FeedbackScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      appBar: AppBar(
        title: const Text('反馈'),
        backgroundColor: AppTheme.followingBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pageHorizontalPadding,
              18,
              AppTheme.pageHorizontalPadding,
              120,
            ),
            children: <Widget>[
              const _ProfilePageIntroCard(
                icon: Icons.feedback_outlined,
                title: '问题和建议',
                detail: '描述你遇到的问题，或希望改进的地方。',
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey<String>('profile-feedback-input'),
                controller: _textController,
                minLines: 6,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: '写下你的反馈',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: widget.controller.isSubmittingProfileFeedback
                    ? null
                    : () => unawaited(_submit(context)),
                child: Text(
                  widget.controller.isSubmittingProfileFeedback ? '提交中' : '提交',
                ),
              ),
              const SizedBox(height: 16),
              const _FeedbackRecordsSection(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    try {
      await widget.controller.submitProfileFeedback(
        message: _textController.text,
      );
      _textController.clear();
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        '反馈已提交',
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showAppSnackBar(
        context,
        '提交失败：$error',
        tone: AppSnackBarTone.error,
      );
    }
  }
}

class _FeedbackRecordsSection extends StatelessWidget {
  const _FeedbackRecordsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.receipt_long_outlined,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '我的反馈记录',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: AppTheme.backgroundRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text(
              '暂无反馈记录',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderSettingsScreen extends StatefulWidget {
  const _ReminderSettingsScreen({required this.controller});

  final TimelineController controller;

  @override
  State<_ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<_ReminderSettingsScreen> {
  late RecentUpdateReminderMode _mode;

  @override
  void initState() {
    super.initState();
    _mode = widget.controller.recentUpdateReminderMode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      appBar: AppBar(
        title: const Text('提醒设置'),
        backgroundColor: AppTheme.followingBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pageHorizontalPadding,
          18,
          AppTheme.pageHorizontalPadding,
          120,
        ),
        children: <Widget>[
          const _ProfilePageIntroCard(
            icon: Icons.notifications_none_rounded,
            title: '新进展提醒',
            detail: '管理新进展和重大节点的提醒强度。',
          ),
          const SizedBox(height: 14),
          _ReminderModeSection(
            selectedMode: _mode,
            onChanged: _setMode,
          ),
        ],
      ),
    );
  }

  void _setMode(RecentUpdateReminderMode mode) {
    setState(() => _mode = mode);
    widget.controller.setRecentUpdateReminderMode(mode);
  }
}

class _ReminderModeSection extends StatelessWidget {
  const _ReminderModeSection({
    required this.selectedMode,
    required this.onChanged,
  });

  final RecentUpdateReminderMode selectedMode;
  final ValueChanged<RecentUpdateReminderMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '提醒强度',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          _ReminderRadioTile(
            icon: Icons.notifications_off_outlined,
            title: '关闭',
            selected: selectedMode == RecentUpdateReminderMode.off,
            onTap: () => onChanged(RecentUpdateReminderMode.off),
          ),
          const SizedBox(height: 8),
          _ReminderRadioTile(
            icon: Icons.priority_high_rounded,
            title: '重大节点提醒',
            selected: selectedMode == RecentUpdateReminderMode.majorOnly,
            onTap: () => onChanged(RecentUpdateReminderMode.majorOnly),
          ),
          const SizedBox(height: 8),
          _ReminderRadioTile(
            icon: Icons.notifications_active_outlined,
            title: '全部新进展提醒',
            selected: selectedMode == RecentUpdateReminderMode.all,
            onTap: () => onChanged(RecentUpdateReminderMode.all),
          ),
        ],
      ),
    );
  }
}

class _ReminderRadioTile extends StatelessWidget {
  const _ReminderRadioTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accentStrong : AppTheme.textSecondary;
    return Material(
      color: selected ? AppTheme.accentSoft : AppTheme.backgroundRaised,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppTheme.accent.withValues(alpha: 0.28)
                  : AppTheme.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: selected
                            ? AppTheme.accentStrong
                            : AppTheme.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShareRecordsScreen extends StatelessWidget {
  const _ShareRecordsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      appBar: AppBar(
        title: const Text('分享记录'),
        backgroundColor: AppTheme.followingBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: const Padding(
        padding: EdgeInsets.fromLTRB(
          AppTheme.pageHorizontalPadding,
          18,
          AppTheme.pageHorizontalPadding,
          120,
        ),
        child: AppEmptyStateCard(
          icon: Icons.ios_share_outlined,
          title: '暂无分享记录',
          detail: '分享过的专题会在这里集中管理。',
        ),
      ),
    );
  }
}

class _ProfilePageIntroCard extends StatelessWidget {
  const _ProfilePageIntroCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: <Widget>[
          AppTopicIconBadge(
            icon: icon,
            backgroundColor: AppTheme.accentSoft,
            iconColor: AppTheme.accentStrong,
            borderColor: AppTheme.accent.withValues(alpha: 0.20),
            size: 38,
            iconSize: 20,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _interestCategoryIcon(String id) {
  return switch (id) {
    'politics' => Icons.account_balance_rounded,
    'military' => Icons.shield_outlined,
    'history' => Icons.history_edu_rounded,
    'economy' => Icons.trending_up_rounded,
    'finance' => Icons.payments_outlined,
    'technology' => Icons.memory_rounded,
    'society' => Icons.groups_rounded,
    'international' => Icons.public_rounded,
    'enterprise' => Icons.business_center_outlined,
    'health' => Icons.medical_services_outlined,
    'climate' => Icons.eco_outlined,
    'culture' => Icons.palette_outlined,
    _ => Icons.category_outlined,
  };
}

class FavoriteNodesScreen extends StatelessWidget {
  const FavoriteNodesScreen({
    super.key,
    required this.controller,
  });

  final TimelineController controller;

  Future<void> _openTopicTimeline(
    BuildContext context,
    FavoriteTimelineNode node,
  ) async {
    await controller.openTopicById(
      node.topicId,
      requestShellNavigation: false,
    );
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => Scaffold(
          body: TimelineScreen(
            controller: controller,
            onSwipeBack: () async {},
            onSwipeForward: () async {},
            onClose: () => Navigator.of(routeContext).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      appBar: AppBar(
        title: const Text('收藏节点'),
        backgroundColor: AppTheme.followingBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final nodes = controller.favoriteTimelineNodes;
          if (nodes.isEmpty) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.pageHorizontalPadding,
                18,
                AppTheme.pageHorizontalPadding,
                120,
              ),
              child: AppEmptyStateCard(
                icon: Icons.star_border_rounded,
                title: '暂无收藏节点',
                detail: '在时间轴节点右上角点击收藏后，会在这里统一查看。',
              ),
            );
          }

          final topicCount = nodes.map((node) => node.topicId).toSet().length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pageHorizontalPadding,
              18,
              AppTheme.pageHorizontalPadding,
              120,
            ),
            children: <Widget>[
              _FavoriteNodesOverview(
                nodeCount: nodes.length,
                topicCount: topicCount,
              ),
              const SizedBox(height: 12),
              _FavoriteNodesManagementPanel(
                topicCount: topicCount,
              ),
              const SizedBox(height: 14),
              ...nodes.map(
                (node) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppTheme.cardVerticalGap,
                  ),
                  child: FavoriteNodeCard(
                    node: node,
                    onOpenTopic: () => _openTopicTimeline(context, node),
                    onRemove: () async {
                      await controller.removeFavoriteTimelineNode(node.id);
                      if (!context.mounted) {
                        return;
                      }
                      showAppSnackBar(
                        context,
                        '已取消收藏',
                        tone: AppSnackBarTone.info,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FavoriteNodesOverview extends StatelessWidget {
  const _FavoriteNodesOverview({
    required this.nodeCount,
    required this.topicCount,
  });

  final int nodeCount;
  final int topicCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.star_rounded,
            size: 18,
            color: AppTheme.highlight,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$nodeCount 个收藏节点，来自 $topicCount 个专题',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteNodesManagementPanel extends StatelessWidget {
  const _FavoriteNodesManagementPanel({required this.topicCount});

  final int topicCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '收藏管理',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              const _ProfileManagementPill(
                label: '全部专题',
                icon: Icons.folder_open_outlined,
              ),
              const _ProfileManagementPill(
                label: '最新收藏优先',
                icon: Icons.south_rounded,
              ),
              _ProfileManagementPill(
                label: '$topicCount 个专题',
                icon: Icons.bookmark_border_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileManagementPill extends StatelessWidget {
  const _ProfileManagementPill({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.backgroundRaised,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class FavoriteNodeCard extends StatefulWidget {
  const FavoriteNodeCard({
    super.key,
    required this.node,
    required this.onRemove,
    this.onOpenTopic,
  });

  final FavoriteTimelineNode node;
  final Future<void> Function() onRemove;
  final Future<void> Function()? onOpenTopic;

  @override
  State<FavoriteNodeCard> createState() => _FavoriteNodeCardState();
}

class _FavoriteNodeCardState extends State<FavoriteNodeCard> {
  static const SourceArticleService _sourceArticleService =
      SourceArticleService();
  static const Color _selectedStarColor = AppTheme.highlight;

  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final dateLabel = formatTimelineHeaderDateLabel(
      node.timestamp,
      bucketLabel: node.label,
      relativeRecent: true,
    );
    final tone =
        node.isMajor ? AppTheme.highlightStrong : AppTheme.accentStrong;
    final entry = _entryForNode(node);
    final signalStyle = TimelineSignalResolver.resolve(
      TimelineBucket(
        id: node.bucketKey,
        periodStart: node.bucketStart,
        granularity: node.bucketGranularity,
        entries: <TimelineEntry>[entry],
        label: node.label,
        headline: node.headline,
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: () {
          setState(() => expanded = !expanded);
        },
        child: Ink(
          padding: const EdgeInsets.fromLTRB(15, 13, 10, 13),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: AppTheme.shadow,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _FavoriteTopicLink(
                      label: node.topicName,
                      onTap: widget.onOpenTopic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      unawaited(_confirmAndRemove(context));
                    },
                    icon: const Icon(Icons.star_rounded),
                    color: _selectedStarColor,
                    tooltip: '取消收藏',
                    constraints: const BoxConstraints.tightFor(
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _FavoriteDateChip(
                    dateLabel,
                    tone: tone,
                  ),
                  if (node.primarySignal != null)
                    _FavoriteSignalChip(style: signalStyle),
                ],
              ),
              const SizedBox(height: 7),
              Text(
                node.headline,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      height: 1.28,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                node.summary,
                maxLines: expanded ? 3 : 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
              ),
              if (expanded) ...<Widget>[
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.border),
                const SizedBox(height: 12),
                _FavoriteNodeEntryDetail(
                  entry: entry,
                  onReadSource: () => _openSourceLink(context, entry),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认取消收藏'),
        content: const Text('取消后，这张时间轴卡片将从收藏节点中移除。'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('保留'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('取消收藏'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    await widget.onRemove();
  }

  TimelineEntry _entryForNode(FavoriteTimelineNode node) {
    return TimelineEntry(
      id: node.id,
      topicId: node.topicId,
      title: node.headline,
      summary: node.summary,
      detail: node.summary,
      fullText: node.summary,
      sourceName: node.topicName,
      timestamp: node.timestamp,
      isMajor: node.isMajor,
      primarySignal: node.primarySignal,
    );
  }

  Future<void> _openSourceLink(
    BuildContext context,
    TimelineEntry entry,
  ) async {
    final request = _sourceArticleService.createRequest(entry);
    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SourceArticleScreen(
          entry: entry,
          request: request,
        ),
      ),
    );
  }
}

class _FavoriteTopicLink extends StatelessWidget {
  const _FavoriteTopicLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () => unawaited(onTap!()),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.open_in_new_rounded,
              size: 12,
              color: AppTheme.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteDateChip extends StatelessWidget {
  const _FavoriteDateChip(
    this.label, {
    required this.tone,
  });

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final major = tone == AppTheme.highlightStrong;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: major ? AppTheme.highlightSoft : AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: major
              ? AppTheme.highlight.withValues(alpha: 0.20)
              : AppTheme.accent.withValues(alpha: 0.44),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tone,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

class _FavoriteSignalChip extends StatelessWidget {
  const _FavoriteSignalChip({required this.style});

  final TimelineSignalStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: style.backgroundColor.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(style.icon, size: 10.5, color: style.foregroundColor),
          const SizedBox(width: 3),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteNodeEntryDetail extends StatelessWidget {
  const _FavoriteNodeEntryDetail({
    required this.entry,
    required this.onReadSource,
  });

  final TimelineEntry entry;
  final VoidCallback onReadSource;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            entry.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onReadSource,
              icon: const Icon(Icons.open_in_new_rounded, size: 15),
              label: const Text('阅读原文'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView({required this.onOpenLogin});

  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pageHorizontalPadding,
        36,
        AppTheme.pageHorizontalPadding,
        120,
      ),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.textSecondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          '未登录',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '登录后同步关注、历史和创建专题。',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onOpenLogin,
                  icon: const Icon(Icons.phone_iphone_rounded),
                  label: const Text('手机号验证'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller});

  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.accentSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.22)),
          ),
          child: const Icon(
            Icons.person_rounded,
            color: AppTheme.accentStrong,
            size: 30,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '我的',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                controller.maskedPhoneNumber ?? '已登录账号',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            unawaited(controller.logout());
          },
          icon: const Icon(Icons.logout_rounded),
          color: AppTheme.textSecondary,
          tooltip: '退出登录',
        ),
      ],
    );
  }
}

class _ProfileActionGrid extends StatelessWidget {
  const _ProfileActionGrid({required this.controller});

  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    final contentActions = <_ProfileAction>[
      _ProfileAction(
        key: const ValueKey<String>('profile-action-following'),
        icon: Icons.bookmark_rounded,
        label: '关注',
        detail: '${controller.trackedTopics.length} 个专题',
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _ProfileTopicListScreen(
                controller: controller,
                kind: _ProfileTopicListKind.following,
              ),
            ),
          );
        },
      ),
      _ProfileAction(
        key: const ValueKey<String>('profile-action-favorites'),
        icon: Icons.star_border_rounded,
        label: '收藏',
        detail: '${controller.favoriteTimelineNodes.length} 个节点',
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => FavoriteNodesScreen(controller: controller),
            ),
          );
        },
      ),
      _ProfileAction(
        key: const ValueKey<String>('profile-action-history'),
        icon: Icons.history_rounded,
        label: '历史',
        detail: '${controller.historyTopics.length} 个专题',
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _ProfileTopicListScreen(
                controller: controller,
                kind: _ProfileTopicListKind.history,
              ),
            ),
          );
        },
      ),
      _ProfileAction(
        key: const ValueKey<String>('profile-action-share-records'),
        icon: Icons.ios_share_outlined,
        label: '分享',
        detail: '记录',
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const _ShareRecordsScreen(),
            ),
          );
        },
      ),
    ];

    final settingActions = <_ProfileAction>[
      _ProfileAction(
        key: const ValueKey<String>('profile-action-reminder-settings'),
        icon: Icons.notifications_none_rounded,
        label: '提醒',
        detail: _reminderModeActionDetail(controller.recentUpdateReminderMode),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _ReminderSettingsScreen(controller: controller),
            ),
          );
        },
      ),
      _ProfileAction(
        key: const ValueKey<String>('profile-action-interests'),
        icon: Icons.tune_rounded,
        label: '兴趣',
        detail: controller.userInterestCategoryIds.isEmpty
            ? '选择事件类别'
            : '${controller.userInterestCategoryIds.length} 个类别',
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _InterestCategoryScreen(controller: controller),
            ),
          );
        },
      ),
      _ProfileAction(
        key: const ValueKey<String>('profile-action-feedback'),
        icon: Icons.feedback_outlined,
        label: '反馈',
        detail: '问题与建议',
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _FeedbackScreen(controller: controller),
            ),
          );
        },
      ),
      _ProfileAction(
        key: const ValueKey<String>('profile-action-membership'),
        icon: Icons.workspace_premium_outlined,
        label: '会员',
        detail: '更多额度',
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _MembershipScreen(controller: controller),
            ),
          );
        },
      ),
    ];

    return Column(
      children: <Widget>[
        _ProfileActionSection(
          key: const ValueKey<String>('profile-section-content-management'),
          title: '内容管理',
          actions: contentActions,
        ),
        const SizedBox(height: 12),
        _ProfileActionSection(
          key: const ValueKey<String>('profile-section-preferences'),
          title: '偏好设置',
          actions: settingActions,
        ),
      ],
    );
  }
}

String _reminderModeActionDetail(RecentUpdateReminderMode mode) {
  return switch (mode) {
    RecentUpdateReminderMode.off => '已关闭',
    RecentUpdateReminderMode.majorOnly => '重大节点',
    RecentUpdateReminderMode.all => '全部进展',
  };
}

class _ProfileActionSection extends StatelessWidget {
  const _ProfileActionSection({
    super.key,
    required this.title,
    required this.actions,
  });

  final String title;
  final List<_ProfileAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textTertiary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final action in actions)
                    SizedBox(
                      width: itemWidth,
                      height: 70,
                      child: _ProfileActionCell(action: action),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileActionCell extends StatelessWidget {
  const _ProfileActionCell({required this.action});

  final _ProfileAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: action.key,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: action.onTap ??
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${action.label}功能准备中'),
                  duration: const Duration(milliseconds: 1200),
                ),
              );
            },
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: AppTheme.backgroundRaised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Icon(
                  action.icon,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiary,
                            fontSize: 11,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipScreen extends StatelessWidget {
  const _MembershipScreen({required this.controller});

  final TimelineController controller;

  @override
  Widget build(BuildContext context) {
    final capabilities = controller.capabilities;
    final accountTier = capabilities?.accountTier ?? 'free';
    final isPro = accountTier == 'pro';
    final tierLabel = isPro ? 'Pro 会员' : '免费版';
    final followCount = controller.trackedTopics.length;
    final followLimit = controller.effectiveFollowLimit;
    final remaining = (followLimit - followCount).clamp(0, followLimit);
    final progress =
        followLimit <= 0 ? 0.0 : (followCount / followLimit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      appBar: AppBar(
        title: const Text('会员权益'),
        backgroundColor: AppTheme.followingBackground,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pageHorizontalPadding,
          18,
          AppTheme.pageHorizontalPadding,
          120,
        ),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.border),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: AppTheme.shadow,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.accentSoft,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_rounded,
                        color: AppTheme.accentStrong,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '当前版本',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tierLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  height: 1.15,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MembershipQuotaRow(
                  title: '关注额度',
                  value: '$followCount / $followLimit',
                  detail: '剩余 $remaining 个专题',
                  progress: progress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const _MembershipBenefitSection(
            title: 'Pro 适合高频追踪',
            benefits: <_MembershipBenefit>[
              _MembershipBenefit(
                icon: Icons.bookmark_add_outlined,
                title: '更多关注额度',
                detail: '把长期关注的专题留在列表里，不必频繁取舍。',
              ),
              _MembershipBenefit(
                icon: Icons.auto_fix_high_rounded,
                title: '更多 AI 扩写',
                detail: '用于创建专题时补全关键词、类别和事件起点。',
              ),
              _MembershipBenefit(
                icon: Icons.manage_search_rounded,
                title: '收藏检索',
                detail: '后续可按专题、类别、时间快速回看收藏节点。',
              ),
              _MembershipBenefit(
                icon: Icons.notifications_active_outlined,
                title: '重点提醒',
                detail: '后续支持重大节点和新进展的精细提醒。',
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              showAppSnackBar(
                context,
                '支付暂未接入',
                tone: AppSnackBarTone.info,
              );
            },
            icon: const Icon(Icons.workspace_premium_rounded),
            label: Text(isPro ? '已是 Pro 会员' : '升级 Pro'),
          ),
          const SizedBox(height: 10),
          Text(
            '当前阶段只展示会员权益和能力模型。支付接入后，会通过平台内购或订阅完成购买和恢复。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}

class _MembershipQuotaRow extends StatelessWidget {
  const _MembershipQuotaRow({
    required this.title,
    required this.value,
    required this.detail,
    required this.progress,
  });

  final String title;
  final String value;
  final String detail;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.accentStrong,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppTheme.surfaceMuted,
            color: AppTheme.accentStrong,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          detail,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _MembershipBenefit {
  const _MembershipBenefit({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;
}

class _MembershipBenefitSection extends StatelessWidget {
  const _MembershipBenefitSection({
    required this.title,
    required this.benefits,
  });

  final String title;
  final List<_MembershipBenefit> benefits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
          ),
          const SizedBox(height: 12),
          for (final benefit in benefits) ...<Widget>[
            _MembershipBenefitTile(benefit: benefit),
            if (benefit != benefits.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _MembershipBenefitTile extends StatelessWidget {
  const _MembershipBenefitTile({required this.benefit});

  final _MembershipBenefit benefit;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.backgroundRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Icon(
            benefit.icon,
            size: 18,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                benefit.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                benefit.detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.35,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAction {
  const _ProfileAction({
    this.key,
    required this.icon,
    required this.label,
    required this.detail,
    this.onTap,
  });

  final Key? key;
  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback? onTap;
}
