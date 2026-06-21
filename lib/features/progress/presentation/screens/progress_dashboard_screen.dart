// lib/features/progress/presentation/screens/progress_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/befit_theme_extension.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/content_wrapper.dart';
import '../../../../features/profile/presentation/providers/user_provider.dart';
import '../providers/progress_provider.dart';
import '../widgets/empty_progress_state.dart';
import '../widgets/weight_stat_card.dart';
import '../widgets/bmi_info_card.dart';
import '../widgets/weight_chart.dart';
import '../widgets/weight_log_sheet.dart';
import '../widgets/progress_photo_sheet.dart';
import '../widgets/progress_tab_selector.dart';
import '../widgets/measurement_section.dart';
import '../widgets/photos_tab_view.dart';
import '../screens/photo_compare_screen.dart';
import '../../../../core/utils/responsive.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  int _currentTab = 0; // 0 = Weight & Stats, 1 = Progress Photos

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;
    final progress = context.watch<ProgressProvider>();
    final user = context.watch<UserProvider>();
    final unit = progress.weightUnit;

    return Scaffold(
      backgroundColor: custom.bgPrimary,
      appBar: _buildAppBar(theme),
      body: progress.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: progress.refreshState,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surface,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ContentWrapper(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProgressTabSelector(
                          currentTab: _currentTab,
                          onTabChanged: (tab) =>
                              setState(() => _currentTab = tab),
                        ),
                        const SizedBox(height: 24),
                        if (_currentTab == 0)
                          _WeightTabContent(
                            progress: progress,
                            user: user,
                            unit: unit,
                            isDark: isDark,
                            theme: theme,
                            custom: custom,
                            onSetGoalWeight: () =>
                                _showSetGoalWeightDialog(context, progress),
                          )
                        else
                          const PhotosTabView(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      floatingActionButton: _buildFABs(context, progress),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          context.pop();
        },
        icon: PhosphorIcon(
          PhosphorIcons.caretLeft(),
          color: theme.colorScheme.onSurface,
        ),
      ),
      title: Text(
        _currentTab == 0 ? 'Weight & Progress' : 'Progress Gallery',
        style: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface,
        ),
      ),
      actions: [
        if (_currentTab == 0)
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push(AppRoutes.weightHistory);
            },
            icon: PhosphorIcon(
              PhosphorIcons.clockCounterClockwise(),
              color: theme.colorScheme.onSurface,
            ),
          ),
      ],
    );
  }

  Widget _buildFABs(BuildContext context, ProgressProvider progress) {
    final theme = Theme.of(context);
    final custom = context.customColors;
    final isDark = theme.brightness == Brightness.dark;

    if (_currentTab == 0) {
      return FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          WeightLogSheet.show(context);
        },
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: isDark ? custom.bgPrimary : Colors.white,
        icon: PhosphorIcon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
        label: Text(
          'Log Weight',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
      );
    }

    final showCompare = progress.allPhotos.length >= 2;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (showCompare) ...[
          FloatingActionButton.extended(
            heroTag: 'compare_photos_btn',
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhotoCompareScreen(),
                ),
              );
            },
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: isDark ? custom.bgPrimary : Colors.white,
            icon: PhosphorIcon(
              PhosphorIcons.squaresFour(PhosphorIconsStyle.bold),
            ),
            label: Text(
              'Compare',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
        ],
        FloatingActionButton.extended(
          heroTag: 'add_photo_btn',
          onPressed: () {
            HapticFeedback.mediumImpact();
            ProgressPhotoSheet.show(context);
          },
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: isDark ? custom.bgPrimary : Colors.white,
          icon: PhosphorIcon(PhosphorIcons.plus(PhosphorIconsStyle.bold)),
          label: Text(
            'Add Photo',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  void _showSetGoalWeightDialog(
    BuildContext context,
    ProgressProvider progress,
  ) {
    final theme = Theme.of(context);
    final unit = progress.weightUnit;
    final currentGoalDisplay = progress.goalWeight != null
        ? progress.toDisplayWeight(progress.goalWeight!)
        : progress.currentWeight ?? 70.0;

    final controller = TextEditingController(
      text: currentGoalDisplay.toStringAsFixed(1),
    );

    final double minWeight = unit == 'lbs' ? 66.0 : 30.0;
    final double maxWeight = unit == 'lbs' ? 660.0 : 300.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Set Goal Weight',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your target weight in $unit:',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              decoration: InputDecoration(
                suffixText: unit,
                suffixStyle: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val >= minWeight && val <= maxWeight) {
                HapticFeedback.mediumImpact();
                await progress.updateGoalWeight(val);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Goal weight updated to ${val.toStringAsFixed(1)} $unit',
                      ),
                      backgroundColor: context.customColors.success,
                    ),
                  );
                }
              } else {
                HapticFeedback.heavyImpact();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.brightness == Brightness.dark
                  ? theme.colorScheme.surface
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Weight Tab Content ────────────────────────────────────────────────────────

/// The weight & stats tab body, extracted for clarity.
class _WeightTabContent extends StatelessWidget {
  final ProgressProvider progress;
  final UserProvider user;
  final String unit;
  final bool isDark;
  final ThemeData theme;
  final BeFitThemeExtension custom;
  final VoidCallback onSetGoalWeight;

  const _WeightTabContent({
    required this.progress,
    required this.user,
    required this.unit,
    required this.isDark,
    required this.theme,
    required this.custom,
    required this.onSetGoalWeight,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.allLogs.isEmpty) {
      return EmptyProgressState(
        onLogFirstWeight: () => WeightLogSheet.show(context),
      );
    }

    final bmi = progress.calculateBmi(user.height);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsGrid(
          progress: progress,
          user: user,
          unit: unit,
          custom: custom,
          theme: theme,
          onSetGoalWeight: onSetGoalWeight,
          bmi: bmi,
        ),
        const SizedBox(height: 24),
        _ChartSection(
          progress: progress,
          unit: unit,
          isDark: isDark,
          theme: theme,
          custom: custom,
        ),
        const SizedBox(height: 24),
        if (bmi != null) ...[
          BmiInfoCard(bmi: bmi, category: progress.getBmiCategory(bmi)),
          const SizedBox(height: 24),
        ],
        MeasurementsSection(progress: progress),
      ],
    );
  }
}

