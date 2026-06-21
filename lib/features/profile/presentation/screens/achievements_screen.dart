// lib/features/profile/presentation/screens/achievements_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/achievements/engine/achievement_manager.dart';
import '../../../../core/achievements/engine/achievement_definitions.dart';
import '../../../../core/achievements/models/achievement_models.dart';
import '../../../../core/achievements/ui/achievement_detail_sheet.dart';
import '../../../../core/theme/befit_theme_extension.dart';
import 'profile_screen.dart'; // For HexagonPainter

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<AchievementManager>();
    final allAchievements = AchievementDefinitions.all;
    final unlockedIds = manager.unlockedAchievements.map((a) => a.id).toSet();
    
    // Group by category
    final grouped = <AchievementCategory, List<Achievement>>{};
    for (final a in allAchievements) {
      grouped.putIfAbsent(a.category, () => []).add(a);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Achievements', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        physics: const BouncingScrollPhysics(),
        children: AchievementCategory.values.map((category) {
          final achievements = grouped[category] ?? [];
          if (achievements.isEmpty) return const SizedBox.shrink();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryHeader(context, category),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final isUnlocked = unlockedIds.contains(achievement.id);
                  final progress = manager.allProgress.firstWhere(
                    (p) => p.achievementId == achievement.id,
                    orElse: () => UserAchievementProgress(
                      achievementId: achievement.id,
                      userId: '',
                    ),
                  );

                  return _AchievementBadge(
                    achievement: achievement,
                    isUnlocked: isUnlocked,
                    progress: progress,
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, AchievementCategory category) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: _getCategoryColor(context, category),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          category.name.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  static Color _getCategoryColor(BuildContext context, AchievementCategory category) {
    final custom = context.customColors;
    switch (category) {
      case AchievementCategory.fitness: return custom.protein;
      case AchievementCategory.nutrition: return custom.success;
      case AchievementCategory.consistency: return custom.carbs;
      case AchievementCategory.milestone: return custom.dropSet;
      case AchievementCategory.social: return custom.fat;
    }
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool isUnlocked;
  final UserAchievementProgress progress;

  const _AchievementBadge({
    required this.achievement,
    required this.isUnlocked,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = AchievementsScreen._getCategoryColor(context, achievement.category);

    return Semantics(
      button: true,
      label: '${achievement.title} achievement, ${isUnlocked ? "unlocked" : "locked"}',
      child: GestureDetector(
        onTap: () => AchievementDetailSheet.show(context, achievement, progress),
        child: Column(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(double.infinity, double.infinity),
                      painter: HexagonPainter(
                        color: isUnlocked ? color : theme.colorScheme.surfaceContainerHigh,
                        isLocked: !isUnlocked,
                      ),
                    ),
                    if (isUnlocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    Text(
                      _getEmoji(achievement.icon),
                      style: GoogleFonts.montserrat(
                        fontSize: 32,
                        color: isUnlocked ? null : theme.colorScheme.onSurface.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isUnlocked ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
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
}
