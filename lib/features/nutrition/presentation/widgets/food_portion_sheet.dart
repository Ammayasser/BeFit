import 'dart:math';

import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../data/models/food_item.dart';
import '../../data/models/meal_log.dart';
import '../providers/nutrition_provider.dart';

class FoodPortionSheet extends StatefulWidget {
  final FoodItem food;
  final MealType? preSelectedMeal;

  const FoodPortionSheet({super.key, required this.food, this.preSelectedMeal});

  @override
  State<FoodPortionSheet> createState() => _FoodPortionSheetState();
}

class _FoodPortionSheetState extends State<FoodPortionSheet> {
  late MealType _selectedMeal;
  late double _grams;
  late TextEditingController _gramsController;
  late TextEditingController _servingsController;
  double _servings = 1.0;

  @override
  void initState() {
    super.initState();
    _selectedMeal =
        widget.preSelectedMeal ??
        context.read<NutritionProvider>().suggestedMealType;
    _grams = widget.food.servingGrams ?? 100.0;
    _gramsController = TextEditingController(text: _grams.toInt().toString());
    _servingsController = TextEditingController(
      text: _servings == _servings.toInt()
          ? _servings.toInt().toString()
          : _servings.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _gramsController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  double get _calories => widget.food.caloriesFor(_grams);
  double get _protein => widget.food.proteinFor(_grams);
  double get _carbs => widget.food.carbsFor(_grams);
  double get _fat => widget.food.fatFor(_grams);

  void _syncServingsFromGrams() {
    final servingG = widget.food.servingGrams ?? 100.0;
    _servings = _grams / servingG;
    _servingsController.text = _servings == _servings.toInt()
        ? _servings.toInt().toString()
        : _servings.toStringAsFixed(1);
  }

  void _nudgeGrams(double delta) {
    HapticFeedback.selectionClick();
    setState(() {
      _grams = (_grams + delta).clamp(1, 5000);
      _gramsController.text = _grams.toInt().toString();
      _syncServingsFromGrams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final s = media.size.width / 390;
    final h = media.size.height;
    final bottomPadding = media.viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;

    return Container(
      constraints: BoxConstraints(maxHeight: h * 0.94),
      decoration: BoxDecoration(
        color: isDark ? colors.bgSecondary : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LuxuryModalHeader(s: s),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24 * s,
                8 * s,
                24 * s,
                bottomPadding + 24 * s,
              ),
              child: Column(
                children: [
                  _FoodSimpleCard(food: widget.food, s: s),
                  SizedBox(height: 24 * s),

                  _LuxuryMealPicker(
                    selected: _selectedMeal,
                    onChanged: (m) => setState(() => _selectedMeal = m),
                    s: s,
                  ),

                  SizedBox(height: 32 * s),

                  _LuxuryPortionEditor(
                    controller: _gramsController,
                    onNudge: _nudgeGrams,
                    s: s,
                  ),

                  SizedBox(height: 32 * s),

                  _LuxuryMacroSummary(
                    calories: _calories,
                    protein: _protein,
                    carbs: _carbs,
                    fat: _fat,
                    s: s,
                  ),
                ],
              ),
            ),
          ),

          _LuxuryLogButton(
            meal: _selectedMeal,
            onLog: () => _handleLog(context),
            s: s,
          ),
        ],
      ),
    );
  }

  Future<void> _handleLog(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final provider = context.read<NutritionProvider>();
    await provider.addFoodLog(_selectedMeal, widget.food, _grams);

    if (mounted) {
      _showLuxurySuccess();
    }
  }

  void _showLuxurySuccess() {
    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? colors.surfaceElevated : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.success.withValues(alpha: 0.15)
                      : const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: colors.success,
                  size: 40,
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                'Added',
                style: GoogleFonts.montserrat(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ).animate().fadeIn(),
      ),
    );

    Future.delayed(1100.ms, () {
      if (mounted) {
        navigator.pop(); // Close dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) navigator.pop({'success': true});
        });
      }
    });
  }
}

