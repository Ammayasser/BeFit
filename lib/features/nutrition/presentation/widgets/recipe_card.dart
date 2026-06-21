// lib/features/nutrition/presentation/widgets/recipe_card.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/recipe.dart';
import 'nutrition_colors.dart';
import 'recipe_lead_image.dart';
import 'recipe_meal_selection_sheet.dart';
import '../../data/models/meal_log.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final Function(MealType)? onAddTap;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavoriteTap,
    this.onAddTap,
  });

  static Color difficultyColor(BuildContext context, String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return NColors.accentPrimary(context);
      case 'medium':
        return NColors.warningAccent(context);
      case 'hard':
        return NColors.dangerAccent(context);
      default:
        return NColors.textTertiary(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NColors.bgSecondary(context),
            NColors.bgSecondary(context).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: NColors.divider(context).withValues(alpha: 0.3),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section with "Floating" slot design
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _ImageHeader(
                          recipe: recipe,
                          onFavoriteTap: onFavoriteTap,
                        ),
                      ),
                    ),
                    // Glassmorphic Time Badge
                    Positioned(
                      left: 10,
                      top: 10,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.timer_1,
                                  size: 10,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${recipe.totalTime}m',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        color: NColors.textPrimary(context),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: NColors.accentPrimary(context)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Iconsax.flash_1,
                                      size: 10,
                                      color: NColors.accentPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${recipe.caloriesPerServing} kcal',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: NColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: NColors.accentSecondary(context)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Iconsax.weight,
                                      size: 10,
                                      color: NColors.accentSecondary(context),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${recipe.protein}g Protein',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: NColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Ultra-Modern Tactile Button
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: NColors.accentPrimary(context)
                                    .withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: NColors.accentPrimary(context),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.mediumImpact();
                                RecipeMealSelectionSheet.show(
                                  context,
                                  recipe: recipe,
                                  onSelected: (type) {
                                    if (onAddTap != null) {
                                      onAddTap!(type);
                                    }
                                  },
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: 42,
                                height: 42,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.add_rounded,
                                  size: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}


class _ImageHeader extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onFavoriteTap;

  const _ImageHeader({required this.recipe, required this.onFavoriteTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RecipeLeadImage(recipe: recipe, variant: RecipeLeadImageVariant.card),
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: NColors.bgSecondary(context).withValues(alpha: 0.9),
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onFavoriteTap,
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    recipe.isFavorite ? Iconsax.archive_15 : Iconsax.archive_1,
                    size: 16,
                    color: recipe.isFavorite
                        ? NColors.accentPrimary(context)
                        : NColors.textPrimary(context),
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
