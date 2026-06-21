// lib/core/achievements/ui/achievement_toast.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/achievement_models.dart';

class AchievementToast extends StatelessWidget {
  final Achievement achievement;

  const AchievementToast({super.key, required this.achievement});

  static void show(BuildContext context, Achievement achievement) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: AchievementToast(achievement: achievement),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () => entry.remove());
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * -100),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFF334155),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getEmoji(achievement.icon),
                    style: GoogleFonts.inter(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACHIEVEMENT UNLOCKED!',
                      style: GoogleFonts.montserrat(
                        color: const Color(0xFFFACC15),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      achievement.title,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      achievement.description,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getEmoji(String icon) {
    // Map existing icons to emojis for simple UI
    switch (icon) {
      case 'fitness_center': return '💪';
      case 'bolt': return '⚡';
      case 'landscape': return '🏔️';
      case 'water_drop': return '💧';
      case 'restaurant': return '🥗';
      case 'local_fire_department': return '🔥';
      default: return '🏆';
    }
  }
}