// ── Stats Grid ────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  final ProgressProvider progress;
  final UserProvider user;
  final String unit;
  final BeFitThemeExtension custom;
  final ThemeData theme;
  final VoidCallback onSetGoalWeight;
  final double? bmi;

  const _StatsGrid({
    required this.progress,
    required this.user,
    required this.unit,
    required this.custom,
    required this.theme,
    required this.onSetGoalWeight,
    required this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = Responsive.isTablet(context);
        final crossCount = isTablet ? 4 : 2;
        const spacing = 12.0;
        final itemWidth =
            (constraints.maxWidth - (crossCount - 1) * spacing) / crossCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: WeightStatCard(
                title: 'Current Weight',
                value: '${progress.currentWeight?.toStringAsFixed(1)} $unit',
                changeText: progress.latestLog != null
                    ? 'Goal: ${progress.toDisplayWeight(progress.goalWeight ?? 0.0).toStringAsFixed(0)} $unit'
                    : null,
                icon: PhosphorIcons.barbell(),
                iconColor: theme.colorScheme.primary,
                iconBgColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                onTap: onSetGoalWeight,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: WeightStatCard(
                title: 'Total Change',
                value:
                    '${progress.weightChange != null ? (progress.weightChange! > 0 ? '+' : '') + progress.weightChange!.toStringAsFixed(1) : '--'} $unit',
                changeText: progress.weightChange != null
                    ? (progress.weightChange! <= 0
                          ? 'Weight loss'
                          : 'Muscle gain')
                    : null,
                isPositiveChange: progress.weightChange != null
                    ? progress.weightChange! <= 0
                    : null,
                icon: PhosphorIcons.trendDown(),
                iconColor: custom.success,
                iconBgColor: custom.success.withValues(alpha: 0.1),
              ),
            ),
            if (progress.weeklyChange != null)
              SizedBox(
                width: itemWidth,
                child: WeightStatCard(
                  title: 'This Week',
                  value:
                      '${progress.weeklyChange! > 0 ? '+' : ''}${progress.weeklyChange!.toStringAsFixed(1)} $unit',
                  changeText: 'Last 7 days',
                  isPositiveChange: progress.weeklyChange! <= 0,
                  icon: PhosphorIcons.calendar(),
                  iconColor: custom.warning,
                  iconBgColor: custom.warning.withValues(alpha: 0.1),
                ),
              ),
            if (bmi != null)
              SizedBox(
                width: itemWidth,
                child: WeightStatCard(
                  title: 'BMI',
                  value: bmi!.toStringAsFixed(1),
                  changeText: progress.getBmiCategory(bmi!),
                  isPositiveChange:
                      progress.getBmiCategory(bmi!).toLowerCase() == 'normal',
                  icon: PhosphorIcons.heartbeat(),
                  iconColor: custom.protein,
                  iconBgColor: custom.protein.withValues(alpha: 0.1),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Chart Section ─────────────────────────────────────────────────────────────

class _ChartSection extends StatelessWidget {
  final ProgressProvider progress;
  final String unit;
  final bool isDark;
  final ThemeData theme;
  final BeFitThemeExtension custom;

  const _ChartSection({
    required this.progress,
    required this.unit,
    required this.isDark,
    required this.theme,
    required this.custom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weight Trend',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        _TimeRangeSelector(progress: progress),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? custom.surfaceCard : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? custom.border
                  : theme.colorScheme.outline.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: WeightChart(
            logs: progress.filteredLogs,
            goalWeight: progress.goalWeight != null
                ? progress.toDisplayWeight(progress.goalWeight!)
                : null,
            unit: unit,
          ),
        ),
      ],
    );
  }
}

// ── Time Range Selector ───────────────────────────────────────────────────────

class _TimeRangeSelector extends StatelessWidget {
  final ProgressProvider progress;

  const _TimeRangeSelector({required this.progress});

  static const _ranges = [
    (WeightTimeRange.week, '1W'),
    (WeightTimeRange.month, '1M'),
    (WeightTimeRange.threeMonths, '3M'),
    (WeightTimeRange.sixMonths, '6M'),
    (WeightTimeRange.year, '1Y'),
    (WeightTimeRange.all, 'All'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _ranges.map((entry) {
          final (range, label) = entry;
          final isSelected = progress.selectedRange == range;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  HapticFeedback.selectionClick();
                  progress.setTimeRange(range);
                }
              },
              selectedColor: progress.isLoading ? Colors.grey : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
