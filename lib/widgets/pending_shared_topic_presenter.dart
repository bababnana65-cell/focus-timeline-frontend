import 'package:flutter/material.dart';

import '../services/shared_topic_flow_service.dart';
import '../theme/app_theme.dart';
import 'app_action_buttons.dart';

class PendingSharedTopicPresenter extends StatefulWidget {
  const PendingSharedTopicPresenter({
    super.key,
    required this.preview,
    required this.previewToken,
    required this.onResolve,
    required this.onDismiss,
    required this.onNavigateTimeline,
  });

  final SharedTopicPreview? preview;
  final int previewToken;
  final Future<void> Function(bool follow) onResolve;
  final Future<void> Function() onDismiss;
  final Future<void> Function() onNavigateTimeline;

  @override
  State<PendingSharedTopicPresenter> createState() => _PendingSharedTopicPresenterState();
}

class _PendingSharedTopicPresenterState extends State<PendingSharedTopicPresenter> {
  int _lastPresentedToken = 0;
  bool _isShowing = false;

  @override
  void initState() {
    super.initState();
    _scheduleIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PendingSharedTopicPresenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  void _scheduleIfNeeded() {
    final preview = widget.preview;
    if (_isShowing || preview == null || widget.previewToken == _lastPresentedToken) {
      return;
    }

    _lastPresentedToken = widget.previewToken;
    _isShowing = true;
    final shownToken = widget.previewToken;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _isShowing = false;
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        builder: (context) {
          return _SharedTopicSheet(
            preview: preview,
            onOpen: () async {
              Navigator.of(context).pop();
              await widget.onResolve(false);
              if (!mounted) {
                return;
              }
              await widget.onNavigateTimeline();
            },
            onFollow: preview.alreadyFollowing
                    || !preview.allowFollow
                ? null
                : () async {
                    Navigator.of(context).pop();
                    await widget.onResolve(true);
                    if (!mounted) {
                      return;
                    }
                    await widget.onNavigateTimeline();
                  },
          );
        },
      );

      _isShowing = false;
      if (!mounted) {
        return;
      }
      if (widget.previewToken == shownToken && widget.preview != null) {
        await widget.onDismiss();
      }
    });
  }
}

class _SharedTopicSheet extends StatelessWidget {
  const _SharedTopicSheet({
    required this.preview,
    required this.onOpen,
    required this.onFollow,
  });

  final SharedTopicPreview preview;
  final Future<void> Function() onOpen;
  final Future<void> Function()? onFollow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '收到分享时间线',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            preview.topic.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            preview.topic.tagline,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  preview.fromImportedPayload
                      ? Icons.file_download_done_rounded
                      : Icons.link_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    preview.alreadyFollowing
                        ? '这条时间线已经在你的关注里，可以直接查看。'
                        : '打开后可先看时间线，再决定是否关注。',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (onFollow == null)
            SizedBox(
              width: double.infinity,
              child: AppActionButton(
                label: preview.alreadyFollowing ? '查看时间轴' : '仅查看',
                onPressed: onOpen,
                variant: AppActionButtonVariant.outlined,
              ),
            )
          else
            AppActionPair(
              secondaryLabel: preview.alreadyFollowing ? '查看时间轴' : '仅查看',
              secondaryOnPressed: onOpen,
              primaryLabel: '关注并查看',
              primaryOnPressed: onFollow,
            ),
        ],
      ),
    );
  }
}
