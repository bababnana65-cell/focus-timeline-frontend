import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/timeline_models.dart';
import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import '../widgets/app_notice_banner.dart';
import '../widgets/pending_shared_topic_presenter.dart';
import '../widgets/timeline_quick_actions.dart';
import 'home_feed_screen.dart';
import 'profile_screen.dart';
import 'registration_gate_screen.dart';
import 'timeline_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
  });

  final TimelineController controller;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final PageController _pageController;
  int currentIndex = 0;
  int _handledLoginPromptToken = 0;
  int _handledOpenTopicRequestToken = 0;
  int _timelineAutoExpandRequestToken = 0;
  TimelineAutoExpandRequest? _pendingTimelineAutoExpandRequest;
  bool _presentingLoginPrompt = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.controller.preferredHomeShellIndex == 1 ? 1 : 0;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    _scheduleLoginPromptIfNeeded(controller);
    _scheduleOpenTopicNavigationIfNeeded(controller);

    final pages = <Widget>[
      HomeFeedScreen(
        controller: controller,
        onOpenTopic: _openTrackedTopic,
        onShareTrackedTopic: _shareTopic,
        onToggleTrackedPin: _togglePinTopic,
        onUnfollowTrackedTopic: _unfollowTopic,
      ),
      TimelineScreen(
        controller: controller,
        onSwipeBack: () => _goToPage(0),
        onSwipeForward: () => _goToPage(0),
        autoExpandRequest: _pendingTimelineAutoExpandRequest,
        onAutoExpandRequestConsumed: _clearTimelineAutoExpandRequest,
      ),
      ProfileScreen(
        controller: controller,
        onOpenLogin: _openLoginScreen,
      ),
    ];
    final shellBackground = switch (currentIndex) {
      0 => AppTheme.recommendBackground,
      1 => AppTheme.timelineBackground,
      _ => AppTheme.followingBackground,
    };

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: <Widget>[
          _ShellBackdrop(color: shellBackground),
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                if (controller.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      12,
                      20,
                      0,
                    ),
                    child: AppNoticeBanner(
                      message: controller.errorMessage!,
                      onClose: controller.clearError,
                    ),
                  ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      if (!mounted) {
                        return;
                      }
                      setState(() => currentIndex = index);
                    },
                    children: pages,
                  ),
                ),
                PendingSharedTopicPresenter(
                  preview: controller.pendingSharedTopic,
                  previewToken: controller.pendingSharedTopicToken,
                  onResolve: (follow) =>
                      controller.openPendingSharedTopic(follow: follow),
                  onDismiss: controller.dismissPendingSharedTopic,
                  onNavigateTimeline: () => _goToPage(1),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _ShellBottomNavigation(
        selectedIndex: currentIndex == 2 ? 3 : currentIndex,
        profileLabel: controller.isRegistered ? '我的' : '未登录',
        showTrackedDot: controller.shouldShowTrackedTopicsRecentUpdateDot,
        onDestinationSelected: (index) async {
          if (index == 2) {
            await _openCreateTimelineFromTab();
            return;
          }
          if (index == 3) {
            if (controller.isGuest) {
              await _openLoginScreen();
              return;
            }
            await _goToPage(2);
            return;
          }
          await _goToPage(index);
        },
      ),
    );
  }

  Future<void> _goToPage(int index) async {
    if (index == currentIndex && _pageController.hasClients) {
      return;
    }

    if (!_pageController.hasClients) {
      if (mounted) {
        setState(() => currentIndex = index);
      }
      return;
    }

    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openCreateTimelineFromTab() async {
    final createdTopic = await showTimelineCreateSheet(
      context,
      widget.controller,
      expanded: true,
    );
    if (createdTopic == null) {
      return;
    }
    await widget.controller.selectTopic(createdTopic);
    if (!mounted) {
      return;
    }
    await _goToPage(1);
  }

  Future<void> _openLoginScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _OnDemandRegistrationGate(
          controller: widget.controller,
        ),
      ),
    );
  }

  Future<void> _openTrackedTopic(Topic topic) async {
    final autoExpandRequest = _autoExpandRequestForTrackedTopic(topic);
    await widget.controller.selectTopic(topic);
    if (!mounted) {
      return;
    }
    setState(() {
      _pendingTimelineAutoExpandRequest = autoExpandRequest;
    });
    await _goToPage(1);
  }

  Future<bool> _confirmRemoval(Topic topic) async {
    return showAppConfirmDialog(
      context,
      title: '确认取消关注',
      message: '取消关注后，「${topic.name}」将不再在“我的关注”中显示，但当前专题内容仍会保留。是否继续？',
      confirmLabel: '取消关注',
      destructive: true,
    );
  }

  Future<void> _unfollowTopic(Topic topic) async {
    final shouldRemove = await _confirmRemoval(topic);
    if (!shouldRemove) {
      return;
    }

    await widget.controller.removeTrackedTopic(topic);
    if (!mounted) {
      return;
    }
    showAppSnackBar(
      context,
      '已取消关注「${topic.name}」',
      tone: AppSnackBarTone.success,
    );
  }

  Future<void> _togglePinTopic(Topic topic) async {
    final pinned = widget.controller.isPinned(topic);
    final changed = pinned
        ? await widget.controller.unpinTopic(topic)
        : await widget.controller.pinTopic(topic);
    if (!mounted) {
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

  TimelineAutoExpandRequest? _autoExpandRequestForTrackedTopic(Topic topic) {
    final controller = widget.controller;
    if (!controller.topicHasRecentUpdate(topic.id)) {
      return null;
    }

    final targetAt = controller.topicLatestRelevantEventAt(topic.id) ??
        controller.latestEntryForTopic(topic.id)?.timestamp;
    if (targetAt == null) {
      return null;
    }

    _timelineAutoExpandRequestToken += 1;
    return TimelineAutoExpandRequest(
      token: _timelineAutoExpandRequestToken,
      topicId: topic.id,
      targetAt: targetAt,
    );
  }

  void _clearTimelineAutoExpandRequest() {
    if (!mounted || _pendingTimelineAutoExpandRequest == null) {
      return;
    }
    setState(() {
      _pendingTimelineAutoExpandRequest = null;
    });
  }

  void _scheduleLoginPromptIfNeeded(TimelineController controller) {
    final token = controller.pendingLoginPromptToken;
    if (token == 0 ||
        token == _handledLoginPromptToken ||
        _presentingLoginPrompt) {
      return;
    }
    _handledLoginPromptToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _presentLoginPrompt(controller);
    });
  }

  void _scheduleOpenTopicNavigationIfNeeded(TimelineController controller) {
    final token = controller.openTopicRequestToken;
    if (token == 0 || token == _handledOpenTopicRequestToken) {
      return;
    }
    _handledOpenTopicRequestToken = token;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_goToPage(1));
    });
  }

  Future<void> _presentLoginPrompt(TimelineController controller) async {
    if (_presentingLoginPrompt) {
      return;
    }
    _presentingLoginPrompt = true;
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final reason =
            controller.pendingLoginPromptReason ?? '登录后即可继续这个操作，并在不同设备间同步你的状态。';
        final isQuotaPrompt = reason.contains('关注') && reason.contains('5');
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: AppTheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSheet),
            side: BorderSide(color: AppTheme.border.withValues(alpha: 0.82)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isQuotaPrompt
                            ? AppTheme.lavenderSoft
                            : AppTheme.accentSoft,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color: isQuotaPrompt
                              ? AppTheme.lavender.withValues(alpha: 0.18)
                              : AppTheme.accent.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        isQuotaPrompt ? '游客额度已满' : '登录以同步',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: isQuotaPrompt
                                  ? AppTheme.lavender
                                  : AppTheme.accentStrong,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  isQuotaPrompt ? '登录后继续关注' : '登录后继续',
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  reason,
                  style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                        height: 1.56,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    child: const Text('手机号验证'),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    child: const Text('稍后再说'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.clearLoginPrompt();
    if (!mounted) {
      _presentingLoginPrompt = false;
      return;
    }

    if (shouldLogin == true) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => _OnDemandRegistrationGate(controller: controller),
        ),
      );
    } else {
      controller.discardDeferredFollowTopic();
      controller.discardDeferredTimelineCreation();
    }
    _presentingLoginPrompt = false;
  }
}

