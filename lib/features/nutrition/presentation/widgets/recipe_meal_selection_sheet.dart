// lib/features/nutrition/presentation/widgets/recipe_meal_selection_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/meal_log.dart';
import '../../data/models/recipe.dart';
import 'nutrition_colors.dart';

class RecipeMealSelectionSheet extends StatelessWidget {
  final Recipe recipe;
  final Function(MealType) onSelected;

  const RecipeMealSelectionSheet({
    super.key,
    required this.recipe,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required Recipe recipe,
    required Function(MealType) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RecipeMealSelectionSheet(
        recipe: recipe,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.only(bottom: bottom),
      decoration: BoxDecoration(
        color: NColors.bgSecondary(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: NColors.divider(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Add to Diary',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: NColors.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Which meal would you like to add\n"${recipe.name}" to?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: NColors.textSecondary(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Selection Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _MealOption(
                  type: MealType.breakfast,
                  icon: Iconsax.coffee,
                  color: NColors.warningAccent(context),
                  onTap: () => _handleSelect(context, MealType.breakfast),
                ),
                _MealOption(
                  type: MealType.lunch,
                  icon: Iconsax.sun_1,
                  color: NColors.accentPrimary(context),
                  onTap: () => _handleSelect(context, MealType.lunch),
                ),
                _MealOption(
                  type: MealType.dinner,
                  icon: Iconsax.moon,
                  color: NColors.accentSecondary(context),
                  onTap: () => _handleSelect(context, MealType.dinner),
                ),
                _MealOption(
                  type: MealType.snacks,
                  icon: Iconsax.flash_1,
                  color: NColors.purple,
                  onTap: () => _handleSelect(context, MealType.snacks),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  void _handleSelect(BuildContext context, MealType type) {
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    onSelected(type);
  }
}

class _MealOption extends StatelessWidget {
  final MealType type;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MealOption({
    required this.type,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                type.displayName,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: NColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
