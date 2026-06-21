// lib/features/workout/presentation/widgets/workout_screen/discovery_carousel.dart

import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import 'package:befit/core/router/app_routes.dart';
import 'package:befit/features/workout/presentation/providers/exercise_library_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'workout_hub_shared.dart';

class DiscoveryCategory {
  final String id;
  final String name;
  final String? imagePath;
  final String? filterKey; // Key used for filtering in the library

  const DiscoveryCategory({
    required this.id,
    required this.name,
    this.imagePath,
    this.filterKey,
  });
}

class DiscoveryCarousel extends StatelessWidget {
  final String title;
  final List<DiscoveryCategory> categories;
  final String filterType; // 'muscle' or 'equipment'
  final VoidCallback? onSeeAll;

  const DiscoveryCarousel({
    super.key,
    required this.title,
    required this.categories,
    required this.filterType,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final s = Responsive.scale(context, 1);
    final fs = Responsive.fontScale(context, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WorkoutHubSectionHeader(title: title, onSeeAll: onSeeAll, s: s, fs: fs),
        SizedBox(height: 16 * s),
        SizedBox(
          height: 195 * s,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20 * s),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            separatorBuilder: (_, _) => SizedBox(width: 16 * s),
            itemBuilder: (context, index) {
              return _DiscoveryCard(
                category: categories[index],
                filterType: filterType,
                index: index,
                s: s,
                fs: fs,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DiscoveryCard extends StatelessWidget {
  final DiscoveryCategory category;
  final String filterType;
  final int index;
  final double s;
  final double fs;

  const _DiscoveryCard({
    required this.category,
    required this.filterType,
    required this.index,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();

            // Apply filter to library provider
            final libraryProvider = context.read<ExerciseLibraryProvider>();
            if (filterType == 'muscle') {
              libraryProvider.applyFilter(
                bodyPart: category.filterKey ?? category.name,
              );
            } else {
              libraryProvider.applyFilter(
                equipment: category.filterKey ?? category.name,
              );
            }

            // Navigate to library
            context.push('${AppRoutes.workout}/library');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140 * s,
                height: 140 * s,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(28 * s),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12 * s,
                      offset: Offset(0, 6 * s),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(filterType == 'muscle' ? 8 * s : 16 * s),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28 * s),
                  child: _buildVisual(colors),
                ),
              ),
              SizedBox(height: 12 * s),
              Padding(
                padding: EdgeInsets.only(left: 6 * s),
                child: Text(
                  category.name,
                  style: GoogleFonts.montserrat(
                    fontSize: 14 * fs,
                    fontWeight: FontWeight.w700,
                    color: colors.setupTextPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        )
        .animate(delay: (index * 50).ms)
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildVisual(BeFitThemeExtension colors) {
    if (filterType == 'muscle') {
      return _DiscoveryMusclePreview(muscleName: category.name);
    }

    if (category.imagePath != null) {
      return Image.asset(
        category.imagePath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(colors),
      );
    }

    return _buildPlaceholder(colors);
  }

  Widget _buildPlaceholder(BeFitThemeExtension colors) {
    return Center(
      child: Icon(
        filterType == 'muscle' ? Icons.fitness_center : Icons.handyman_rounded,
        color: colors.setupPrimary.withValues(alpha: 0.3),
        size: 32 * s,
      ),
    );
  }
}

class _DiscoveryMusclePreview extends StatelessWidget {
  final String muscleName;

  const _DiscoveryMusclePreview({required this.muscleName});

  int _getMuscleId(String name) {
    final clean = name.trim().toLowerCase();
    if (clean.contains('chest')) return 4;
    if (clean.contains('abs') || clean.contains('oblique')) return 6;
    if (clean.contains('bicep')) return 1;
    if (clean.contains('tricep')) return 5;
    if (clean.contains('shoulder') || clean.contains('delt')) return 2;
    if (clean.contains('quad')) return 10;
    if (clean.contains('hamstring')) return 11;
    if (clean.contains('glute')) return 8;
    if (clean.contains('calf') || clean.contains('calve')) return 7;
    if (clean.contains('trapezius') || clean.contains('trap')) return 9;
    if (clean.contains('back') || clean.contains('lat')) return 12;
    return 1;
  }

  bool _isBackMuscle(int id) {
    return const [5, 7, 8, 9, 11, 12, 15, 16].contains(id);
  }

  @override
  Widget build(BuildContext context) {
    final id = _getMuscleId(muscleName);
    final isBack = _isBackMuscle(id);
    final viewName = isBack ? 'back' : 'front';
    final baseSilhouettePath = 'assets/muscle_svgs/wger/muscular_system_$viewName.svg';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Base Silhouette
          Opacity(
            opacity: isDark ? 0.25 : 0.15,
            child: SvgPicture.asset(
              baseSilhouettePath,
              fit: BoxFit.contain,
              colorFilter: isDark
                  ? const ColorFilter.matrix(<double>[
                      -1, 0, 0, 0, 255,
                      0, -1, 0, 0, 255,
                      0, 0, -1, 0, 255,
                      0, 0, 0, 1, 0,
                    ])
                  : null,
            ),
          ),
          // 2. Highlighted Muscle
          SvgPicture.asset(
            'assets/muscle_svgs/wger/muscle-$id.svg',
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Color(0xFF4ADE80), // Vibrant Lime
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
