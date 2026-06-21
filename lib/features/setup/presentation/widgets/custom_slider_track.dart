import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class CustomSliderTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight!;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Background track
    final backgroundPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..style = PaintingStyle.fill;

    final backgroundRRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    context.canvas.drawRRect(backgroundRRect, backgroundPaint);

    // Active track with gradient
    final activeRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      thumbCenter.dx - rect.left,
      rect.height,
    );

    final gradient = LinearGradient(
      colors: [AppColors.primary, AppColors.primaryDark],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );

    final activePaint = Paint()
      ..shader = gradient.createShader(activeRect)
      ..style = PaintingStyle.fill;

    final activeRRect = RRect.fromRectAndRadius(
      activeRect,
      Radius.circular(rect.height / 2),
    );
    context.canvas.drawRRect(activeRRect, activePaint);

    // Add subtle shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    context.canvas.drawRRect(
      activeRRect.shift(const Offset(0, 2)),
      shadowPaint,
    );
  }
}
