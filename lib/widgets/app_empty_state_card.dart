import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppEmptyStateCard extends StatelessWidget {
  const AppEmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.centered = true,
    this.boxedIcon = false,
    this.backgroundColor = AppTheme.surface,
    this.borderColor = AppTheme.border,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool centered;
  final bool boxedIcon;
  final Color backgroundColor;
  final Color borderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor =
        iconColor ?? Theme.of(context).colorScheme.primary;
    final textAlign = centered ? TextAlign.center : TextAlign.start;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor.withValues(alpha: 0.82)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: <Widget>[
          if (boxedIcon)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: resolvedIconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: resolvedIconColor),
            )
          else
            Container(
              width: centered ? 76 : 44,
              height: centered ? 62 : 44,
              decoration: BoxDecoration(
                color: resolvedIconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                icon,
                size: centered ? 34 : 26,
                color: resolvedIconColor.withValues(alpha: 0.82),
              ),
            ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
          ),
        ],
      ),
    );
  }
}
