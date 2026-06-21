// lib/features/profile/presentation/screens/profile_screen.dart

import 'dart:io';

import 'package:befit/core/achievements/engine/achievement_definitions.dart';
import 'package:befit/core/achievements/models/achievement_models.dart';
import 'package:befit/core/achievements/ui/achievement_detail_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/achievements/engine/achievement_manager.dart';
import '../../../../features/workout/data/models/workout_history_entry.dart';
import '../../../../features/workout/data/models/workout_hub_stats.dart';
import '../../../../features/nutrition/data/models/meal_log.dart';
import '../../../../features/workout/presentation/providers/workout_history_provider.dart';
import '../../../../features/workout/presentation/providers/workout_hub_provider.dart';
import '../../../../features/nutrition/presentation/providers/nutrition_provider.dart';
import '../providers/user_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/progress/presentation/providers/progress_provider.dart';
import '../widgets/activity_heatmap_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserProvider>();
    final workoutHub = context.watch<WorkoutHubProvider>();
    final nutrition = context.watch<NutritionProvider>();
    final achievements = context.watch<AchievementManager>();
    final workoutHistory = context.watch<WorkoutHistoryProvider>();

    final stats = workoutHub.stats;

    // Combine and sort activities
    final recentActivities = _getRecentActivities(
      context,
      workoutHistory.history,
      nutrition.recentMeals,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final auth = context.read<AuthProvider>();
          if (auth.userId != null) {
            await workoutHub.refresh(
              userId: auth.userId!,
              user: context.read<UserProvider>(),
              historyProvider: context.read<WorkoutHistoryProvider>(),
            );
            await nutrition.refresh();
          }
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileInfoCard(user: user),
              const SizedBox(height: 24),
              const ActivityHeatmapCard(),
              const SizedBox(height: 24),
              _ProgressOverview(stats: stats),
              const SizedBox(height: 24),
              _RecentActivities(activities: recentActivities),
              const SizedBox(height: 24),
              _Achievements(manager: achievements),
              const SizedBox(height: 24),
              _SettingsGroup(context: context),
              const SizedBox(height: 40),
              _LogoutButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  List<_ActivityItem> _getRecentActivities(
    BuildContext context,
    List<WorkoutHistoryEntry> workouts,
    List<MealLog> meals,
  ) {
    final list = <_ActivityItem>[];
    final customColors = context.customColors;

    for (final w in workouts) {
      DateTime ts;
      try {
        ts = w.completedAt != null
            ? DateTime.parse(w.completedAt!)
            : DateTime.parse(w.date);
      } catch (_) {
        ts = DateTime.now();
      }
      list.add(
        _ActivityItem(
          title: w.focus ?? 'Workout Session',
          subtitle: _formatTimestamp(ts),
          value: '${(w.durationSeconds / 60).round()} min',
          icon: PhosphorIcons.barbell(),
          color: customColors.success,
          imageUrl:
              'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=200&auto=format&fit=crop',
          timestamp: ts,
        ),
      );
    }

    for (final m in meals) {
      list.add(
        _ActivityItem(
          title: m.foodItem.name,
          subtitle: _formatTimestamp(m.loggedAt),
          value: '${m.loggedCalories.round()} kcal',
          icon: PhosphorIcons.bowlFood(),
          color: customColors.protein,
          imageUrl:
              'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=200&auto=format&fit=crop',
          timestamp: m.loggedAt,
        ),
      );
    }

    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list.take(5).toList();
  }

  String _formatTimestamp(DateTime ts) {
    final now = DateTime.now();
    final diff = now.difference(ts);
    if (diff.inDays == 0) {
      if (ts.day == now.day) return 'Today, ${_formatTime(ts)}';
      return 'Yesterday, ${_formatTime(ts)}';
    } else if (diff.inDays == 1) {
      return 'Yesterday, ${_formatTime(ts)}';
    }
    return '${ts.day}/${ts.month}, ${_formatTime(ts)}';
  }

  String _formatTime(DateTime ts) {
    final h = ts.hour.toString().padLeft(2, '0');
    final m = ts.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String value;
  final PhosphorIconData icon;
  final Color color;
  final String imageUrl;
  final DateTime timestamp;

  _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.imageUrl,
    required this.timestamp,
  });
}

