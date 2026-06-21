import 'package:google_fonts/google_fonts.dart';
// lib/features/workout/presentation/widgets/alphabet_scrubber.dart

import 'package:flutter/material.dart';
import '../../core/workout_colors.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';

/// A–Z vertical fast-scroll widget for the right edge of the Exercise Library.
/// Tap or drag to jump to any alphabetical section.
class AlphabetScrubber extends StatefulWidget {
  /// The letters currently present in the list (skip letters with no items).
  final List<String> letters;

  /// Called whenever the user selects a letter by tap or drag.
  final void Function(String letter) onLetterSelected;

  const AlphabetScrubber({
    super.key,
    required this.letters,
    required this.onLetterSelected,
  });

  @override
  State<AlphabetScrubber> createState() => _AlphabetScrubberState();
}

class _AlphabetScrubberState extends State<AlphabetScrubber> {
  String? _active;

  String? _letterAt(Offset localPos, RenderBox box) {
    final n = widget.letters.length;
    if (n == 0) return null;
    final slotH = box.size.height / n;
    final idx = (localPos.dy / slotH).floor().clamp(0, n - 1);
    return widget.letters[idx];
  }

  void _select(Offset localPos) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final letter = _letterAt(localPos, box);
    if (letter == null) return;
    if (letter != _active) {
      setState(() => _active = letter);
      HapticFeedback.selectionClick();
      widget.onLetterSelected(letter);
    }
  }

  void _clearActive() {
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _active = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.letters.isEmpty) return const SizedBox(width: 20);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        _select(d.localPosition);
        _clearActive();
      },
      onVerticalDragUpdate: (d) => _select(d.localPosition),
      onVerticalDragEnd: (_) => _clearActive(),
      child: SizedBox(
        width: 20,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.letters.map((letter) {
            final isActive = _active == letter;
            return Expanded(
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 120),
                  style: GoogleFonts.jetBrainsMono(
                    color: isActive
                        ? AppColors.primary
                        : WorkoutColors.onSurfaceMuted(context).withValues(alpha: 0.7),
                    fontSize: isActive ? 12 : 9.5,
                    fontWeight:
                        isActive ? FontWeight.w900 : FontWeight.w600,
                    height: 1.0,
                  ),
                  child: Text(
                    letter,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