class _LuxuryModalHeader extends StatelessWidget {
  final double s;
  const _LuxuryModalHeader({required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? colors.border : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Iconsax.close_circle,
                  color: isDark ? colors.chartLabel : const Color(0xFFCBD5E1),
                  size: 24 * s,
                ),
              ),
              Expanded(
                child: Text(
                  'Log Entry',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 18 * s,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodSimpleCard extends StatelessWidget {
  final FoodItem food;
  final double s;
  const _FoodSimpleCard({required this.food, required this.s});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 52 * s,
          height: 52 * s,
          decoration: BoxDecoration(
            color: isDark ? colors.bgPrimary : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14 * s),
            border: Border.all(color: isDark ? colors.border : const Color(0xFFF1F5F9)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14 * s),
            child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: food.imageUrl!,
                    fit: BoxFit.cover,
                  )
                : Center(
                    child: Text(
                      food.name[0].toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 20 * s,
                        fontWeight: FontWeight.w800,
                        color: isDark ? colors.chartLabel : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
          ),
        ),
        SizedBox(width: 14 * s),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                food.name,
                style: GoogleFonts.montserrat(
                  fontSize: 18 * s,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                food.brand ?? 'Standard Portion',
                style: GoogleFonts.inter(
                  fontSize: 12 * s,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LuxuryMealPicker extends StatelessWidget {
  final MealType selected;
  final Function(MealType) onChanged;
  final double s;
  const _LuxuryMealPicker({
    required this.selected,
    required this.onChanged,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: MealType.values.map((m) {
        final isSel = selected == m;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(m),
            child: AnimatedContainer(
              duration: 250.ms,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(vertical: 10 * s),
              decoration: BoxDecoration(
                color: isSel ? colorScheme.onSurface : (isDark ? colors.surfaceCard : Colors.white),
                borderRadius: BorderRadius.circular(14 * s),
                border: Border.all(
                  color: isSel
                      ? colorScheme.onSurface
                      : (isDark ? colors.border : const Color(0xFFF1F5F9)),
                ),
              ),
              child: Center(
                child: Text(
                  m.displayName,
                  style: GoogleFonts.inter(
                    color: isSel ? (isDark ? colors.bgPrimary : Colors.white) : colorScheme.onSurfaceVariant,
                    fontSize: 11 * s,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LuxuryPortionEditor extends StatelessWidget {
  final TextEditingController controller;
  final Function(double) onNudge;
  final double s;
  const _LuxuryPortionEditor({
    required this.controller,
    required this.onNudge,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleNudge(
              icon: Icons.remove_rounded,
              onTap: () => onNudge(-10),
              s: s,
            ),
            SizedBox(width: 24 * s),
            Flexible(
              child: IntrinsicWidth(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    color: colorScheme.onSurface,
                    fontSize: 56 * s,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    suffixText: 'g',
                    suffixStyle: GoogleFonts.montserrat(
                      color: isDark ? colors.chartLabel : const Color(0xFFCBD5E1),
                      fontSize: 20 * s,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 24 * s),
            _CircleNudge(
              icon: Icons.add_rounded,
              onTap: () => onNudge(10),
              s: s,
            ),
          ],
        ),
        SizedBox(height: 8 * s),
        Text(
          'ADJUST PORTION',
          style: GoogleFonts.montserrat(
            color: isDark ? colors.chartLabel : const Color(0xFFCBD5E1),
            fontSize: 10 * s,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _CircleNudge extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double s;
  const _CircleNudge({
    required this.icon,
    required this.onTap,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isDark ? colors.surfaceCard : const Color(0xFFF8FAFC),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44 * s,
          height: 44 * s,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? colors.border : const Color(0xFFF1F5F9)),
          ),
          child: Icon(icon, color: colorScheme.onSurface, size: 20 * s),
        ),
      ),
    );
  }
}

class _LuxuryMacroSummary extends StatelessWidget {
  final double calories, protein, carbs, fat;
  final double s;
  const _LuxuryMacroSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: isDark ? colors.bgPrimary : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: isDark ? colors.border : const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                calories.toInt().toString(),
                style: GoogleFonts.montserrat(
                  color: colorScheme.onSurface,
                  fontSize: 28 * s,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 4 * s),
              Text(
                'kcal',
                style: GoogleFonts.montserrat(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11 * s,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * s),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _LuxuryMacro(
                label: 'PRO',
                value: protein,
                color: colors.protein,
                s: s,
              ),
              _LuxuryMacro(
                label: 'CARB',
                value: carbs,
                color: colors.carbs,
                s: s,
              ),
              _LuxuryMacro(
                label: 'FAT',
                value: fat,
                color: colors.fat,
                s: s,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LuxuryMacro extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final double s;
  const _LuxuryMacro({
    required this.label,
    required this.value,
    required this.color,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toInt()}g',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14 * s,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: color,
            fontSize: 8 * s,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _LuxuryLogButton extends StatelessWidget {
  final MealType meal;
  final VoidCallback onLog;
  final double s;
  const _LuxuryLogButton({
    required this.meal,
    required this.onLog,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24 * s,
        12 * s,
        24 * s,
        max(12 * s, MediaQuery.paddingOf(context).bottom + 12 * s),
      ),
      decoration: BoxDecoration(
        color: isDark ? colors.bgSecondary : Colors.white,
        border: Border(top: BorderSide(color: isDark ? colors.border : const Color(0xFFF1F5F9))),
      ),
      child: Material(
        color: colorScheme.onSurface,
        borderRadius: BorderRadius.circular(16 * s),
        child: InkWell(
          onTap: onLog,
          borderRadius: BorderRadius.circular(16 * s),
          child: Container(
            height: 54 * s,
            alignment: Alignment.center,
            child: Text(
              'Add to ${meal.displayName}',
              style: GoogleFonts.montserrat(
                color: isDark ? colors.bgPrimary : Colors.white,
                fontSize: 15 * s,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
