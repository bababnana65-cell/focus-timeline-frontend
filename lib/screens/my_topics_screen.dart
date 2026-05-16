import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../dto/topic_timeline_dto.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_empty_state_card.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_topic_card_parts.dart';

class MyTopicsScreen extends StatefulWidget {
  const MyTopicsScreen({
    super.key,
    required this.controller,
    this.onOpenTopic,
  });

  final TimelineController controller;
  final Future<void> Function(String topicId)? onOpenTopic;

  @override
  State<MyTopicsScreen> createState() => _MyTopicsScreenState();
}

class _MyTopicsScreenState extends State<MyTopicsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.loadMyTopics(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final controller = widget.controller;
            final items = controller.ownedTopicItems;
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pageHorizontalPadding,
                    16,
                    AppTheme.pageHorizontalPadding,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          IconButton.filledTonal(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '我的专题',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      AppSectionHeader(
                        eyebrow: '账号专题',
                        title: '我的专题',
                        detail: '查看自己创建的专题、初始化状态以及最近更新时间。初始化失败时可直接重试。',
                        trailingText: '${items.length} 个',
                      ),
                      if (controller.myTopicsRefreshNotice != null) ...<Widget>[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            controller.myTopicsRefreshNotice!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: controller.myTopicsRefreshNoticeIsError
                                      ? AppTheme.danger
                                      : AppTheme.textSecondary,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await controller.refreshMyTopics();
                      if (!context.mounted) {
                        return;
                      }
                      final notice = controller.myTopicsRefreshNotice;
                      if (notice == null || notice.isEmpty) {
                        return;
                      }
                      showAppSnackBar(
                        context,
                        notice,
                        tone: controller.myTopicsRefreshNoticeIsError
                            ? AppSnackBarTone.warning
                            : AppSnackBarTone.success,
                      );
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppTheme.pageHorizontalPadding,
                        0,
                        AppTheme.pageHorizontalPadding,
                        120,
                      ),
                      children: <Widget>[
                        if (controller.isLoadingMyTopics && items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 80),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (controller.session == null)
                          const AppEmptyStateCard(
                            icon: Icons.lock_outline_rounded,
                            title: '登录后查看我的专题',
                            detail: '手机号验证后即可查看自己创建的专题及其初始化状态。',
                          )
                        else if (items.isEmpty)
                          const AppEmptyStateCard(
                            icon: Icons.topic_outlined,
                            title: '还没有创建专题',
                            detail: '去首页右上角创建一个专题，这里会显示它的初始化状态与最近更新时间。',
                          )
                        else
                          ...items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppTheme.cardVerticalGap,
                              ),
                              child: _MyTopicCard(
                                controller: controller,
                                item: item,
                                onOpen: () async {
                                  final openTopic = widget.onOpenTopic ??
                                      controller.openOwnedTopic;
                                  await openTopic(item.topicId);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  Navigator.of(context).maybePop();
                                },
                                onRetry: () async {
                                  try {
                                    await controller
                                        .retryTopicInitialization(item.topicId);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    showAppSnackBar(
                                      context,
                                      '已重新发起初始化',
                                      tone: AppSnackBarTone.success,
                                    );
                                  } catch (error) {
                                    if (!context.mounted) {
                                      return;
                                    }
                                    showAppSnackBar(
                                      context,
                                      '重试初始化失败：$error',
                                      tone: AppSnackBarTone.error,
                                    );
                                  }
                                },
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
      ),
    );
  }
}

class _MyTopicCard extends StatelessWidget {
  const _MyTopicCard({
    required this.controller,
    required this.item,
    required this.onOpen,
    required this.onRetry,
  });

  final TimelineController controller;
  final MyTopicItemDto item;
  final Future<void> Function() onOpen;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _statusLabel(item);
    final statusTone = _statusTone(item);
    final updatedAt = DateFormat('yyyy-MM-dd HH:mm', 'zh_CN')
        .format(item.updatedAt.toLocal());
    final isRetrying =
        controller.isTopicInitializationRetryInFlight(item.topicId);

    return AppTopicCardSurface(
      onTap: () {
        onOpen();
      },
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AppTopicIconBadge(
                  icon: item.canRetry
                      ? Icons.error_outline_rounded
                      : Icons.topic_rounded,
                  backgroundColor: statusTone.$1.withValues(alpha: 0.12),
                  iconColor: statusTone.$1,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AppTopicTitleBlock(
                    title: item.title,
                    subtitle: item.summary,
                  ),
                ),
                const SizedBox(width: 10),
                AppTopicPill(
                  label: statusLabel,
                  backgroundColor: statusTone.$2,
                  foregroundColor: statusTone.$1,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTopicMetaItem(
                    icon: Icons.schedule_rounded,
                    text: '最近更新 $updatedAt',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTopicMetaItem(
                    icon: item.isReadable
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    text: item.isReadable ? '可正常阅读' : '暂不可阅读',
                    textColor: item.isReadable
                        ? AppTheme.accentStrong
                        : AppTheme.textSecondary,
                    iconColor: item.isReadable
                        ? AppTheme.accentStrong
                        : AppTheme.textTertiary,
                  ),
                ),
              ],
            ),
            if (item.canRetry) ...<Widget>[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: isRetrying ? null : () => onRetry(),
                  icon: isRetrying
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(isRetrying ? '重新生成中' : '重新生成'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(MyTopicItemDto item) {
    if (item.status == 'active' && item.initializationState == 'ready') {
      return '可正常阅读';
    }
    if (item.status == 'draft' && item.initializationState == 'failed') {
      return '初始化失败';
    }
    if (item.status == 'draft' && item.initializationState == 'running') {
      return '初始化中';
    }
    return '正在准备中';
  }

  (Color, Color) _statusTone(MyTopicItemDto item) {
    if (item.status == 'active' && item.initializationState == 'ready') {
      return (
        AppTheme.accentStrong,
        AppTheme.accentStrong.withValues(alpha: 0.12)
      );
    }
    if (item.status == 'draft' && item.initializationState == 'failed') {
      return (AppTheme.danger, AppTheme.danger.withValues(alpha: 0.10));
    }
    if (item.status == 'draft' && item.initializationState == 'running') {
      return (AppTheme.highlight, AppTheme.highlight.withValues(alpha: 0.14));
    }
    return (AppTheme.textSecondary, AppTheme.surfaceMuted);
  }
}
