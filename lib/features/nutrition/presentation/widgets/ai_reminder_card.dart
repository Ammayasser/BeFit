// lib/features/nutrition/presentation/widgets/ai_reminder_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/befit_theme_extension.dart';

class AiReminderCard extends StatelessWidget {
  final String message;

  const AiReminderCard({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.customColors.hydration;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.03),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.06)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.04),
                  isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                ],
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Reminder',
                        style: GoogleFonts.orbitron(
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: GoogleFonts.inter(
                          color: accent,
                          fontSize: 13,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Iconsax.drop,
                  color: accent.withValues(alpha: 0.9),
                  size: 22,
                ),
              ],
            ),
          ),
          Positioned(
            right: -20,
            top: -30,
            child: IgnorePointer(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF818CF8).withValues(alpha: 0.22),
                      accent.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
