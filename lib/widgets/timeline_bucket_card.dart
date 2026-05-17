import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/timeline_models.dart';
import '../screens/source_article_screen.dart';
import '../services/source_article_service.dart';
import '../theme/app_theme.dart';
import 'source_attribution_badges.dart';
import 'timeline_signal_resolver.dart';

class TimelineBucketCard extends StatefulWidget {
  const TimelineBucketCard({
    super.key,
    required this.bucket,
    this.isFirst = false,
    this.isLast = false,
    this.isInitialNode = false,
    this.isLatestNode = false,
    this.latestDirectionUp = false,
    this.autoExpandToken,
    this.isFavoriteNode = false,
    this.onToggleFavorite,
    this.favoriteButtonKey,
  });

  final TimelineBucket bucket;
  final bool isFirst;
  final bool isLast;
  final bool isInitialNode;
  final bool isLatestNode;
  final bool latestDirectionUp;
  final int? autoExpandToken;
  final bool isFavoriteNode;
  final VoidCallback? onToggleFavorite;
  final Key? favoriteButtonKey;

  @override
  State<TimelineBucketCard> createState() => _TimelineBucketCardState();
}

class _TimelineBucketCardState extends State<TimelineBucketCard> {
  static const SourceArticleService _sourceArticleService =
      SourceArticleService();

  bool expanded = false;
  int? _handledAutoExpandToken;

  @override
  void initState() {
    super.initState();
    final token = widget.autoExpandToken;
    if (token != null) {
      expanded = true;
      _handledAutoExpandToken = token;
    }
  }

