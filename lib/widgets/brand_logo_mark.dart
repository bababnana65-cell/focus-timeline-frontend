// ============================================================
// lib/widgets/brand_logo_mark.dart - S2 Midnight inline logo
// ------------------------------------------------------------
// Zero-dependency CustomPainter implementation of the exact T1 SVG:
// design_handoff_s2_midnight/T1 _ _.html
// ============================================================

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    this.size = 32,
    this.radius = 8,
  });

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter(radius: radius)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.radius});

  final double radius;

  static const Color _ink = AppTheme.textPrimary; // #F2E9D8
  static const Color _bg = AppTheme.surface; // #142238
  static const Color _ember = AppTheme.accent; // #E07A3B

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 360.0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppTheme.background,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(40 * s, 40 * s, 280 * s, 280 * s),
        Radius.circular(40 * s),
      ),
      Paint()..color = _bg,
    );

    final stem = Path()
      ..moveTo(180 * s, 86 * s)
      ..lineTo(180 * s, 246 * s)
      ..quadraticBezierTo(180 * s, 282 * s, 220 * s, 282 * s);
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = _ink
        ..strokeWidth = 38 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawRect(
      Rect.fromLTWH(118 * s, 138 * s, 124 * s, 28 * s),
      Paint()..color = _ember,
    );

    canvas.drawCircle(
      Offset(220 * s, 282 * s),
      14 * s,
      Paint()..color = _ember,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) =>
      oldDelegate.radius != radius;
}
