// lib/features/nutrition/presentation/widgets/recipe_lead_image.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../data/models/recipe.dart';

enum RecipeLeadImageVariant { card, hero }

/// Cuisine gradient + Spoonacular recipe photo when [Recipe.imageUrl] is set.
class RecipeLeadImage extends StatelessWidget {
  const RecipeLeadImage({
    super.key,
    required this.recipe,
    this.variant = RecipeLeadImageVariant.card,
  });

  final Recipe recipe;
  final RecipeLeadImageVariant variant;

  static LinearGradient _gradientForCuisine(String? cuisine) {
    switch (cuisine?.toLowerCase()) {
      case 'italian':
        return const LinearGradient(
          colors: [Color(0xFF2D8A4E), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'japanese':
        return const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'mexican':
        return const LinearGradient(
          colors: [Color(0xFF92400E), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'french':
        return const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'thai':
        return const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF475569)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _gradientForCuisine(recipe.cuisine);
    final isHero = variant == RecipeLeadImageVariant.hero;
    final url = recipe.imageUrl;

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: base)),
        if (url != null && url.isNotEmpty)
          CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 220),
            placeholder: (_, _) => const SizedBox.shrink(),
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        if (isHero)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.0),
                  Colors.black.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
