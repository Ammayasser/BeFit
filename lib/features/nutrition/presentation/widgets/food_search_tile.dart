// lib/features/nutrition/presentation/widgets/food_search_tile.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/food_item.dart';
import 'nutrition_colors.dart';

class FoodSearchTile extends StatelessWidget {
  final FoodItem food;
  final VoidCallback onTap;
  /// Matches selected meal accent from [AddFoodBottomSheet].
  final Color? accentColor;

  const FoodSearchTile({
    super.key,
    required this.food,
    required this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = food.isGeneric;
    final accent = accentColor ?? NColors.accentSecondary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final servingText =
        food.servingSize ?? '${food.servingGrams?.toInt() ?? 100} gram';

    final displayCalories = food.servingGrams != null
        ? food.caloriesFor(food.servingGrams!).round()
        : food.caloriesPer100g.round();

    final subtitleParts = <String>['$displayCalories cal', servingText];
    if (food.brand != null && food.brand!.isNotEmpty) {
      subtitleParts.add(food.brand!);
    }
    final subtitle = subtitleParts.join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: accent.withValues(alpha: 0.1),
          highlightColor: accent.withValues(alpha: 0.05),
          child: Ink(
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Color.lerp(
                  isDark ? colorScheme.outline : const Color(0xFFE2E8F0),
                  accent,
                  0.2,
                )!,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: accent.withValues(alpha: isDark ? 0.12 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                food.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Iconsax.verify5,
                                color: NColors.accentPrimary(context),
                                size: 18,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.2),
                          accent.withValues(alpha: 0.08),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Iconsax.add,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
