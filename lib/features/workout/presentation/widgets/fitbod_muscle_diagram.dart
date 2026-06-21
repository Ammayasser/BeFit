import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/workout_colors.dart';

class FitbodMuscleDiagram extends StatelessWidget {
  final String primaryMuscle;
  final List<String> secondaryMuscles;

  const FitbodMuscleDiagram({
    super.key,
    required this.primaryMuscle,
    required this.secondaryMuscles,
  });

  List<int> _getMuscleIds(String name) {
    final clean = name.trim().toLowerCase();
    final ids = <int>[];

    if (clean.contains('chest') || clean.contains('pectoral')) ids.add(4);
    if (clean.contains('abs') ||
        clean.contains('abdominals') ||
        clean.contains('core') ||
        clean.contains('waist')) {
      ids.addAll([6, 14]); // Rectus abdominis and Obliques
    }
    if (clean.contains('biceps') ||
        clean.contains('bicep') ||
        clean.contains('arms')) {
      ids.addAll([1, 13]); // Biceps and Brachialis
    }
    if (clean.contains('triceps') || clean.contains('tricep')) ids.add(5);
    if (clean.contains('shoulders') ||
        clean.contains('deltoid') ||
        clean.contains('delt')) {
      ids.add(2);
    }
    if (clean.contains('quadriceps') ||
        clean.contains('quad') ||
        clean.contains('quads') ||
        clean.contains('leg')) {
      ids.add(10);
    }
    if (clean.contains('hamstring') || clean.contains('hamstrings')) {
      ids.add(11);
    }
    if (clean.contains('glutes') ||
        clean.contains('gluteus') ||
        clean.contains('glute')) {
      ids.add(8);
    }
    if (clean.contains('calves') || clean.contains('calf')) {
      ids.addAll([7, 15]); // Gastrocnemius and Soleus
    }
    if (clean.contains('trapezius') || clean.contains('traps')) ids.add(9);
    if (clean.contains('back') ||
        clean.contains('lats') ||
        clean.contains('latissimus')) {
      ids.add(12);
    }

    return ids;
  }

  bool _isBackMuscle(int id) {
    // Known back muscles in Wger
    return const [5, 7, 8, 9, 11, 12, 15, 16].contains(id);
  }

  @override
  Widget build(BuildContext context) {
    final primaryIds = _getMuscleIds(primaryMuscle);
    final secondaryIds = <int>{};
    for (final sec in secondaryMuscles) {
      secondaryIds.addAll(_getMuscleIds(sec));
    }
    // Remove primary from secondary so they don't clash
    secondaryIds.removeAll(primaryIds);

    return Column(
      children: [
        // Silhouette Row wrapped in LayoutBuilder and FittedBox to prevent overflow on narrow viewports
        LayoutBuilder(
          builder: (context, constraints) {
            final row = Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Front View
                _buildWgerSilhouette(
                  context,
                  isBack: false,
                  primaryIds: primaryIds
                      .where((id) => !_isBackMuscle(id))
                      .toList(),
                  secondaryIds: secondaryIds
                      .where((id) => !_isBackMuscle(id))
                      .toList(),
                ),
                const SizedBox(width: 24),
                // Back View
                _buildWgerSilhouette(
                  context,
                  isBack: true,
                  primaryIds: primaryIds
                      .where((id) => _isBackMuscle(id))
                      .toList(),
                  secondaryIds: secondaryIds
                      .where((id) => _isBackMuscle(id))
                      .toList(),
                ),
              ],
            );

            if (constraints.maxWidth < 304) {
              return FittedBox(fit: BoxFit.scaleDown, child: row);
            }
            return row;
          },
        ),
        const SizedBox(height: 16),
        // Labeled Targets (Responsive individual chips)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (primaryMuscle.isNotEmpty)
                _buildMuscleChip(context, primaryMuscle, isPrimary: true),
              ...secondaryMuscles.map(
                (m) => _buildMuscleChip(context, m, isPrimary: false),
              ),
              if (primaryMuscle.isEmpty && secondaryMuscles.isEmpty)
                Text(
                  "No target muscles specified",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WorkoutColors.onSurfaceMuted(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMuscleChip(
    BuildContext context,
    String muscleName, {
    required bool isPrimary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dotColor = isPrimary
        ? const Color(0xFF4ADE80)
        : const Color(0xFFEF4444);
    final labelPrefix = isPrimary ? 'Primary: ' : 'Secondary: ';
    final cleanName = muscleName
        .split('-')
        .map((e) => e.isEmpty ? '' : e[0].toUpperCase() + e.substring(1))
        .join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: WorkoutColors.fill(context).withValues(alpha: isDark ? 0.15 : 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: WorkoutColors.border(context).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$labelPrefix$cleanName',
            style: GoogleFonts.inter(
              color: WorkoutColors.onSurface(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWgerSilhouette(
    BuildContext context, {
    required bool isBack,
    required List<int> primaryIds,
    required List<int> secondaryIds,
  }) {
    final viewName = isBack ? 'back' : 'front';
    final baseSilhouettePath =
        'assets/muscle_svgs/wger/muscular_system_$viewName.svg';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 140,
      height: 280,
      decoration: BoxDecoration(
        color: WorkoutColors.fill(context).withValues(alpha: isDark ? 0.2 : 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: WorkoutColors.border(context).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Base Wger Silhouette (Restoring Anatomical Details)
          // Increased opacity to make details (bones, fibers) more prominent
          Opacity(
            opacity: isDark ? 0.5 : 0.45,
            child: SvgPicture.asset(
              baseSilhouettePath,
              width: 120,
              height: 260,
              colorFilter: isDark
                  ? const ColorFilter.matrix(<double>[
                      -1,
                      0,
                      0,
                      0,
                      255,
                      0,
                      -1,
                      0,
                      0,
                      255,
                      0,
                      0,
                      -1,
                      0,
                      255,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ])
                  : null,
            ),
          ),

          // 2. Secondary Highlights
          for (final id in secondaryIds)
            Opacity(
              opacity: 0.85, // Let anatomical details show through
              child: SvgPicture.asset(
                'assets/muscle_svgs/wger/muscle-$id.svg',
                width: 120,
                height: 260,
                colorFilter: const ColorFilter.mode(
                  Color(0xFFEF4444), // Professional Red
                  BlendMode.srcIn,
                ),
              ),
            ),

          // 3. Primary Highlights (with Glow)
          for (final id in primaryIds)
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft Glow
                Opacity(
                  opacity: 0.3,
                  child: SvgPicture.asset(
                    'assets/muscle_svgs/wger/muscle-$id.svg',
                    width: 124,
                    height: 264,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4ADE80),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                // Main Highlight (slightly transparent for detail)
                Opacity(
                  opacity: 0.9,
                  child: SvgPicture.asset(
                    'assets/muscle_svgs/wger/muscle-$id.svg',
                    width: 120,
                    height: 260,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFF4ADE80), // Powerful Vibrant Lime
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
