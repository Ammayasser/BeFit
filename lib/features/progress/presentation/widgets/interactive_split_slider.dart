// lib/features/progress/presentation/widgets/interactive_split_slider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class InteractiveSplitSlider extends StatefulWidget {
  final String beforeImagePath;
  final String afterImagePath;

  const InteractiveSplitSlider({
    super.key,
    required this.beforeImagePath,
    required this.afterImagePath,
  });

  @override
  State<InteractiveSplitSlider> createState() => _InteractiveSplitSliderState();
}

class _InteractiveSplitSliderState extends State<InteractiveSplitSlider> {
  double _sliderPos = 0.5; // range: 0.0 -> 1.0

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          return Stack(
            children: [
              // 1. Before Image (Full background)
              Positioned.fill(
                child: Image.file(
                  File(widget.beforeImagePath),
                  fit: BoxFit.cover,
                ),
              ),

              // 2. After Image (Clipped to the right side of the slider position)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: (1.0 - _sliderPos).clamp(0.0, 1.0),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Image.file(
                      File(widget.afterImagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // 3. Before Label (Top Left)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'BEFORE',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              // 4. After Label (Top Right)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'AFTER',
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              // 5. Divider Line
              Positioned(
                top: 0,
                bottom: 0,
                left: _sliderPos * width - 1.5,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

              // 6. Sliding Circle Handle
              Positioned(
                top: height / 2 - 22,
                left: _sliderPos * width - 22,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(
                          Icons.arrow_left_rounded,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        Icon(
                          Icons.arrow_right_rounded,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 7. GestureDetector Overlay for Dragging
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (_) {
                    HapticFeedback.selectionClick();
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _sliderPos = (details.localPosition.dx / width).clamp(
                        0.0,
                        1.0,
                      );
                    });
                  },
                  onHorizontalDragEnd: (_) {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
