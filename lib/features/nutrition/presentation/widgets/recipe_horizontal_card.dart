// lib/features/nutrition/presentation/widgets/recipe_horizontal_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/recipe.dart';
import 'nutrition_colors.dart';
import 'recipe_lead_image.dart';
import 'recipe_meal_selection_sheet.dart';
import '../../data/models/meal_log.dart';

/// Compact recipe tile for horizontal section rails.
class RecipeHorizontalCard extends StatelessWidget {
  const RecipeHorizontalCard({
    super.key,
    required this.recipe,
    required this.onTap,
    required this.onFavoriteTap,
    this.onAddTap,
    this.width = 172,
  });

  final Recipe recipe;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;
  final Function(MealType)? onAddTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: NColors.bgSecondary(context),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
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
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Floating Slot Image section
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: AspectRatio(
                  aspectRatio: 16 / 10.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        RecipeLeadImage(
                          recipe: recipe,
                          variant: RecipeLeadImageVariant.card,
                        ),
                        // Glassmorphic Favorite
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
                                  recipe.isFavorite
                                      ? Iconsax.archive_15
                                      : Iconsax.archive_1,
                                  size: 14,
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
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                        color: NColors.textPrimary(context),
                        letterSpacing: -0.3,
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
                                  Icon(
                                    Iconsax.flash_1,
                                    size: 11,
                                    color: NColors.accentPrimary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${recipe.caloriesPerServing} kcal',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: NColors.textSecondary(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.timer_1,
                                    size: 11,
                                    color: NColors.textTertiary(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${recipe.totalTime} min',
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
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
                        // Small Premium Add button
                        Material(
                          color: NColors.accentPrimary(context),
                          borderRadius: BorderRadius.circular(12),
                          elevation: 2,
                          shadowColor: NColors.accentPrimary(context).withValues(alpha: 0.3),
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: Colors.white,
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
