// lib/features/nutrition/presentation/widgets/smart_meal_plan_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../../smart_plan/data/models/smart_meal_plan.dart';
import '../../../smart_plan/presentation/providers/smart_plan_provider.dart';

class SmartMealPlanCard extends StatefulWidget {
  const SmartMealPlanCard({super.key});

  @override
  State<SmartMealPlanCard> createState() => _SmartMealPlanCardState();
}

class _SmartMealPlanCardState extends State<SmartMealPlanCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = size.width / 390;
    final isTablet = size.width > 600;

    final smartPlan = context.watch<SmartPlanProvider>();
    final meal = smartPlan.mealPlan;

    if (meal == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 0 : 20 * s,
            vertical: 8 * s,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28 * s),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF0F172A), Color(0xFF1E1B4B)]
                  : const [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.15 : 0.08),
                blurRadius: 24 * s,
                offset: Offset(0, 8 * s),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28 * s),
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                _CardHeader(
                  plan: meal,
                  expanded: _expanded,
                  s: s,
                  onToggle: () {
                    setState(() => _expanded = !_expanded);
                  },
                ),

                // ── Stats Row ─────────────────────────────────────────────
                _StatsRow(plan: meal, s: s),

                // ── Expandable Meal Suggestions ───────────────────────────
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity, height: 0),
                  secondChild: _MealSuggestions(plan: meal, s: s),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 350),
                  sizeCurve: Curves.easeOutCubic,
                ),

                SizedBox(height: 4 * s),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.05, end: 0);
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _CardHeader extends StatelessWidget {
  final SmartMealPlan plan;
  final bool expanded;
  final VoidCallback onToggle;
  final double s;

  const _CardHeader({
    required this.plan,
    required this.expanded,
    required this.onToggle,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 20 * s, 20 * s, 8 * s),
      child: Row(
        children: [
          // Icon badge
          Container(
            padding: EdgeInsets.all(10 * s),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14 * s),
              border:
                  Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
            ),
            child: Icon(
              Iconsax.magic_star5,
              color: const Color(0xFF818CF8),
              size: 20 * s,
            ),
          ),
          SizedBox(width: 14 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Meal Plan',
                  style: GoogleFonts.montserrat(
                    color: textColor,
                    fontSize: 16 * s,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  plan.goal,
                  style: GoogleFonts.inter(
                    color: textColor.withValues(alpha: 0.5),
                    fontSize: 12 * s,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Calorie badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12 * s),
              border:
                  Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
            ),
            child: Text(
              '${plan.recommendedCalories.toInt()} kcal',
              style: GoogleFonts.montserrat(
                color: const Color(0xFF34D399),
                fontSize: 13 * s,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: 8 * s),
          // Expand toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textColor.withValues(alpha: 0.5),
                size: 22 * s,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SmartMealPlan plan;
  final double s;
  const _StatsRow({required this.plan, required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 16 * s),
      child: Row(
        children: [
          _StatItem(
            label: 'BMI',
            value: plan.bmi.toStringAsFixed(1),
            sub: plan.bmiCategory,
            color: _bmiColor(plan.bmi),
            s: s,
          ),
          _Divider(s: s),
          _StatItem(
            label: 'BMR',
            value: '${plan.bmr.toInt()}',
            sub: 'kcal/day',
            color: const Color(0xFF818CF8),
            s: s,
          ),
          _Divider(s: s),
          _StatItem(
            label: 'TDEE',
            value: '${plan.tdee.toInt()}',
            sub: 'kcal/day',
            color: const Color(0xFFF59E0B),
            s: s,
          ),
        ],
      ),
    );
  }

  Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFF60A5FA);
    if (bmi < 25.0) return const Color(0xFF34D399);
    if (bmi < 30.0) return const Color(0xFFFBBF24);
    return const Color(0xFFF87171);
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final double s;

  const _StatItem({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: textColor.withValues(alpha: 0.4),
              fontSize: 10 * s,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            value,
            style: GoogleFonts.montserrat(
              color: color,
              fontSize: 18 * s,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.inter(
              color: textColor.withValues(alpha: 0.35),
              fontSize: 10 * s,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final double s;
  const _Divider({required this.s});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 1,
      height: 40 * s,
      color: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.08),
    );
  }
}

// ── Meal Suggestions ─────────────────────────────────────────────────────────

class _MealSuggestions extends StatelessWidget {
  final SmartMealPlan plan;
  final double s;
  const _MealSuggestions({required this.plan, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * s, 0, 20 * s, 12 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 1,
            color: textColor.withValues(alpha: 0.07),
            margin: EdgeInsets.only(bottom: 16 * s),
          ),
          Text(
            'TODAY\'S MEAL SUGGESTIONS',
            style: GoogleFonts.montserrat(
              color: textColor.withValues(alpha: 0.35),
              fontSize: 10 * s,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12 * s),
          if (plan.breakfast.isNotEmpty)
            _MealGroup(
              icon: Icons.wb_sunny_rounded,
              mealName: 'Breakfast',
              color: const Color(0xFFFBBF24),
              recipes: plan.breakfast,
              s: s,
            ),
          if (plan.lunch.isNotEmpty)
            _MealGroup(
              icon: Icons.lunch_dining_rounded,
              mealName: 'Lunch',
              color: const Color(0xFF34D399),
              recipes: plan.lunch,
              s: s,
            ),
          if (plan.dinner.isNotEmpty)
            _MealGroup(
              icon: Icons.nightlight_round,
              mealName: 'Dinner',
              color: const Color(0xFF818CF8),
              recipes: plan.dinner,
              s: s,
            ),
        ],
      ),
    );
  }
}