class _OnDemandRegistrationGate extends StatefulWidget {
  const _OnDemandRegistrationGate({
    required this.controller,
  });

  final TimelineController controller;

  @override
  State<_OnDemandRegistrationGate> createState() =>
      _OnDemandRegistrationGateState();
}

class _OnDemandRegistrationGateState extends State<_OnDemandRegistrationGate> {
  bool _hasRequestedDismissal = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.followingBackground,
      body: Stack(
        children: <Widget>[
          RegistrationGateScreen(controller: widget.controller),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: AppTopIconButton(
                  onPressed: () {
                    _hasRequestedDismissal = true;
                    Navigator.of(context).maybePop();
                  },
                  icon: Icons.close_rounded,
                  backgroundColor: AppTheme.surface,
                  borderColor: AppTheme.warmHairline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleControllerChanged() {
    if (!mounted || _hasRequestedDismissal || !widget.controller.isRegistered) {
      return;
    }
    _hasRequestedDismissal = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    });
  }
}

class _ShellBackdrop extends StatelessWidget {
  const _ShellBackdrop({
    required this.color,
  });

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(color: color),
      ),
    );
  }
}

class _TimelineBottomTab extends StatelessWidget {
  const _TimelineBottomTab({
    required this.selected,
    required this.onTap,
  });

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppTheme.accentStrong : AppTheme.textSecondary;
    final labelColor = selected ? AppTheme.accentStrong : AppTheme.textPrimary;

