import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';

class HeightRulerPainter extends CustomPainter {
  final double value;
  final double visibleMin;
  final double visibleMax;

  final double majorTickInterval;
  final double minorTickInterval;

  final Color blobGradientStart;
  final Color blobGradientEnd;
  final Color majorTickColor;
  final Color minorTickColor;
  final Color labelColor;
  final Color needleColor;

  HeightRulerPainter({
    required this.value,
    required this.visibleMin,
    required this.visibleMax,
    this.majorTickInterval = 1.0,
    this.minorTickInterval = 0.5,
    this.blobGradientStart = const Color(0xFF6BB56A),
    this.blobGradientEnd = const Color(0xFF1B5E20),
    this.majorTickColor = const Color(0xFF8DDBBD),
    this.minorTickColor = const Color(0xFFC8E6C9),
    this.labelColor = const Color(0xFF757575),
    this.needleColor = const Color(0xFFFF8A00),
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the green organic blob on the left edge
    final blobPath = Path();
    blobPath.moveTo(0, 0);
    // Soft curve that bulges slightly in the center
    blobPath.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.5,
      0,
      size.height,
    );
    blobPath.close();

    final blobPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [blobGradientStart, blobGradientEnd],
      ).createShader(Rect.fromLTWH(0, 0, size.width * 0.4, size.height));

    canvas.drawPath(blobPath, blobPaint);

    // 2. Calculate scale metrics
    final double range = visibleMax - visibleMin;
    final double pixelsPerUnit = size.height / range;

    // The center of the visible window is vertically in the middle of the widget
    final double centerValue = visibleMin + range / 2;

    // Helper to get Y coordinate for a given value
    double getY(double v) {
      // Larger value means higher up (smaller Y)
      return size.height / 2 + (centerValue - v) * pixelsPerUnit;
    }

    // 3. Draw ticks and labels
    // We draw slightly outside the visible bounds for smooth scrolling
    final int startTick = ((visibleMin - range * 0.5) / minorTickInterval)
        .floor();
    final int endTick = ((visibleMax + range * 0.5) / minorTickInterval).ceil();

    final textStyle = GoogleFonts.jetBrainsMono(
      color: labelColor,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );

    final tickStartX = size.width * 0.5;

    for (int i = startTick; i <= endTick; i++) {
      final double v = i * minorTickInterval;
      final double y = getY(v);

      if (y < -20 || y > size.height + 20) continue;

      // Check if it's a major tick
      // Using modulo on doubles can have floating point issues, so we use a small epsilon
      final double remainder = (v % majorTickInterval).abs();
      final bool isMajor =
          remainder < 0.001 || (majorTickInterval - remainder) < 0.001;

      if (isMajor) {
        // Draw Major Tick
        canvas.drawLine(
          Offset(tickStartX, y),
          Offset(tickStartX + 24, y),
          Paint()
            ..color = majorTickColor
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );

        // Draw Label
        final tp = TextPainter(
          text: TextSpan(text: '${v.toInt()}', style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();

        // Position label to the left of the tick
        tp.paint(canvas, Offset(tickStartX - tp.width - 12, y - tp.height / 2));
      } else {
        // Draw Minor Tick
        canvas.drawLine(
          Offset(tickStartX, y),
          Offset(tickStartX + 12, y),
          Paint()
            ..color = minorTickColor
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // 4. Draw the Needle (points exactly to the current `value`)
    final needleY = getY(value);

    // Needle specs: Length 40px, Thickness 3px, Color #FF8A00, Rounded ends
    canvas.drawLine(
      Offset(tickStartX - 8, needleY),
      Offset(tickStartX - 8 + 40, needleY),
      Paint()
        ..color = needleColor
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant HeightRulerPainter oldDelegate) {
    return value != oldDelegate.value ||
        visibleMin != oldDelegate.visibleMin ||
        visibleMax != oldDelegate.visibleMax;
  }
}
