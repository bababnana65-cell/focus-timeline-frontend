import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppActionButtonVariant {
  outlined,
  filled,
  tonal,
}

class AppActionButton extends StatelessWidget {
  const AppActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.variant = AppActionButtonVariant.outlined,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final AppActionButtonVariant variant;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final child = isLoading
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:
                      foregroundColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Text('处理中', style: textStyle),
            ],
          )
        : icon == null
            ? Text(label, style: textStyle)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(label, style: textStyle),
                ],
              );

    final style = switch (variant) {
      AppActionButtonVariant.outlined => OutlinedButton.styleFrom(
          foregroundColor: foregroundColor,
          side: const BorderSide(color: AppTheme.borderStrong),
          backgroundColor: AppTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      AppActionButtonVariant.filled => FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      AppActionButtonVariant.tonal => FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? AppTheme.accentSoft,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
    };

    return switch (variant) {
      AppActionButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
      AppActionButtonVariant.filled => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
      AppActionButtonVariant.tonal => FilledButton.tonal(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        ),
    };
  }
}

class AppActionPair extends StatelessWidget {
  const AppActionPair({
    super.key,
    required this.secondaryLabel,
    required this.secondaryOnPressed,
    required this.primaryLabel,
    required this.primaryOnPressed,
    this.secondaryIcon,
    this.primaryIcon,
    this.primaryVariant = AppActionButtonVariant.filled,
    this.primaryBackgroundColor,
    this.primaryForegroundColor,
    this.stackOnNarrow = false,
  });

  final String secondaryLabel;
  final VoidCallback? secondaryOnPressed;
  final IconData? secondaryIcon;
  final String primaryLabel;
  final VoidCallback? primaryOnPressed;
  final IconData? primaryIcon;
  final AppActionButtonVariant primaryVariant;
  final Color? primaryBackgroundColor;
  final Color? primaryForegroundColor;
  final bool stackOnNarrow;

  @override
  Widget build(BuildContext context) {
    Widget buildButtons(bool stacked) {
      final children = <Widget>[
        Expanded(
          child: AppActionButton(
            label: secondaryLabel,
            icon: secondaryIcon,
            onPressed: secondaryOnPressed,
            variant: AppActionButtonVariant.outlined,
          ),
        ),
        SizedBox(width: stacked ? 0 : 10, height: stacked ? 10 : 0),
        Expanded(
          child: AppActionButton(
            label: primaryLabel,
            icon: primaryIcon,
            onPressed: primaryOnPressed,
            variant: primaryVariant,
            backgroundColor: primaryBackgroundColor,
            foregroundColor: primaryForegroundColor,
          ),
        ),
      ];

      return stacked
          ? Column(
              children: children,
            )
          : Row(
              children: children,
            );
    }

    if (!stackOnNarrow) {
      return buildButtons(false);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return buildButtons(constraints.maxWidth < 340);
      },
    );
  }
}