    return Expanded(
      child: Semantics(
        label: '时间轴',
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            hoverColor: AppTheme.accentSoft.withValues(alpha: 0.34),
            focusColor: AppTheme.accentSoft.withValues(alpha: 0.54),
            highlightColor: AppTheme.accentSoft.withValues(alpha: 0.44),
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 52,
                    height: 30,
                    child: Icon(
                      selected
                          ? Icons.watch_later_rounded
                          : Icons.schedule_outlined,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '时间轴',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
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

class _ShellBottomNavigation extends StatelessWidget {
  const _ShellBottomNavigation({
    required this.selectedIndex,
    required this.profileLabel,
    required this.showTrackedDot,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final String profileLabel;
  final bool showTrackedDot;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: AppTheme.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
            child: Row(
              children: <Widget>[
                _ShellBottomTab(
                  icon: Icons.home_outlined,
                  selectedIcon: Icons.home_rounded,
                  label: '首页',
                  selected: selectedIndex == 0,
                  selectedIconColor: AppTheme.accentStrong,
                  selectedBackgroundColor: AppTheme.accentSoft,
                  showDot: showTrackedDot,
                  onTap: () => onDestinationSelected(0),
                ),
                _TimelineBottomTab(
                  selected: selectedIndex == 1,
                  onTap: () => onDestinationSelected(1),
                ),
                _ShellBottomTab(
                  icon: Icons.add_circle_outline_rounded,
                  selectedIcon: Icons.add_circle_rounded,
                  label: '创建',
                  selected: false,
                  selectedIconColor: AppTheme.accentStrong,
                  selectedBackgroundColor: AppTheme.accentSoft,
                  onTap: () => onDestinationSelected(2),
                ),
                _ShellBottomTab(
                  icon: Icons.person_outline_rounded,
                  selectedIcon: Icons.person_rounded,
                  label: profileLabel,
                  selected: selectedIndex == 3,
                  selectedIconColor: AppTheme.accentStrong,
                  selectedBackgroundColor: AppTheme.accentSoft,
                  onTap: () => onDestinationSelected(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellBottomTab extends StatelessWidget {
  const _ShellBottomTab({
    this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedIconColor,
    required this.selectedBackgroundColor,
    this.showDot = false,
  });

  final IconData? icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedIconColor;
  final Color selectedBackgroundColor;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? selectedIconColor : AppTheme.textSecondary;
    final labelColor = selected ? selectedIconColor : AppTheme.textPrimary;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: selected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusControl),
            hoverColor: selectedBackgroundColor.withValues(alpha: 0.30),
            focusColor: selectedBackgroundColor.withValues(alpha: 0.48),
            highlightColor: selectedBackgroundColor.withValues(alpha: 0.40),
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      SizedBox(
                        width: 52,
                        height: 30,
                        child: Icon(
                          selected ? selectedIcon! : icon!,
                          color: iconColor,
                          size: 24,
                        ),
                      ),
                      if (showDot)
                        Positioned(
                          right: 12,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.highlight,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusPill),
                              border: Border.all(
                                color: AppTheme.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
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