  @override
  void didUpdateWidget(covariant TimelineBucketCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final token = widget.autoExpandToken;
    if (token == null || token == _handledAutoExpandToken) {
      return;
    }
    _handledAutoExpandToken = token;
    if (!expanded) {
      setState(() => expanded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bucket = widget.bucket;
    final isMajor = bucket.containsMajorEvent;
    final nodeTone = isMajor ? AppTheme.accentStrong : AppTheme.highlightStrong;
    final dateLabel = _dateChipLabel(bucket);
    final signalStyle = TimelineSignalResolver.resolve(bucket);
    final markerText = widget.isInitialNode ? '起' : bucket.countLabel;
    final railTop = widget.isFirst && widget.isInitialNode
        ? 44.0
        : -AppTheme.cardVerticalGap;
    final markerTop = widget.isInitialNode ? 14.0 : 17.0;
    final markerSize = widget.isInitialNode ? 30.0 : 24.0;
    final markerCenterY = markerTop + markerSize / 2;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 34,
            child: Stack(
              alignment: Alignment.topLeft,
              clipBehavior: Clip.none,
              children: <Widget>[
                Positioned(
                  top: railTop,
                  bottom: widget.isLast ? 0 : -AppTheme.cardVerticalGap,
                  left: 8,
                  child: _TimelineRail(
                    dashed: widget.isLatestNode,
                    dashStartY: markerCenterY - railTop,
                    dashDirectionUp: widget.latestDirectionUp,
                    trimAfterMarker: widget.isLast && widget.isInitialNode,
                  ),
                ),
                const Positioned(
                  top: 29,
                  left: 29,
                  right: 0,
                  child: _TimelineNodeConnector(),
                ),
                Positioned(
                  top: markerTop,
                  left: widget.isInitialNode ? 2 : 5,
                  child: _TimelineNodeMarker(
                    text: markerText,
                    tone: nodeTone,
                    major: isMajor,
                    initial: widget.isInitialNode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 12,
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: 29,
                  left: 0,
                  right: 0,
                  child: _TimelineNodeConnector(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    onTap: () {
                      setState(() => expanded = !expanded);
                    },
                    child: Ink(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusCard),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: AppTheme.shadow,
                            blurRadius: 30,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 110),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 15, 16, 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 9),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: <Widget>[
                                              Expanded(
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: <Widget>[
                                                    _DateChip(
                                                      label: dateLabel,
                                                      major: isMajor,
                                                    ),
                                                    _SignalChip(
                                                        style: signalStyle),
                                                  ],
                                                ),
                                              ),
                                              if (widget.onToggleFavorite !=
                                                  null) ...<Widget>[
                                                const SizedBox(width: 6),
                                                _FavoriteNodeButton(
                                                  key: widget.favoriteButtonKey,
                                                  favorited:
                                                      widget.isFavoriteNode,
                                                  onPressed:
                                                      widget.onToggleFavorite!,
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            bucket.headline,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.35,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceMuted,
                                      borderRadius: BorderRadius.circular(12),
                                      border:
                                          Border.all(color: AppTheme.border),
                                    ),
                                    child: Icon(
                                      expanded
                                          ? Icons.keyboard_arrow_down_rounded
                                          : Icons.chevron_right_rounded,
                                      size: 14,
                                      color: AppTheme.accentStrong,
                                    ),
                                  ),
                                ],
                              ),
                              if (!expanded) ...<Widget>[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.only(left: 9),
                                  child: Text(
                                    bucket.entries.isEmpty
                                        ? '点击展开查看该节点的动态。'
                                        // Headline above is `summary`. Show the
                                        // longer `detail` field beneath so the
                                        // collapsed card actually adds info —
                                        // fall back to summary only if detail
                                        // is empty.
                                        : (bucket.entries.first.detail.isNotEmpty
                                            ? bucket.entries.first.detail
                                            : bucket.entries.first.summary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12,
                                          height: 1.45,
                                        ),
                                  ),
                                ),
                              ],
                              if (expanded) ...<Widget>[
                                const SizedBox(height: 12),
                                const Divider(
                                  height: 1,
                                  color: AppTheme.border,
                                ),
                                const SizedBox(height: 12),
                                ...bucket.entries.asMap().entries.map((item) {
                                  final isLast =
                                      item.key == bucket.entries.length - 1;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: isLast ? 0 : 10,
                                    ),
                                    child: _EntryDetail(
                                      entry: item.value,
                                      index: item.key + 1,
                                      onTap: () =>
                                          _openSourceLink(context, item.value),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!widget.isLast)
                  const SizedBox(height: AppTheme.cardVerticalGap),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dateChipLabel(TimelineBucket bucket) {
    return formatTimelineBucketDateLabel(bucket);
  }

  Future<void> _openSourceLink(
      BuildContext context, TimelineEntry entry) async {
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

class _TimelineRail extends StatelessWidget {
  const _TimelineRail({
    required this.dashed,
    required this.dashStartY,
    required this.dashDirectionUp,
    required this.trimAfterMarker,
  });

  final bool dashed;
  final double dashStartY;
  final bool dashDirectionUp;
  final bool trimAfterMarker;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: CustomPaint(
        painter: _TimelineRailPainter(
          dashed: dashed,
          dashStartY: dashStartY,
          dashDirectionUp: dashDirectionUp,
          trimAfterMarker: trimAfterMarker,
        ),
      ),
    );
  }
}

class _TimelineNodeConnector extends StatelessWidget {
  const _TimelineNodeConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
    );
  }
}

class _FavoriteNodeButton extends StatelessWidget {
  const _FavoriteNodeButton({
    super.key,
    required this.favorited,
    required this.onPressed,
  });

  final bool favorited;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = favorited ? AppTheme.highlight : AppTheme.textSecondary;
    return Semantics(
      button: true,
      selected: favorited,
      label: favorited ? '取消收藏节点' : '收藏节点',
      child: SizedBox.square(
        dimension: 24,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Icon(
              favorited ? Icons.star_rounded : Icons.star_border_rounded,
              size: 19,
              color: foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.major,
  });

  final String label;
  final bool major;

  @override
  Widget build(BuildContext context) {
    final foreground = major ? AppTheme.accentStrong : AppTheme.highlightStrong;
    final border = major
        ? AppTheme.accent.withValues(alpha: 0.44)
        : AppTheme.highlight.withValues(alpha: 0.30);
    final background = major ? AppTheme.accentSoft : AppTheme.highlightSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  const _SignalChip({
    required this.style,
  });

  final TimelineSignalStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: AppTheme.border.withValues(alpha: 0.78),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            style.icon,
            size: 10.5,
            color: style.foregroundColor,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              style.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRailPainter extends CustomPainter {
  const _TimelineRailPainter({
    required this.dashed,
    required this.dashStartY,
    required this.dashDirectionUp,
    required this.trimAfterMarker,
  });

  final bool dashed;
  final double dashStartY;
  final bool dashDirectionUp;
  final bool trimAfterMarker;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final mainPaint = Paint()
      ..isAntiAlias = true
      ..color = AppTheme.accent
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.square;

    if (dashed) {
      final startY = dashStartY.clamp(-1.0, size.height + 1).toDouble();
      if (dashDirectionUp) {
        final arrowTipY = math.min(startY - 12, 1.0);
        final dashEndY = math.min(startY, arrowTipY + 9);

        _drawDashedLine(
          canvas,
          Offset(centerX, startY),
          Offset(centerX, dashEndY),
          mainPaint,
        );
        _drawArrowHead(
          canvas,
          Offset(centerX, arrowTipY),
          mainPaint,
          pointsUp: true,
        );
        canvas.drawLine(
          Offset(centerX, startY),
          Offset(centerX, size.height + 1),
          mainPaint,
        );
        return;
      }

      final arrowTipY = math.max(startY + 12, size.height - 2);
      final dashEndY = math.max(startY, arrowTipY - 9);

      canvas.drawLine(
        Offset(centerX, -1),
        Offset(centerX, startY),
        mainPaint,
      );
      _drawDashedLine(
        canvas,
        Offset(centerX, startY),
        Offset(centerX, dashEndY),
        mainPaint,
      );
      _drawArrowHead(canvas, Offset(centerX, arrowTipY), mainPaint);
      return;
    }

    if (trimAfterMarker) {
      final endY = dashStartY.clamp(-1.0, size.height + 1).toDouble();
      if (endY > -1) {
        canvas.drawLine(
          Offset(centerX, -1),
          Offset(centerX, endY),
          mainPaint,
        );
      }
      return;
    }

    canvas.drawLine(
      Offset(centerX, -1),
      Offset(centerX, size.height + 1),
      mainPaint,
    );
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashLength = 7.0;
    const gapLength = 5.0;
    if (start.dy > end.dy) {
      var y = start.dy;
      while (y > end.dy) {
        final nextY = math.max(y - dashLength, end.dy);
        canvas.drawLine(Offset(start.dx, y), Offset(end.dx, nextY), paint);
        y = nextY - gapLength;
      }
      return;
    }

    var y = start.dy;
    while (y < end.dy) {
      final nextY = math.min(y + dashLength, end.dy);
      canvas.drawLine(Offset(start.dx, y), Offset(end.dx, nextY), paint);
      y = nextY + gapLength;
    }
  }

  void _drawArrowHead(
    Canvas canvas,
    Offset tip,
    Paint paint, {
    bool pointsUp = false,
  }) {
    const arrowSize = 5.0;
    final baseY = pointsUp ? tip.dy + arrowSize : tip.dy - arrowSize;
    canvas.drawLine(
      tip,
      Offset(tip.dx - arrowSize, baseY),
      paint,
    );
    canvas.drawLine(
      tip,
      Offset(tip.dx + arrowSize, baseY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineRailPainter oldDelegate) {
    return oldDelegate.dashed != dashed ||
        oldDelegate.dashStartY != dashStartY ||
        oldDelegate.dashDirectionUp != dashDirectionUp ||
        oldDelegate.trimAfterMarker != trimAfterMarker;
  }
}

class _TimelineNodeMarker extends StatelessWidget {
  const _TimelineNodeMarker({
    required this.text,
    required this.tone,
    required this.major,
    required this.initial,
  });

  final String text;
  final Color tone;
  final bool major;
  final bool initial;

  @override
  Widget build(BuildContext context) {
    final size = initial ? 30.0 : 24.0;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Underlay: solid opaque page-bg disc that guarantees the rail
          // (solid or dashed) is hidden behind the marker.
          DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.timelineBackground,
              shape: BoxShape.circle,
            ),
            child: SizedBox.square(dimension: size),
          ),
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: initial
                  ? AppTheme.accentSoft
                  : (major ? AppTheme.accentSoft : AppTheme.highlightSoft),
              shape: BoxShape.circle,
              boxShadow: initial
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.timelineBackground,
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: AppTheme.accentSoft,
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ]
                  : null,
              border: Border.all(
                color: initial || major
                    ? AppTheme.accent
                        .withValues(alpha: initial ? 0.45 : 0.30)
                    : AppTheme.highlight.withValues(alpha: 0.30),
                width: 2,
              ),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: initial
                        ? AppTheme.accentStrong
                        : tone,
                    fontWeight:
                        initial ? FontWeight.w500 : FontWeight.w900,
                    height: 1,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  final String text;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: foreground.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
            ),
      ),
    );
  }
}

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({
    required this.entry,
    required this.index,
    required this.onTap,
  });

  final TimelineEntry entry;
  final int index;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await onTap();
        },
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: entry.isMajor
                          ? AppTheme.highlight.withValues(alpha: 0.12)
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$index',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: entry.isMajor
                                ? AppTheme.highlight
                                : Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (entry.isMajor)
                    const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: _Badge(
                        text: '重大',
                        background: AppTheme.highlightSoft,
                        foreground: AppTheme.highlight,
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 18,
                    color: AppTheme.textTertiary,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.detail,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 10),
              SourceAttributionBadges(
                entry: entry,
                compact: true,
              ),
              const SizedBox(height: 8),
              Text(
                formatTimelineDateTime(entry.timestamp),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