class _MealGroup extends StatelessWidget {
  final IconData icon;
  final String mealName;
  final Color color;
  final List<SmartMealRecipe> recipes;
  final double s;

  const _MealGroup({
    required this.icon,
    required this.mealName,
    required this.color,
    required this.recipes,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    // Show top 2 recipes per meal
    final shown = recipes.take(2).toList();
    final totalCalories = shown.fold(0.0, (s, r) => s + r.calories);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Padding(
      padding: EdgeInsets.only(bottom: 16 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14 * s),
              SizedBox(width: 8 * s),
              Text(
                mealName,
                style: GoogleFonts.montserrat(
                  color: color,
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '~${totalCalories.toInt()} kcal',
                style: GoogleFonts.montserrat(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8 * s),
          ...shown.map((recipe) => _RecipeRow(recipe: recipe, color: color, s: s)),
        ],
      ),
    );
  }
}

class _RecipeRow extends StatelessWidget {
  final SmartMealRecipe recipe;
  final Color color;
  final double s;

  const _RecipeRow({required this.recipe, required this.color, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      margin: EdgeInsets.only(bottom: 6 * s),
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              recipe.food,
              style: GoogleFonts.montserrat(
                color: textColor.withValues(alpha: 0.85),
                fontSize: 13 * s,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 12 * s),
          _MacroTag(
            value: '${recipe.calories.toInt()}',
            unit: 'kcal',
            color: color,
            s: s,
          ),
          SizedBox(width: 6 * s),
          _MacroTag(
            value: '${recipe.protein.toStringAsFixed(0)}g',
            unit: 'P',
            color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
            s: s,
          ),
        ],
      ),
    );
  }
}

class _MacroTag extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  final double s;

  const _MacroTag({
    required this.value,
    required this.unit,
    required this.color,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMuted = color.a < 0.5;
    final tagBg = isMuted
        ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04))
        : color.withValues(alpha: 0.1);
    final tagTextColor = isMuted
        ? (isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF0F172A).withValues(alpha: 0.5))
        : color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(7 * s),
      ),
      child: Text(
        '$value $unit',
        style: GoogleFonts.montserrat(
          color: tagTextColor,
          fontSize: 10 * s,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
