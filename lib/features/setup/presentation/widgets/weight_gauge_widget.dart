import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'weight_gauge_painter.dart';

/// Interactive weight gauge that looks like a bathroom-scale display.
///
/// The needle points to the value.
/// - When dragging, the needle tracks the finger instantly (no lag).
/// - On release, the dial gracefully slides to center the new value.
class WeightGaugeWidget extends StatefulWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final ValueChanged<double> onValueChanged;
  final bool isKg;
  final VoidCallback onUnitToggle;

  const WeightGaugeWidget({
    super.key,
    required this.value,
    this.minValue = 30,
    this.maxValue = 300,
    required this.onValueChanged,
    this.isKg = true,
    required this.onUnitToggle,
  });

  @override
  State<WeightGaugeWidget> createState() => _WeightGaugeWidgetState();
}

class _WeightGaugeWidgetState extends State<WeightGaugeWidget>
    with TickerProviderStateMixin {
  // Needle animation
  late AnimationController _needleController;
  late Animation<double> _needleAnimation;
  double _animatedValue = 80.0;

  // Window sliding animation
  late AnimationController _windowController;
  late Animation<double> _windowAnimation;
  double _currentWindowLo = 60.0;

  bool _isDragging = false;

  // Arc geometry constants (must match the painter)
  static const double _startAngleDeg = -140.0;
  static const double _endAngleDeg = -40.0;
  static const double _startAngle = _startAngleDeg * math.pi / 180;
  static const double _endAngle = _endAngleDeg * math.pi / 180;
  static const double _sweepAngle = _endAngle - _startAngle;

  // The gauge displays a 40-unit wide window of the scale at any time.
  static const double _windowSize = 40.0;

  @override
  void initState() {
    super.initState();
    _animatedValue = widget.value;
    _currentWindowLo = _calculateTargetWindowLo(widget.value);

    // Needle controller (only used if value changes programmatically outside drag)
    _needleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _needleAnimation = AlwaysStoppedAnimation(_animatedValue);

    // Window controller (slides the dial when the user lifts their finger)
    _windowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _windowAnimation = AlwaysStoppedAnimation(_currentWindowLo);
  }

  @override
  void didUpdateWidget(WeightGaugeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.01) {
      if (_isDragging) {
        // If dragging, follow the finger INSTANTLY without animation lag
        _animatedValue = widget.value;
      } else {
        // If changed programmatically (e.g. initial setup), animate smoothly
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

  /// Calculates where the 40-unit window should sit so that [val] is
  /// neatly centered. Returns the lowest visible value of that window.
  double _calculateTargetWindowLo(double val) {
    // Center the value, rounding to nearest 10 for clean label boundaries
    double target = (val / 10).round() * 10.0 - (_windowSize / 2);

    // Clamp to absolute physical bounds so we never pan out of bounds
    if (target < widget.minValue - 5) target = widget.minValue - 5;
    if (target > widget.maxValue - _windowSize + 5) {
      target = widget.maxValue - _windowSize + 5;
    }
    return target;
  }

  /// Smoothly animates the dial to the [targetLo]
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

  /// Calculates weight value from finger position, using the *currently visible* window
  double? _positionToValue(Offset localPosition, Size size) {
    final arcCenter = Offset(size.width * 0.5, size.height * 1.4);
    final dx = localPosition.dx - arcCenter.dx;
    final dy = localPosition.dy - arcCenter.dy;
    var angle = math.atan2(dy, dx);

    // Ignore touches completely outside the arc
    if (angle > 0) return null;
    if (angle < _startAngle - 0.15) return null;
    if (angle > _endAngle + 0.15) return null;

    double fraction = (angle - _startAngle) / _sweepAngle;
    fraction = fraction.clamp(0.0, 1.0);

    // Value based on the needle's physical angle inside the current window
    double v = _currentWindowLo + fraction * _windowSize;
    v = (v * 2).roundToDouble() / 2; // Snap to nearest 0.5 kg
    return v.clamp(widget.minValue, widget.maxValue);
  }

  void _handlePanStart() {
    _isDragging = true;
    _needleController.stop(); // Stop needle animation immediately
    _windowController.stop(); // Lock the window in place while dragging
  }

  void _handlePanEnd() {
    _isDragging = false;
    // When the user lifts their finger, dynamically slide the window to center
    // the new needle position.
    _animateWindowTo(_calculateTargetWindowLo(widget.value));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0.0, 340.0);
        final height = width * 0.58;

        return SizedBox(
          width: width,
          height: height + 48,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // ── Gauge ──────────────────────────────────────────
              GestureDetector(
                onPanStart: (d) => _handlePanStart(),
                onPanUpdate: (d) {
                  final v = _positionToValue(
                    d.localPosition,
                    Size(width, height),
                  );
                  if (v != null) widget.onValueChanged(v);
                },
                onPanEnd: (d) => _handlePanEnd(),
                onPanCancel: () => _handlePanEnd(),
                onTapDown: (d) {
                  _handlePanStart();
                  final v = _positionToValue(
                    d.localPosition,
                    Size(width, height),
                  );
                  if (v != null) widget.onValueChanged(v);
                },
                onTapUp: (d) => _handlePanEnd(),
                onTapCancel: () => _handlePanEnd(),
                child: CustomPaint(
                  size: Size(width, height),
                  painter: GaugeContainerPainter(
                    borderWidth: 12,
                    borderGradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF66BB6A), Color(0xFFA5D6A7)],
                    ),
                    fillColor: Colors.white,
                  ),
                  foregroundPainter: WeightGaugePainter(
                    value: _animatedValue,
                    visibleMin: _currentWindowLo,
                    visibleMax: _currentWindowLo + _windowSize,
                    needleColor: const Color(0xFFFF8A00),
                    majorTickColor: const Color(0xFF444444),
                    minorTickColor: const Color(0xFF8DB87E),
                    labelColor: const Color(0xFF333333),
                  ),
                ),
              ),

              // ── KG / LB dropdown button ────────────────────────
              Positioned(
                bottom: 6,
                child: GestureDetector(
                  onTap: widget.onUnitToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFCCDFCE),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.isKg ? 'KG' : 'LB',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D2B12),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: Color(0xFF1B5E20),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
