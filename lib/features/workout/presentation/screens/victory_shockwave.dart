import 'package:flutter/material.dart';

class VictoryShockwave extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final Color color;

  VictoryShockwave({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 1.2;
    final radius = maxRadius * progress;

    final paint = Paint()
      ..color = color.withValues(alpha: (1 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0 * (1 - progress);

    canvas.drawCircle(center, radius, paint);
    
    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: (0.5 * (1 - progress)).clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 40.0 * (1 - progress)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      
    canvas.drawCircle(center, radius, glowPaint);
  }

  @override
  bool shouldRepaint(covariant VictoryShockwave oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
