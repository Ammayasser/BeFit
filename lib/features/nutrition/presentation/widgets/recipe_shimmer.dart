// lib/features/nutrition/presentation/widgets/recipe_shimmer.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'nutrition_colors.dart';

/// Placeholder grid tile matching [RecipeCard] proportions.
class RecipeShimmerCard extends StatelessWidget {
  const RecipeShimmerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: NColors.bgSecondary(context),
        borderRadius: BorderRadius.circular(NColors.radiusCard),
        boxShadow: NColors.cardGlow(context),
        border: Border.all(color: NColors.divider(context).withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(NColors.radiusCard),
              ),
              color: NColors.divider(context).withValues(alpha: 0.35),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(
                duration: 1200.ms,
                color: Colors.white.withValues(alpha: 0.55),
              ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 64,
                  decoration: BoxDecoration(
                    color: NColors.divider(context).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                const SizedBox(height: 10),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: NColors.divider(context).withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                const SizedBox(height: 6),
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: NColors.divider(context).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: NColors.divider(context).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shimmer(
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
