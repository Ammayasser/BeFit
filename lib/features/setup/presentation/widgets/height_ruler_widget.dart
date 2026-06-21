import 'package:flutter/material.dart';
import 'height_ruler_painter.dart';

/// Interactive vertical height ruler.
///
/// Features zero-lag 1:1 needle tracking during drag,
/// and smooth scale sliding to center the value on release.
class HeightRulerWidget extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final ValueChanged<double> onValueChanged;

  final double windowSize;
  final double snapInterval;
  final double majorTickInterval;
  final double minorTickInterval;

  const HeightRulerWidget({
    super.key,
    required this.value,
    this.minValue = 100,
    this.maxValue = 250,
    required this.onValueChanged,
    this.windowSize = 10.0,
    this.snapInterval = 0.1,
    this.majorTickInterval = 1.0,
    this.minorTickInterval = 0.5,
  });

  @override
  State<HeightRulerWidget> createState() => _HeightRulerWidgetState();
}

class _HeightRulerWidgetState extends State<HeightRulerWidget>
    with TickerProviderStateMixin {
  late AnimationController _needleController;
  late Animation<double> _needleAnimation;
  double _animatedValue = 170.0;

  late AnimationController _windowController;
  late Animation<double> _windowAnimation;
  double _currentWindowLo = 165.0;

  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animatedValue = widget.value;
    _currentWindowLo = _calculateTargetWindowLo(widget.value);

    _needleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _needleAnimation = AlwaysStoppedAnimation(_animatedValue);

    _windowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _windowAnimation = AlwaysStoppedAnimation(_currentWindowLo);
  }

  @override
  void didUpdateWidget(HeightRulerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.01) {
      if (_isDragging) {
        _animatedValue = widget.value;
      } else {
        _needleAnimation =
            Tween<double>(begin: _animatedValue, end: widget.value).animate(
              CurvedAnimation(
                parent: _needleController,
                curve: Curves.easeOutCubic,
              ),
            )..addListener(() {
              setState(() => _animatedValue = _needleAnimation.value);
            });
        _needleController.forward(from: 0);

        _animateWindowTo(_calculateTargetWindowLo(widget.value));
      }
    }
  }

  @override
  void dispose() {
    _needleController.dispose();
    _windowController.dispose();
    super.dispose();
  }

  double _calculateTargetWindowLo(double val) {
    // Center the value, rounding to nearest integer
    double target = val.roundToDouble() - (widget.windowSize / 2);

    // Clamp to absolute physical bounds
    if (target < widget.minValue - 2) target = widget.minValue - 2;
    if (target > widget.maxValue - widget.windowSize + 2) {
      target = widget.maxValue - widget.windowSize + 2;
    }
    return target;
  }

  void _animateWindowTo(double targetLo) {
    if ((_currentWindowLo - targetLo).abs() < 0.1) return;

    _windowAnimation =
        Tween<double>(begin: _currentWindowLo, end: targetLo).animate(
          CurvedAnimation(
            parent: _windowController,
            curve: Curves.easeInOutCubic,
          ),
        )..addListener(() {
          setState(() => _currentWindowLo = _windowAnimation.value);
        });
    _windowController.forward(from: 0);
  }

  double? _positionToValue(Offset localPosition, Size size) {
    // Fraction of height from bottom up
    double fraction = 1.0 - (localPosition.dy / size.height);
    fraction = fraction.clamp(0.0, 1.0);

    double v = _currentWindowLo + fraction * widget.windowSize;
    v =
        (v * (1.0 / widget.snapInterval)).roundToDouble() *
        widget.snapInterval; // Snap to 0.1 cm
    return v.clamp(widget.minValue, widget.maxValue);
  }

  void _handlePanStart() {
    _isDragging = true;
    _needleController.stop();
    _windowController.stop();
  }

  void _handlePanEnd() {
    _isDragging = false;
    _animateWindowTo(_calculateTargetWindowLo(widget.value));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The widget will take up available height, and a fixed width
        // sufficient to show the blob, numbers, and ticks.
        final width = 160.0;
        final height = constraints.maxHeight;

        return SizedBox(
          width: width,
          height: height,
          child: GestureDetector(
            onPanStart: (d) => _handlePanStart(),
            onPanUpdate: (d) {
              final v = _positionToValue(d.localPosition, Size(width, height));
              if (v != null) widget.onValueChanged(v);
            },
            onPanEnd: (d) => _handlePanEnd(),
            onPanCancel: () => _handlePanEnd(),
            onTapDown: (d) {
              _handlePanStart();
              final v = _positionToValue(d.localPosition, Size(width, height));
              if (v != null) widget.onValueChanged(v);
            },
            onTapUp: (d) => _handlePanEnd(),
            onTapCancel: () => _handlePanEnd(),
            child: CustomPaint(
              size: Size(width, height),
              painter: HeightRulerPainter(
                value: _animatedValue,
                visibleMin: _currentWindowLo,
                visibleMax: _currentWindowLo + widget.windowSize,
                majorTickInterval: widget.majorTickInterval,
                minorTickInterval: widget.minorTickInterval,
              ),
            ),
          ),
        );
      },
    );
  }
}
