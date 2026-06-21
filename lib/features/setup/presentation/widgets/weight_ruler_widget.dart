import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WeightRulerWidget extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final ValueChanged<double> onValueChanged;

  const WeightRulerWidget({
    super.key,
    required this.value,
    this.minValue = 40,
    this.maxValue = 150,
    required this.onValueChanged,
  });

  @override
  State<WeightRulerWidget> createState() => _WeightRulerWidgetState();
}

class _WeightRulerWidgetState extends State<WeightRulerWidget>
    with SingleTickerProviderStateMixin {
  late double _currentValue;
  late AnimationController _controller;
  double _startValue = 0;
  double _dragStartX = 0;

  static const double _pixelsPerUnit =
      24.0; // Increased spacing for a "wider" look
  int _lastHapticValue = -1;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(WeightRulerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_controller.isAnimating) {
      _currentValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    _startValue = _currentValue;
    _dragStartX = details.localPosition.dx;
    _controller.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final dx = details.localPosition.dx - _dragStartX;
    final valueDelta = -dx / _pixelsPerUnit;

    setState(() {
      _currentValue = (_startValue + valueDelta).clamp(
        widget.minValue,
        widget.maxValue,
      );
    });

    final rounded = _currentValue.roundToDouble();
    widget.onValueChanged(rounded);

    if (rounded.toInt() != _lastHapticValue) {
      HapticFeedback.selectionClick();
      _lastHapticValue = rounded.toInt();
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    final targetValue = _currentValue.roundToDouble();

    final animation = Tween<double>(
      begin: _currentValue,
      end: targetValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    animation.addListener(() {
      setState(() {
        _currentValue = animation.value;
      });
      widget.onValueChanged(_currentValue.roundToDouble());
    });

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: Container(
        height: 180, // Increased height
        width: double.infinity,
        color: Colors.transparent,
        child: CustomPaint(
          painter: _RulerPainter(
            currentValue: _currentValue,
            minValue: widget.minValue,
            maxValue: widget.maxValue,
            pixelsPerUnit: _pixelsPerUnit,
          ),
        ),
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double currentValue;
  final double minValue;
  final double maxValue;
  final double pixelsPerUnit;

  _RulerPainter({
    required this.currentValue,
    required this.minValue,
    required this.maxValue,
    required this.pixelsPerUnit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final textStyle = GoogleFonts.jetBrainsMono(
      color: Colors.white,
      fontSize: 14, // Slightly larger font
      fontWeight: FontWeight.w400,
    );

    final visibleUnits = (size.width / pixelsPerUnit).ceil() + 2;
    final startUnit = (currentValue - visibleUnits / 2).floor();
    final endUnit = (currentValue + visibleUnits / 2).ceil();

    for (int i = startUnit; i <= endUnit; i++) {
      if (i < minValue || i > maxValue) continue;

      final x = centerX + (i - currentValue) * pixelsPerUnit;
      final isMajor = i % 5 == 0;
      final distance = (i - currentValue).abs();
      final opacity = (1.0 - (distance / (visibleUnits / 2))).clamp(0.0, 1.0);

      tickPaint.color = Colors.white.withValues(
        alpha: isMajor ? opacity * 0.8 : opacity * 0.4,
      );
      tickPaint.strokeWidth = isMajor ? 2.0 : 1.2; // Slightly thicker ticks

      final tickHeight = isMajor ? 50.0 : 30.0; // Taller ticks
      canvas.drawLine(
        Offset(x, centerY - 15),
        Offset(x, centerY - 15 - tickHeight),
        tickPaint,
      );

      if (isMajor) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: i.toString(),
            style: textStyle.copyWith(
              color: Colors.white.withValues(alpha: opacity),
              fontWeight: distance < 0.5 ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, centerY + 15),
        );
      }
    }

    final pointerPaint = Paint()
      ..color = const Color(0xFFF05556)
      ..strokeWidth =
          3.0 // Thicker pointer
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(centerX, centerY - 15),
      Offset(centerX, centerY - 85), // Taller pointer line
      pointerPaint,
    );

    final circlePaint = Paint()
      ..color = const Color(0xFFF05556)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(centerX, centerY - 5), 8, circlePaint);

    canvas.drawCircle(
      Offset(centerX, centerY - 5),
      12,
      Paint()..color = const Color(0xFFF05556).withValues(alpha: 0.2),
    );

    // Apply fading gradient to the entire layer
    final fadePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.black,
          Colors.black,
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.dstIn;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fadePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) {
    return oldDelegate.currentValue != currentValue;
  }
}
