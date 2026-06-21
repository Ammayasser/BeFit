import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints the organic rounded blob shape (bathroom-scale style) with a thick
/// green gradient border and white interior.
class GaugeContainerPainter extends CustomPainter {
  final double borderWidth;
  final Gradient borderGradient;
  final Color fillColor;
  final Color shadowColor;

  GaugeContainerPainter({
    this.borderWidth = 12,
    required this.borderGradient,
    required this.fillColor,
    this.shadowColor = const Color(0x2266BB6A),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildShape(size);

    // Outer soft shadow / glow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path, shadowPaint);

    // White fill
    canvas.drawPath(path, Paint()..color = fillColor);

    // Thick gradient border stroke
    final borderPaint = Paint()
      ..shader = borderGradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, borderPaint);
  }

  /// Wide, horizontally-stretched organic blob with a FLAT bottom edge,
  /// tuned for a ~320 × 180 canvas.
  Path _buildShape(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();

    // ── Flat bottom edge ──────────────────────────────────────────
    // Start at bottom-left corner (with small rounding)
    path.moveTo(w * 0.12, h * 0.88);

    // Straight line across the bottom
    path.lineTo(w * 0.88, h * 0.88);

    // ── Bottom-right corner → right side going up ─────────────────
    path.cubicTo(w * 0.97, h * 0.88, w * 1.00, h * 0.72, w * 0.96, h * 0.50);

    // Right side → top-right
    path.cubicTo(w * 0.92, h * 0.24, w * 0.82, h * 0.08, w * 0.65, h * 0.03);

    // Top-right → top-center
    path.cubicTo(w * 0.58, h * 0.01, w * 0.52, h * 0.00, w * 0.50, h * 0.00);

    // Top-center → top-left
    path.cubicTo(w * 0.48, h * 0.00, w * 0.42, h * 0.01, w * 0.35, h * 0.03);

    // Top-left → left side
    path.cubicTo(w * 0.18, h * 0.08, w * 0.08, h * 0.24, w * 0.04, h * 0.50);

    // Left side → bottom-left corner
    path.cubicTo(w * 0.00, h * 0.72, w * 0.03, h * 0.88, w * 0.12, h * 0.88);

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant GaugeContainerPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor ||
      oldDelegate.borderWidth != borderWidth;
}

/// Draws the scale markings (ticks + labels) and the needle indicator on top
/// of the gauge container.
///
/// [visibleMin] / [visibleMax] define the window of values shown on the gauge.
/// The window is always 40 units wide and shifts dynamically based on the
/// current [value].
class WeightGaugePainter extends CustomPainter {
  final double value;
  final double visibleMin;
  final double visibleMax;
  final Color needleColor;
  final Color majorTickColor;
  final Color minorTickColor;
  final Color labelColor;

  WeightGaugePainter({
    required this.value,
    required this.visibleMin,
    required this.visibleMax,
    this.needleColor = const Color(0xFFFF8A00),
    this.majorTickColor = const Color(0xFF444444),
    this.minorTickColor = const Color(0xFF8DB87E),
    this.labelColor = const Color(0xFF333333),
  });

  double get _range => visibleMax - visibleMin;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Arc center is pushed down well below the visible canvas so the arc
    // curves gently across the upper-middle of the gauge shape.
    final arcCenter = Offset(w * 0.5, h * 1.4);
    final arcRadius = w * 0.55;

    // Arc sweep: left-side to right-side across the top.
    const startAngleDeg = -140.0;
    const endAngleDeg = -40.0;
    const startAngle = startAngleDeg * math.pi / 180;
    const endAngle = endAngleDeg * math.pi / 180;
    const sweepAngle = endAngle - startAngle;

    // ── Thin arc line ───────────────────────────────────────────────────
    final arcPaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawArc(
      Rect.fromCircle(center: arcCenter, radius: arcRadius),
      startAngle,
      sweepAngle,
      false,
      arcPaint,
    );

