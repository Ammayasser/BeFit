// lib/core/achievements/ui/achievement_detail_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../models/achievement_models.dart';
import '../models/achievement_event.dart';

class AchievementDetailSheet extends StatelessWidget {
  final Achievement achievement;
  final UserAchievementProgress progress;

  const AchievementDetailSheet({
    super.key,
    required this.achievement,
    required this.progress,
  });

  static void show(BuildContext context, Achievement achievement, UserAchievementProgress progress) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => AchievementDetailSheet(
        achievement: achievement,
        progress: progress,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = !progress.isUnlocked;
    final color = _getCategoryColor(achievement.category);
    final textPrimary = const Color(0xFF1E293B);
    final textSecondary = const Color(0xFF64748B);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 32),

          // Badge Hero Section
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glow
              if (!isLocked)
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              
              // The Badge
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isLocked 
                    ? const LinearGradient(
                        colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                  border: Border.all(
                    color: isLocked ? const Color(0xFFCBD5E1) : color.withOpacity(0.3),
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _getEmoji(achievement.icon),
                    style: GoogleFonts.montserrat(
                      fontSize: 56,
                      color: isLocked ? Colors.black.withOpacity(0.15) : null,
                    ),
                  ),
                ),
              ),
              
              // Progress Ring
              if (isLocked)
                SizedBox(
                  width: 132,
                  height: 132,
                  child: CircularProgressIndicator(
                    value: _calculateTotalPercent(),
                    strokeWidth: 4,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.4)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),

          // Badge Text
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          
          // XP Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.flash5, size: 16, color: Color(0xFFBAFF29)),
                const SizedBox(width: 6),
                Text(
                  '+${achievement.points} XP',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Description Card
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: textSecondary,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 36),

          // Requirements Section
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isLocked ? 'CHALLENGE STATUS' : 'MILESTONE REACHED',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: textSecondary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...achievement.requirements.map((req) {
            final current = progress.requirementValues[req.id] ?? 0.0;
            final percent = (current / req.targetValue).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getRequirementLabel(req),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        '${_formatValue(current)} / ${_formatValue(req.targetValue)}',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isLocked ? color : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percent.clamp(0.05, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLocked 
                                ? [color.withOpacity(0.6), color]
                                : [const Color(0xFF10B981), const Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),

          if (!isLocked && progress.unlockedAt != null) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Text(
                  'COMPLETED ON ${_formatDate(progress.unlockedAt!)}',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  double _calculateTotalPercent() {
    if (achievement.requirements.isEmpty) return 0;
    double total = 0;
    for (final req in achievement.requirements) {
      final current = progress.requirementValues[req.id] ?? 0.0;
      total += (current / req.targetValue).clamp(0.0, 1.0);
    }
    return total / achievement.requirements.length;
  }

  Color _getCategoryColor(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.fitness: return const Color(0xFF3B82F6);
      case AchievementCategory.nutrition: return const Color(0xFF10B981);
      case AchievementCategory.consistency: return const Color(0xFFF59E0B);
      case AchievementCategory.milestone: return const Color(0xFF8B5CF6);
      case AchievementCategory.social: return const Color(0xFFEC4899);
    }
  }

  String _getEmoji(String icon) {
    switch (icon) {
      case 'fitness_center': return '💪';
      case 'bolt': return '⚡';
      case 'landscape': return '🏔️';
      case 'water_drop': return '💧';
      case 'restaurant': return '🥗';
      case 'local_fire_department': return '🔥';
      case 'award': return '🏆';
      default: return '🏅';
    }
  }

  String _getRequirementLabel(AchievementRequirement req) {
    switch (req.eventType) {
      case AchievementEventType.workoutCompleted: return 'Session Count';
      case AchievementEventType.mealLogged: return 'Logged Meals';
      case AchievementEventType.waterLogged: return 'Hydration Target';
      case AchievementEventType.streakUpdated: return 'Daily Consistency';
      case AchievementEventType.weightLogged: return 'Body Metrics';
      case AchievementEventType.achievementUnlocked: return 'Milestones Met';
      default: return 'Challenge Goal';
    }
  }

  String _formatValue(double v) {
    if (v == v.toInt().toDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  String _formatDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
