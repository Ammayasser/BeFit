import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'victory_colors.dart';

class VictoryMoodSelector extends StatelessWidget {
  final int selectedMood;
  final Function(int) onMoodSelected;

  const VictoryMoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final emojis = ['😫', '😕', '😐', '🙂', '🔥'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(5, (index) {
        final mood = index + 1;
        final isSelected = selectedMood == mood;

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onMoodSelected(mood);
          },
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected 
                      ? VictoryColors.accent.withValues(alpha: 0.1) 
                      : VictoryColors.backgroundCard,
                  border: Border.all(
                    color: isSelected ? VictoryColors.accent : VictoryColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: VictoryColors.accent.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ] : [],
                ),
                child: Center(
                  child: Text(
                    emojis[index],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ).animate(target: isSelected ? 1 : 0).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.2, 1.2),
                duration: 300.ms,
                curve: Curves.easeOutBack,
              ),
            ],
          ),
        );
      }),
    );
  }
}
