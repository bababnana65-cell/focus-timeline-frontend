import 'package:flutter/material.dart';

import '../models/timeline_models.dart';
import '../theme/app_theme.dart';

class AppTopicCardSurface extends StatelessWidget {
  const AppTopicCardSurface({
    super.key,
    required this.child,
    this.onTap,
    required this.decoration,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final Widget child;
  final VoidCallback? onTap;
  final BoxDecoration decoration;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: Ink(
          decoration: decoration,
          child: child,
        ),
      ),
    );
  }
}

class AppTopicIconBadge extends StatelessWidget {
  const AppTopicIconBadge({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.borderColor,
    this.size = 32,
    this.iconSize = 18,
    this.radius = 9,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor ?? AppTheme.accent.withValues(alpha: 0.26),
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}

class AppTopicTitleBlock extends StatelessWidget {
  const AppTopicTitleBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.subtitleAlpha = 0.6,
    this.subtitleHeight = 1.4,
  });

  final String title;
  final String subtitle;
  final double subtitleAlpha;
  final double subtitleHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary
                    .withValues(alpha: subtitleAlpha + 0.08),
                height: subtitleHeight,
              ),
        ),
      ],
    );
  }
}

class AppTopicPill extends StatelessWidget {
  const AppTopicPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.fontWeight = FontWeight.w800,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.10)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}

class AppTopicIconToneBadge extends StatelessWidget {
  const AppTopicIconToneBadge({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.size = 24,
    this.iconSize = 14,
    this.margin = EdgeInsets.zero,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: iconColor.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: iconColor,
      ),
    );
  }
}

class AppTopicMetaItem extends StatelessWidget {
  const AppTopicMetaItem({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
    this.maxLines = 1,
    this.fontWeight,
    this.fontSize,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;
  final int maxLines;
  final FontWeight? fontWeight;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          icon,
          size: 16,
          color: iconColor ?? AppTheme.textTertiary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: textColor ?? AppTheme.textSecondary,
                  fontWeight: fontWeight,
                  fontSize: fontSize,
                ),
          ),
        ),
      ],
    );
  }
}

String formatTopicCardNodeTimeLabel(
  DateTime timestamp, {
  DateTime? now,
}) {
  final compactLabel = formatCompactNodeTimeLabel(
    timestamp,
    now: now,
  );
  if (compactLabel.contains('\n')) {
    return compactLabel;
  }

  final localTimestamp = timestamp.toLocal();
  final localNow = (now ?? DateTime.now()).toLocal();
  if (localTimestamp.year == localNow.year) {
    return compactLabel;
  }

  final yearLabel = localTimestamp.year >= 100
      ? '${localTimestamp.year}年'
      : '公元${localTimestamp.year}年';
  return '$yearLabel\n${localTimestamp.month}月${localTimestamp.day}日';
}