class _ProfileInfoCard extends StatefulWidget {
  final UserProvider user;
  const _ProfileInfoCard({required this.user});

  @override
  State<_ProfileInfoCard> createState() => _ProfileInfoCardState();
}

class _ProfileInfoCardState extends State<_ProfileInfoCard> {
  bool _isPickingImage = false;

  Future<void> _pickImage(BuildContext context) async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    final userProvider = context.read<UserProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        final success = await userProvider.updateAvatar(image.path);
        if (!mounted) return;
        if (success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(content: Text('Failed to update profile picture')),
          );
        }
      }
    } catch (e) {
      if (e is PlatformException && e.code == 'already_active') {
        // Picker already active, ignore it
      } else if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final custom = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = widget.user;

    final progress = context.watch<ProgressProvider>();
    final displayWeight =
        progress.currentWeight ?? progress.toDisplayWeight(user.weight);
    final unit = progress.weightUnit;
    final change = progress.weightChange;

    return Semantics(
      label: 'Profile Information Card',
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark
              ? custom.surfaceCard
              : colorScheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? custom.border
                : colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _pickImage(context),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: custom.success, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          backgroundImage: user.profile?.avatarUrl != null
                              ? (user.profile!.avatarUrl!.startsWith('http')
                                    ? NetworkImage(user.profile!.avatarUrl!)
                                    : FileImage(File(user.profile!.avatarUrl!))
                                          as ImageProvider)
                              : null,
                          foregroundImage: user.profile?.avatarUrl != null
                              ? (user.profile!.avatarUrl!.startsWith('http')
                                    ? NetworkImage(user.profile!.avatarUrl!)
                                    : FileImage(File(user.profile!.avatarUrl!))
                                          as ImageProvider)
                              : null,
                          child: user.profile?.avatarUrl == null
                              ? PhosphorIcon(
                                  PhosphorIcons.user(),
                                  size: 32,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickImage(context),
                        child: Semantics(
                          label: 'Edit Avatar',
                          button: true,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: custom.success,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: _isPickingImage
                                  ? SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: isDark
                                            ? custom.bgPrimary
                                            : Colors.white,
                                      ),
                                    )
                                  : PhosphorIcon(
                                      PhosphorIcons.camera(),
                                      size: 14,
                                      color: isDark
                                          ? custom.bgPrimary
                                          : Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        user.email,
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSimpleStat('Age', '${user.age}', context),
                _buildSimpleStat(
                  'Height',
                  '${user.height.toInt()} cm',
                  context,
                ),
                Column(
                  children: [
                    Text(
                      '${displayWeight.toStringAsFixed(1)} $unit',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (change != null && change != 0.0) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PhosphorIcon(
                            change < 0
                                ? PhosphorIcons.arrowDownRight()
                                : PhosphorIcons.arrowUpRight(),
                            size: 11,
                            color: change < 0 ? custom.success : custom.error,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                            style: GoogleFonts.montserrat(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: change < 0 ? custom.success : custom.error,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Weight',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                _buildSimpleStat('Gender', user.gender, context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProgressOverview extends StatelessWidget {
  final WorkoutHubStats stats;
  const _ProgressOverview({required this.stats});

  @override
  Widget build(BuildContext context) {
    final custom = context.customColors;
    return Column(
      children: [
        _buildSectionHeader(context, 'Progress Overview', null),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewItem(
                context,
                'Workouts',
                '${stats.totalSessions}',
                'Completed',
                PhosphorIcons.barbell(),
                custom.success.withValues(alpha: 0.1),
                custom.success,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewItem(
                context,
                'Calories Burned',
                stats.totalCaloriesAllTime > 1000
                    ? '${(stats.totalCaloriesAllTime / 1000).toStringAsFixed(1)}k'
                    : '${stats.totalCaloriesAllTime}',
                'Total',
                PhosphorIcons.fire(),
                custom.protein.withValues(alpha: 0.1),
                custom.protein,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewItem(
                context,
                'Streak',
                '${stats.currentStreak}',
                'Days',
                PhosphorIcons.lightning(),
                custom.carbs.withValues(alpha: 0.1),
                custom.carbs,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildOverviewItem(
                context,
                'Time',
                '${(stats.totalSessions * stats.avgDurationMinutes / 60).floor()}h ${(stats.totalSessions * stats.avgDurationMinutes % 60)}m',
                'Total',
                PhosphorIcons.clock(),
                custom.dropSet.withValues(alpha: 0.1),
                custom.dropSet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewItem(
    BuildContext context,
    String title,
    String value,
    String sub,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: PhosphorIcon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                sub,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _RecentActivities extends StatelessWidget {
  final List<_ActivityItem> activities;
  const _RecentActivities({required this.activities});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Recent Activities', null),
        const SizedBox(height: 16),
        if (activities.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                'No recent activities yet',
                style: GoogleFonts.montserrat(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          Column(
            children: List.generate(activities.length, (index) {
              return _TimelineItem(
                activity: activities[index],
                isFirst: index == 0,
                isLast: index == activities.length - 1,
              );
            }),
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final _ActivityItem activity;
  final bool isFirst;
  final bool isLast;

  const _TimelineItem({
    required this.activity,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final timeStr = DateFormat('HH:mm').format(activity.timestamp);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 50,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                timeStr,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),

          // Indicator column
          SizedBox(
            width: 44,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 12,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  )
                else
                  const SizedBox(height: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: activity.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: activity.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.black26 : Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      activity.icon,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ),

          // Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity.title,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'EEEE, MMM d',
                            ).format(activity.timestamp),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: activity.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        activity.value,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: activity.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Achievements extends StatelessWidget {
  final AchievementManager manager;
  const _Achievements({required this.manager});

  @override
  Widget build(BuildContext context) {
    final unlocked = manager.unlockedAchievements;
    final all = AchievementDefinitions.all;

    // Show up to 4 achievements (unlocked first, then locked)
    final displayList = <Achievement>[...unlocked];
    if (displayList.length < 4) {
      final locked = all
          .where((a) => !unlocked.any((u) => u.id == a.id))
          .toList();
      displayList.addAll(locked.take(4 - displayList.length));
    }

    return Column(
      children: [
        _buildSectionHeader(
          context,
          'Achievements',
          () => context.push(AppRoutes.achievements),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: displayList.map((a) {
            final isUnlocked = unlocked.any((u) => u.id == a.id);
            final progress = manager.allProgress.firstWhere(
              (p) => p.achievementId == a.id,
              orElse: () =>
                  UserAchievementProgress(achievementId: a.id, userId: ''),
            );

            return Expanded(
              child: GestureDetector(
                onTap: () => AchievementDetailSheet.show(context, a, progress),
                child: _buildBadge(
                  context,
                  a.title,
                  isUnlocked ? 'Unlocked' : 'Locked',
                  _getCategoryColor(context, a.category),
                  icon: _getEmoji(a.icon),
                  isLocked: !isUnlocked,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(
    BuildContext context,
    String title,
    String sub,
    Color color, {
    required String icon,
    bool isLocked = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        CustomPaint(
          size: const Size(70, 80),
          painter: HexagonPainter(
            color: isLocked ? colorScheme.surfaceContainerHighest : color,
            isLocked: isLocked,
            iconEmoji: icon,
            lockColor: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          sub,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(BuildContext context, AchievementCategory category) {
    final custom = context.customColors;
    switch (category) {
      case AchievementCategory.fitness:
        return custom.protein;
      case AchievementCategory.nutrition:
        return custom.success;
      case AchievementCategory.consistency:
        return custom.carbs;
      case AchievementCategory.milestone:
        return custom.dropSet;
      case AchievementCategory.social:
        return const Color(0xFFEC4899);
    }
  }

  String _getEmoji(String icon) {
    switch (icon) {
      case 'fitness_center':
        return '💪';
      case 'bolt':
        return '⚡';
      case 'landscape':
        return '🏔️';
      case 'water_drop':
        return '💧';
      case 'restaurant':
        return '🥗';
      case 'local_fire_department':
        return '🔥';
      case 'award':
        return '🏆';
      default:
        return '🏅';
    }
  }
}

class HexagonPainter extends CustomPainter {
  final Color color;
  final bool isLocked;
  final String? iconEmoji;
  final Color? lockColor;
  HexagonPainter({
    required this.color,
    required this.isLocked,
    this.iconEmoji,
    this.lockColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.25);
    path.lineTo(w, h * 0.75);
    path.lineTo(w * 0.5, h);
    path.lineTo(0, h * 0.75);
    path.lineTo(0, h * 0.25);
    path.close();

    canvas.drawPath(path, paint);

    if (isLocked) {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(PhosphorIcons.lockKey().codePoint),
          style: TextStyle(
            fontSize: 24,
            fontFamily: PhosphorIcons.lockKey().fontFamily,
            package: PhosphorIcons.lockKey().fontPackage,
            color: lockColor ?? Colors.grey[500],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset((w - iconPainter.width) / 2, (h - iconPainter.height) / 2),
      );
    } else {
      final iconPainter = TextPainter(
        text: TextSpan(
          text: iconEmoji ?? '🔥',
          style: GoogleFonts.montserrat(fontSize: 32),
        ),
        textDirection: TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(
        canvas,
        Offset((w - iconPainter.width) / 2, (h - iconPainter.height) / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SettingsGroup extends StatelessWidget {
  final BuildContext context;
  const _SettingsGroup({required this.context});

  void _showAppearanceBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.read<ThemeProvider>();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Appearance',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontFamily: GoogleFonts.montserrat().fontFamily,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose Light, Dark, or System Theme',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
            ),
            const SizedBox(height: 24),
            _buildThemeOption(
              context,
              'Light',
              ThemeMode.light,
              PhosphorIcons.sun(),
              themeProvider.themeMode == ThemeMode.light,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              'Dark',
              ThemeMode.dark,
              PhosphorIcons.moon(),
              themeProvider.themeMode == ThemeMode.dark,
            ),
            const SizedBox(height: 12),
            _buildThemeOption(
              context,
              'System',
              ThemeMode.system,
              PhosphorIcons.deviceMobile(),
              themeProvider.themeMode == ThemeMode.system,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    String label,
    ThemeMode mode,
    PhosphorIconData icon,
    bool isSelected,
  ) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    return InkWell(
      onTap: () {
        context.read<ThemeProvider>().setThemeMode(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? custom.success.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? custom.success
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            PhosphorIcon(
              icon,
              color: isSelected ? custom.success : theme.colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? custom.success
                      : theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
              ),
            ),
            if (isSelected)
              PhosphorIcon(
                PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: custom.success,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'BeFit AI',
      applicationVersion: 'Version 1.0',
      applicationLegalese: '© 2026 BeFit AI',
      children: [
        const SizedBox(height: 12),
        Text(
          'Your personal AI fitness coach.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            context,
            'Weight Tracker',
            PhosphorIcons.chartLineUp(),
            onTap: () => context.push(AppRoutes.progress),
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            'Notifications',
            PhosphorIcons.bell(),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            'Appearance',
            PhosphorIcons.paintBrush(),
            onTap: () => _showAppearanceBottomSheet(context),
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            'Privacy Policy',
            PhosphorIcons.shieldCheck(),
            onTap: () => context.push(AppRoutes.privacyPolicy),
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            'Help & Support',
            PhosphorIcons.question(),
            onTap: () => context.push(AppRoutes.helpSupport),
          ),
          _buildDivider(context),
          _buildSettingsTile(
            context,
            'App Info',
            PhosphorIcons.info(),
            onTap: () => _showAppInfoDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: PhosphorIcon(icon, size: 20, color: colorScheme.onSurface),
      ),
      title: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      trailing: PhosphorIcon(
        PhosphorIcons.caretRight(),
        size: 16,
        color: colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(BuildContext context) => Divider(
    height: 1,
    indent: 64,
    color: Theme.of(context).colorScheme.outlineVariant,
  );
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final custom = context.customColors;
    return Center(
      child: TextButton.icon(
        onPressed: () => context.read<AuthProvider>().logout(),
        icon: PhosphorIcon(PhosphorIcons.signOut(), color: custom.failure),
        label: Text(
          'Log Out',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: custom.failure,
          ),
        ),
      ),
    );
  }
}

Widget _buildSectionHeader(
  BuildContext context,
  String title,
  VoidCallback? onAction,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final custom = context.customColors;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      if (onAction != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            'View All',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: custom.success,
            ),
          ),
        ),
    ],
  );
}
