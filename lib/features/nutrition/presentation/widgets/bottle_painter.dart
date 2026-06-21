// lib/features/nutrition/presentation/widgets/bottle_painter.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';

class BottlePainter extends CustomPainter {
  final double fill;
  final double wavePhase;
  final Color accent;
  final bool isDark;

  BottlePainter({
    required this.fill,
    required this.wavePhase,
    required this.accent,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyW = w * 0.52;
    final bodyLeft = (w - bodyW) / 2;
    final neckW = bodyW * 0.45;
    final neckLeft = (w - neckW) / 2;
    final neckTop = h * 0.06;
    final bodyTop = h * 0.14;
    final bodyBottom = h * 0.94;
    final radius = bodyW * 0.22;

    final bottlePath = Path()
      ..moveTo(neckLeft + neckW * 0.15, neckTop + h * 0.04)
      ..lineTo(neckLeft + neckW * 0.85, neckTop + h * 0.04)
      ..lineTo(bodyLeft + bodyW - radius * 0.2, bodyTop)
      ..arcToPoint(
        Offset(bodyLeft + bodyW, bodyTop + radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(bodyLeft + bodyW, bodyBottom - radius)
      ..arcToPoint(
        Offset(bodyLeft + bodyW - radius, bodyBottom),
        radius: Radius.circular(radius),
      )
      ..lineTo(bodyLeft + radius, bodyBottom)
      ..arcToPoint(
        Offset(bodyLeft, bodyBottom - radius),
        radius: Radius.circular(radius),
      )
      ..lineTo(bodyLeft, bodyTop + radius)
      ..arcToPoint(
        Offset(bodyLeft + radius * 0.2, bodyTop),
        radius: Radius.circular(radius),
      )
      ..lineTo(neckLeft + neckW * 0.15, neckTop + h * 0.04)
      ..close();

    final fillTop = bodyBottom - (bodyBottom - bodyTop) * fill.clamp(0.02, 1.0);

    canvas.save();
    canvas.clipPath(bottlePath);

    final liquidTop = fillTop - 8;
    final grad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent, accent.withValues(alpha: 0.8)],
      ).createShader(Rect.fromLTWH(bodyLeft, liquidTop, bodyW, bodyBottom - liquidTop));

    final wavePath = Path();
    wavePath.moveTo(bodyLeft - 4, bodyBottom + 4);
    wavePath.lineTo(bodyLeft - 4, liquidTop);
    final steps = 14;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = bodyLeft + t * bodyW;
      final wave = 3 * math.sin(t * math.pi * 3 + wavePhase);
      wavePath.lineTo(x, liquidTop + wave);
    }
    wavePath.lineTo(bodyLeft + bodyW + 4, bodyBottom + 4);
    wavePath.close();
    canvas.drawPath(wavePath, grad);

    final gloss = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.0),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(bodyLeft, bodyTop, bodyW * 0.35, bodyBottom - bodyTop));
    canvas.drawRect(
      Rect.fromLTWH(bodyLeft + bodyW * 0.12, bodyTop, bodyW * 0.22, bodyBottom - bodyTop),
      gloss,
    );

    canvas.restore();

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isDark ? Colors.white.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.2),
          isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(bottlePath, borderPaint);

    final glow = Paint()
      ..color = accent.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawPath(bottlePath, glow);
  }

  @override
  bool shouldRepaint(covariant BottlePainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.wavePhase != wavePhase;
}
