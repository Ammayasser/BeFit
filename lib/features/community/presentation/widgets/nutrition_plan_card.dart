import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/befit_theme_extension.dart';

class NutritionPlanCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final double s;

  const NutritionPlanCard({
    super.key,
    required this.data,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final rawMeals = data['meals'] as List? ?? [];
    final meals = rawMeals.whereType<Map<String, dynamic>>().toList();
    final custom = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryAccent = custom.carbs;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: custom.surfaceCard,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: custom.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16 * s),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  custom.carbs.withValues(alpha: isDark ? 0.12 : 0.08),
                  custom.surfaceCard,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8 * s),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10 * s),
                  ),
                  child: Icon(Iconsax.note_2, color: primaryAccent, size: 20 * s),
                ),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Nutrition Plan',
                        style: GoogleFonts.montserrat(
                          fontSize: 16 * s,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (data['subtitle'] != null)
                        Text(
                          data['subtitle'],
                          style: GoogleFonts.inter(
                            fontSize: 11 * s,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100 * s),
                    border: Border.all(color: primaryAccent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${meals.length} meals',
                    style: GoogleFonts.montserrat(
                      fontSize: 10 * s,
                      fontWeight: FontWeight.w800,
                      color: primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Meal List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 8 * s),
            itemCount: meals.length,
            separatorBuilder: (_, index) => Divider(color: custom.border, height: 1),
            itemBuilder: (_, i) => _MealRow(meal: meals[i], index: i, s: s),
          ),

          // Coach Note
          if (data['coachNote'] != null)
            Container(
              margin: EdgeInsets.fromLTRB(16 * s, 0, 16 * s, 16 * s),
              padding: EdgeInsets.all(14 * s),
              decoration: BoxDecoration(
                color: primaryAccent.withValues(alpha: isDark ? 0.06 : 0.04),
                borderRadius: BorderRadius.circular(12 * s),
                border: Border.all(color: primaryAccent.withValues(alpha: isDark ? 0.15 : 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Iconsax.message_favorite, color: primaryAccent, size: 16 * s),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      data['coachNote'],
                      style: GoogleFonts.inter(
                        fontSize: 12 * s,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MealRow extends StatefulWidget {
  final Map<String, dynamic> meal;
  final int index;
  final double s;

  const _MealRow({
    required this.meal,
    required this.index,
    required this.s,
  });

  @override
  State<_MealRow> createState() => _MealRowState();
}

class _MealRowState extends State<_MealRow> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final meal = widget.meal;
    final index = widget.index;
    final custom = context.customColors;

    final primaryAccent = custom.carbs;

    final name = meal['name'] ?? '';
    final calories = meal['calories'] ?? meal['kcal'] ?? 0;
    final protein = meal['protein'] ?? 0;
    final carbs = meal['carbs'] ?? 0;
    final fat = meal['fat'] ?? 0;
    final rawFoods = meal['foods'] as List? ?? [];
    final foods = rawFoods.map((e) => e.toString()).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
            child: Row(
              children: [
                // Meal number circle
                Container(
                  width: 28 * s,
                  height: 28 * s,
                  decoration: BoxDecoration(
                    color: custom.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.montserrat(
                        fontSize: 11 * s,
                        fontWeight: FontWeight.w800,
                        color: primaryAccent,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),

                // Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'P: ${protein}g  •  C: ${carbs}g  •  F: ${fat}g',
                        style: GoogleFonts.inter(
                          fontSize: 11 * s,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Calories badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
                  decoration: BoxDecoration(
                    color: custom.surfaceElevated,
                    borderRadius: BorderRadius.circular(8 * s),
                    border: Border.all(color: custom.border),
                  ),
                  child: Text(
                    '$calories kcal',
                    style: GoogleFonts.montserrat(
                      fontSize: 12 * s,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),
                Icon(
                  _isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 14 * s,
                ),
              ],
            ),
          ),
        ),

        // Expanded food items list
        if (_isExpanded && foods.isNotEmpty)
          Container(
            width: double.infinity,
            color: custom.surfaceMuted.withValues(alpha: 0.5),
            padding: EdgeInsets.fromLTRB(56 * s, 8 * s, 16 * s, 16 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: foods.map((food) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 6 * s),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: GoogleFonts.inter(
                          fontSize: 14 * s,
                          color: primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          food,
                          style: GoogleFonts.inter(
                            fontSize: 12 * s,
                            color: Theme.of(context).colorScheme.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
