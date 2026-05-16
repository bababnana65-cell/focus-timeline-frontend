import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({
    super.key,
    required this.message,
    required this.onClose,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.highlight.withValues(alpha: 0.18)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.highlight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppTheme.highlight,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6C5835),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                ),
              ),
            ),
            IconButton(
              onPressed: onClose,
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded),
              color: AppTheme.highlight,
            ),
          ],
        ),
      ),
    );
  }
}
