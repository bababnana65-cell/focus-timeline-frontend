import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/timeline_models.dart';
import '../services/timeline_controller.dart';
import '../screens/registration_gate_screen.dart';
import '../theme/app_theme.dart';
import 'create_timeline_sheet.dart';

class AppPageTopBar extends StatelessWidget {
  const AppPageTopBar({
    super.key,
    required this.leading,
    required this.searchHintText,
    required this.searchValue,
    required this.onSearchChanged,
    this.trailing,
  });

  final Widget leading;
  final String searchHintText;
  final String searchValue;
  final ValueChanged<String>? onSearchChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        leading,
        const SizedBox(width: 8),
        Expanded(
          child: PageTopSearchField(
            hintText: searchHintText,
            value: searchValue,
            onChanged: onSearchChanged,
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );
  }
}

class AppTitleTopBar extends StatelessWidget {
  const AppTitleTopBar({
    super.key,
    required this.title,
    required this.leading,
    required this.trailing,
    this.subtitle,
    this.subtitleLeading,
  });

  final String title;
  final Widget leading;
  final Widget trailing;
  final String? subtitle;
  final Widget? subtitleLeading;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle?.trim();
    return SizedBox(
      height: subtitle == null || subtitle.isEmpty ? 44 : 58,
      child: Row(
        children: <Widget>[
          SizedBox(
              width: 46,
              child: Align(alignment: Alignment.centerLeft, child: leading)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.05,
                        height: 1.2,
                        color: AppTheme.textPrimary,
                      ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  _AppTitleSubtitleLine(
                    subtitle: subtitle,
                    leading: subtitleLeading,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
              width: 46,
              child: Align(alignment: Alignment.centerRight, child: trailing)),
        ],
      ),
    );
  }
}

class _AppTitleSubtitleLine extends StatelessWidget {
  const _AppTitleSubtitleLine({
    required this.subtitle,
    this.leading,
  });

  final String subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: leading == null ? TextAlign.center : TextAlign.left,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
    );
    if (leading == null) {
      return text;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        leading!,
        const SizedBox(width: 6),
        Flexible(child: text),
      ],
    );
  }
}

class AppTopIconButton extends StatelessWidget {
  const AppTopIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.primary = false,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool primary;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        iconColor ?? (primary ? AppTheme.accentStrong : AppTheme.textPrimary);
    final resolvedBackgroundColor =
        backgroundColor ?? (primary ? AppTheme.accentSoft : AppTheme.surface);
    final resolvedBorderColor = borderColor ??
        (primary
            ? AppTheme.accent.withValues(alpha: 0.18)
            : AppTheme.warmHairline);

    final button = SizedBox.square(
      dimension: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF273843).withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Material(
          color: resolvedBackgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: resolvedBorderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            onTap: onPressed,
            child: Center(
              child: Icon(
                icon,
                color: foregroundColor,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }
    return Tooltip(
      message: tooltip!,
      child: button,
    );
  }
}

Future<void> showTopSearchSheet({
  required BuildContext context,
  required String title,
  required String hintText,
  required String value,
  required ValueChanged<String> onChanged,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            14,
            16,
            16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              PageTopSearchField(
                hintText: hintText,
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      );
    },
  );
}

class TimelineQuickActionBar extends StatelessWidget {
  const TimelineQuickActionBar({
    super.key,
    required this.onOpenAccount,
    required this.onCreateTimeline,
    this.searchHintText,
    this.searchValue = '',
    this.onSearchChanged,
  });

  final VoidCallback onOpenAccount;
  final VoidCallback onCreateTimeline;
  final String? searchHintText;
  final String searchValue;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    if (searchHintText == null) {
      return Row(
        children: <Widget>[
          AppTopIconButton(
            icon: Icons.person_rounded,
            onPressed: onOpenAccount,
          ),
          const Spacer(),
          AppTopIconButton(
            icon: Icons.add_rounded,
            onPressed: onCreateTimeline,
          ),
        ],
      );
    }

    return AppPageTopBar(
      leading: AppTopIconButton(
        icon: Icons.person_rounded,
        onPressed: onOpenAccount,
      ),
      searchHintText: searchHintText!,
      searchValue: searchValue,
      onSearchChanged: onSearchChanged,
      trailing: AppTopIconButton(
        icon: Icons.add_rounded,
        onPressed: onCreateTimeline,
      ),
    );
  }
}

class PageTopSearchField extends StatefulWidget {
  const PageTopSearchField({
    super.key,
    required this.hintText,
    required this.value,
    this.onChanged,
  });

  final String hintText;
  final String value;
  final ValueChanged<String>? onChanged;

  @override
  State<PageTopSearchField> createState() => _PageTopSearchFieldState();
}

class _PageTopSearchFieldState extends State<PageTopSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant PageTopSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          widget.onChanged?.call(value);
          setState(() {});
        },
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textTertiary,
              ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 40),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged?.call('');
                    setState(() {});
                  },
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
          isDense: true,
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}

Future<void> showTimelineAccountSheet(
  BuildContext context,
  TimelineController controller,
) async {
  final session = controller.session;
  if (session == null) {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '游客模式',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                '登录后即可同步关注状态、置顶设置和浏览历史，并在不同设备间继续查看你的专题时间线。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        fullscreenDialog: true,
                        builder: (_) =>
                            _OnDemandRegistrationGate(controller: controller),
                      ),
                    );
                  },
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('去登录'),
                ),
              ),
            ],
          ),
        );
      },
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              '账号信息',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    session.maskedPhoneNumber,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '登录时间 ${DateFormat('yyyy-MM-dd HH:mm', 'zh_CN').format(session.loggedInAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  controller.logout();
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('退出登录'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<Topic?> showTimelineCreateSheet(
  BuildContext context,
  TimelineController controller, {
  bool expanded = false,
}) {
  return showCreateTimelineSheet(
    context,
    controller,
    expanded: expanded,
  );
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
