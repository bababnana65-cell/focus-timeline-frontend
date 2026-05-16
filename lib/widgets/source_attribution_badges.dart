import 'package:flutter/material.dart';

import '../models/timeline_models.dart';
import '../theme/app_theme.dart';

class SourceAttributionBadges extends StatelessWidget {
  const SourceAttributionBadges({
    super.key,
    required this.entry,
    this.compact = false,
  });

  final TimelineEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final providerLabel = _sourceProviderLabel(entry.sourceProvider);
    final sourceName = entry.sourceName.trim();
    final badges = <Widget>[
      if (providerLabel != null)
        _SourceBadge(
          label: providerLabel,
          foreground: AppTheme.accentStrong,
          background: AppTheme.accentSoft,
          compact: compact,
        ),
      if (sourceName.isNotEmpty && sourceName != providerLabel)
        _SourceBadge(
          label: sourceName,
          foreground: AppTheme.textSecondary,
          background: AppTheme.surface,
          compact: compact,
        ),
      if (entry.sourceKind != null)
        _SourceBadge(
          label: entry.sourceKind!.label,
          foreground: AppTheme.highlight,
          background: AppTheme.highlightSoft,
          compact: compact,
        ),
      if (entry.sourceReliability != null)
        _SourceBadge(
          label: entry.sourceReliability!.label,
          foreground: _reliabilityForeground(entry.sourceReliability!),
          background: _reliabilityBackground(entry.sourceReliability!),
          compact: compact,
        ),
    ];

    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: badges,
    );
  }

  String? _sourceProviderLabel(String? provider) {
    final normalized = provider?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    switch (normalized) {
      case 'tianapi':
        return '中文新闻';
      case 'serpapi_baidu':
        return '百度搜索';
      case 'serpapi_google_news':
        return 'Google News';
      case 'serpapi_google':
        return 'Google 搜索';
      case 'freenewsapi':
        return '新闻 API';
      case 'tavily':
        return '全网搜索';
      default:
        return normalized;
    }
  }

  Color _reliabilityForeground(SourceReliability reliability) {
    switch (reliability) {
      case SourceReliability.high:
        return AppTheme.success;
      case SourceReliability.medium:
        return AppTheme.highlight;
      case SourceReliability.low:
        return AppTheme.danger;
    }
  }

  Color _reliabilityBackground(SourceReliability reliability) {
    switch (reliability) {
      case SourceReliability.high:
        return AppTheme.highlightSoft;
      case SourceReliability.medium:
        return AppTheme.highlightSoft;
      case SourceReliability.low:
        return AppTheme.danger.withValues(alpha: 0.16);
    }
  }
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({
    required this.label,
    required this.foreground,
    required this.background,
    required this.compact,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: compact ? 180 : 260),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: foreground.withValues(alpha: 0.08)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : null,
              ),
        ),
      ),
    );
  }
}