    // ── Tick marks ──────────────────────────────────────────────────────
    // Draw ticks a bit outside the visible window so they don't pop instantly
    final tickStart = ((visibleMin - 20) / 2).ceil() * 2.0;
    for (double v = tickStart; v <= visibleMax + 20; v += 2) {
      if (v < 0) continue; // safety
      final fraction = (v - visibleMin) / _range;
      final angle = startAngle + fraction * sweepAngle;

      // Restrict drawing to roughly the top half of the shape
      if (angle < startAngle - 0.2 || angle > endAngle + 0.2) continue;

      final isMajor = (v % 10 == 0);
      final tickLen = isMajor ? 14.0 : 8.0;

      final inner = Offset(
        arcCenter.dx + arcRadius * math.cos(angle),
        arcCenter.dy + arcRadius * math.sin(angle),
      );
      final outer = Offset(
        arcCenter.dx + (arcRadius + tickLen) * math.cos(angle),
        arcCenter.dy + (arcRadius + tickLen) * math.sin(angle),
      );

      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = isMajor ? majorTickColor : minorTickColor
          ..strokeWidth = isMajor ? 2.5 : 1.5
          ..strokeCap = StrokeCap.round,
      );
    }

    // ── Number labels (inside the arc, below the ticks) ─────────────────
    final labelStart = ((visibleMin - 20) / 10).ceil() * 10;
    for (int v = labelStart; v <= visibleMax.toInt() + 20; v += 10) {
      if (v < 0) continue;
      final fraction = (v - visibleMin) / _range;
      final angle = startAngle + fraction * sweepAngle;

      if (angle < startAngle - 0.2 || angle > endAngle + 0.2) continue;

      final labelR = arcRadius - 18;
      final pos = Offset(
        arcCenter.dx + labelR * math.cos(angle),
        arcCenter.dy + labelR * math.sin(angle),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: '$v',
          style: GoogleFonts.jetBrainsMono(
            color: labelColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
    }

    // ── Draw the needle ─────────────────────────────────────────────────
    _drawNeedle(canvas, arcCenter, arcRadius, startAngle, sweepAngle);
  }

  void _drawNeedle(
    Canvas canvas,
    Offset arcCenter,
    double arcRadius,
    double startAngle,
    double sweepAngle,
  ) {
    final clamped = value.clamp(visibleMin, visibleMax);
    final fraction = (clamped - visibleMin) / _range;
    final angle = startAngle + fraction * sweepAngle;

    // Needle length: from a point well below the arc to just past the arc
    final needleTipR = arcRadius + 6;
    final needleBaseR = arcRadius * 0.15;

    final tip = Offset(
      arcCenter.dx + needleTipR * math.cos(angle),
      arcCenter.dy + needleTipR * math.sin(angle),
    );

    // Base of the triangle (two points spread perpendicular to the needle)
    const baseHalfWidth = 5.0;
    final perpAngle = angle + math.pi / 2;
    final baseCenter = Offset(
      arcCenter.dx + needleBaseR * math.cos(angle),
      arcCenter.dy + needleBaseR * math.sin(angle),
    );
    final baseLeft = Offset(
      baseCenter.dx + baseHalfWidth * math.cos(perpAngle),
      baseCenter.dy + baseHalfWidth * math.sin(perpAngle),
    );
    final baseRight = Offset(
      baseCenter.dx - baseHalfWidth * math.cos(perpAngle),
      baseCenter.dy - baseHalfWidth * math.sin(perpAngle),
    );

    // Shadow
    final shadowPath = Path()
      ..moveTo(tip.dx + 1, tip.dy + 2)
      ..lineTo(baseLeft.dx + 1, baseLeft.dy + 2)
      ..lineTo(baseRight.dx + 1, baseRight.dy + 2)
      ..close();
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Needle triangle
    final needlePath = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(baseLeft.dx, baseLeft.dy)
      ..lineTo(baseRight.dx, baseRight.dy)
      ..close();
    canvas.drawPath(needlePath, Paint()..color = needleColor);

    // Small circle at the base (pivot)
    canvas.drawCircle(baseCenter, 4, Paint()..color = needleColor);
    canvas.drawCircle(
      baseCenter,
      2.5,
      Paint()..color = const Color(0xFFFFAA33),
    );
  }

  @override
  bool shouldRepaint(covariant WeightGaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.visibleMin != visibleMin ||
      oldDelegate.visibleMax != visibleMax;
}
