// lib/features/nutrition/presentation/widgets/meal_section.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/core/utils/responsive.dart';
import '../../data/models/meal_log.dart';
import '../../../smart_plan/data/models/smart_meal_plan.dart';
import 'nutrition_colors.dart';

class MealSection extends StatefulWidget {
  final MealType mealType;
  final IconData icon;
  final List<MealLog> foodLogs;
  final double mealCalories;
  final double mealGoal;
  final VoidCallback onAddFood;
  final void Function(String logId, MealLog log) onDeleteFood;
  final List<SmartMealRecipe>? suggestions;
  final void Function(SmartMealRecipe recipe)? onAddSuggestion;

  const MealSection({
    super.key,
    required this.mealType,
    required this.icon,
    required this.foodLogs,
    required this.mealCalories,
    this.mealGoal = 500,
    required this.onAddFood,
    required this.onDeleteFood,
    this.suggestions,
    this.onAddSuggestion,
  });

  @override
  State<MealSection> createState() => _MealSectionState();
}

class _MealSectionState extends State<MealSection> {
  bool _isExpanded = true;

  // Modern, high-end accents
  Color _getMealAccent(BuildContext context) {
    switch (widget.mealType) {
      case MealType.breakfast:
        return const Color(0xFF10B981); // Mint Sage Green
      case MealType.lunch:
        return const Color(0xFF0EA5E9); // Sky Cyan Blue
      case MealType.dinner:
        return const Color(0xFF8B5CF6); // Lavender Violet
      case MealType.snacks:
        return const Color(0xFFF59E0B); // Amber Orange Gold
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = Responsive.scale(context, 1.0);
    final fs = Responsive.fontScale(context, 1.0);
    final isTablet = size.width > 600;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final customColors = context.customColors;

    final accentColor = _getMealAccent(context);
    
    // Muted deep backgrounds for panels to prevent bright glowing cards
    final cardBg = isDark ? const Color(0xFF1A1D24) : Colors.white;
    final expandedWellBg = isDark ? const Color(0xFF111318) : const Color(0xFFF5F7F6);
    final innerCardBg = isDark ? const Color(0xFF16181D) : const Color(0xFFEBEFED);

    final calProgress = widget.mealGoal > 0 
        ? (widget.mealCalories / widget.mealGoal).clamp(0.0, 1.0)
        : 0.0;
    final caloriesLeft = (widget.mealGoal - widget.mealCalories).clamp(0.0, widget.mealGoal).toInt();

    // Aggregate meal macros
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    
    // Default meal macro goals (scaled fraction of standard daily needs)
    const mealProteinGoal = 40.0;
    const mealCarbsGoal = 75.0;
    const mealFatGoal = 20.0;

    for (final log in widget.foodLogs) {
      totalProtein += log.loggedProtein;
      totalCarbs += log.loggedCarbs;
      totalFat += log.loggedFat;
    }

    final proteinProgress = (totalProtein / mealProteinGoal).clamp(0.0, 1.0);
    final carbsProgress = (totalCarbs / mealCarbsGoal).clamp(0.0, 1.0);
    final fatProgress = (totalFat / mealFatGoal).clamp(0.0, 1.0);
    
    // Average of macros progress for inner circle
    final avgMacroProgress = ((proteinProgress + carbsProgress + fatProgress) / 3.0).clamp(0.0, 1.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 0 : 20 * s,
            vertical: 10 * s,
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24 * s),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFF111827).withValues(alpha: 0.04),
              width: 1.0 * s,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                blurRadius: 20 * s,
                offset: Offset(0, 6 * s),
              ),
              if (widget.foodLogs.isNotEmpty)
                BoxShadow(
                  color: accentColor.withValues(alpha: isDark ? 0.03 : 0.01),
                  blurRadius: 30 * s,
                  spreadRadius: -5 * s,
                  offset: Offset(0, 10 * s),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23 * s),
            child: Stack(
              children: [
                // 1. Content Column
                Column(
                  children: [
                    // Sleek Header Row
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _isExpanded = !_isExpanded);
                        },
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16 * s, 16 * s, 16 * s, 16 * s),
                          child: Row(
                            children: [
                              // Glowing Icon Circle Frame
                              Container(
                                width: 42 * s,
                                height: 42 * s,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                    width: 1.5 * s,
                                  ),
                                ),
                                child: Icon(
                                  widget.icon,
                                  color: accentColor,
                                  size: 18 * s,
                                ),
                              ),
                              SizedBox(width: 12 * s),
                              
                              // Title (Normal/Heavy weight split for professional styling)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          _getSplitTitleFirstPart(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 15.5 * fs,
                                            fontWeight: FontWeight.w400,
                                            color: NColors.textPrimary(context),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        Text(
                                          _getSplitTitleSecondPart(),
                                          style: GoogleFonts.montserrat(
                                            fontSize: 15.5 * fs,
                                            fontWeight: FontWeight.w900,
                                            color: NColors.textPrimary(context),
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Iconsax.flash_1, size: 12 * s, color: accentColor),
                                        SizedBox(width: 3 * s),
                                        Text(
                                          '${widget.mealCalories.toInt()} kcal',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11.5 * fs,
                                            fontWeight: FontWeight.w800,
                                            color: NColors.textSecondary(context),
                                          ),
                                        ),
                                        Text(
                                          '  •  Goal ${widget.mealGoal.toInt()} kcal',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11 * fs,
                                            fontWeight: FontWeight.w600,
                                            color: NColors.textSecondary(context).withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Overlapping Concentric Circular Progress Ring
                              SizedBox(
                                width: 58 * s,
                                height: 58 * s,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      size: Size(50 * s, 50 * s),
                                      painter: _DoubleProgressPainter(
                                        calorieProgress: calProgress,
                                        macroProgress: avgMacroProgress,
                                        color: accentColor,
                                        trackColor: isDark 
                                            ? Colors.white.withValues(alpha: 0.05) 
                                            : Colors.black.withValues(alpha: 0.04),
                                        strokeWidth: 3.5 * s,
                                      ),
                                    ),
                                    Text(
                                      '${(calProgress * 100).round()}%',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 11 * fs,
                                        fontWeight: FontWeight.w800,
                                        color: NColors.textPrimary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              
                              // Rotating Chevron
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: NColors.textSecondary(context).withValues(alpha: 0.4),
                                  size: 20 * s,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Expandable Panel
                    AnimatedCrossFade(
                      firstChild: const SizedBox(width: double.infinity),
                      secondChild: Container(
                        width: double.infinity,
                        color: expandedWellBg,
                        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 16 * s),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Macronutrients Horizontal Dashboard Row
                            Row(
                              children: [
                                Expanded(
                                  child: _MacroCapsule(
                                    label: 'PRO',
                                    current: totalProtein,
                                    goal: mealProteinGoal,
                                    color: customColors.protein,
                                    s: s,
                                    fs: fs,
                                    innerCardBg: innerCardBg,
                                  ),
                                ),
                                SizedBox(width: 8 * s),
                                Expanded(
                                  child: _MacroCapsule(
                                    label: 'CARB',
                                    current: totalCarbs,
                                    goal: mealCarbsGoal,
                                    color: customColors.carbs,
                                    s: s,
                                    fs: fs,
                                    innerCardBg: innerCardBg,
                                  ),
                                ),
                                SizedBox(width: 8 * s),
                                Expanded(
                                  child: _MacroCapsule(
                                    label: 'FAT',
                                    current: totalFat,
                                    goal: mealFatGoal,
                                    color: customColors.fat,
                                    s: s,
                                    fs: fs,
                                    innerCardBg: innerCardBg,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 18 * s),

                            // Section Title & Add Action
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.foodLogs.isEmpty ? 'LOGGED FOODS' : 'TIMELINE FEED',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 10 * fs,
                                    fontWeight: FontWeight.w800,
                                    color: NColors.textSecondary(context).withValues(alpha: 0.5),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                _SmallAddButton(
                                  onTap: widget.onAddFood,
                                  accentColor: accentColor,
                                  s: s,
                                  fs: fs,
                                ),
                              ],
                            ),
                            SizedBox(height: 10 * s),

                            // Timeline Feed List
                            if (widget.foodLogs.isNotEmpty)
                              Stack(
                                children: [
                                  // Smooth vertical timeline guideline
                                  Positioned(
                                    left: 13 * s,
                                    top: 18 * s,
                                    bottom: 18 * s,
                                    child: Container(
                                      width: 1.5 * s,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            accentColor.withValues(alpha: 0.5),
                                            accentColor.withValues(alpha: 0.05),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Timeline Food Rows
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: widget.foodLogs.length,
                                    separatorBuilder: (context, index) => SizedBox(height: 12 * s),
                                    itemBuilder: (context, index) {
                                      final log = widget.foodLogs[index];
                                      return _buildTimelineRow(context, log, accentColor, s, fs, customColors, innerCardBg);
                                    },
                                  ),
                                ],
                              )
                            else
                              // Clean borderless empty state card
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 24 * s, horizontal: 16 * s),
                                decoration: BoxDecoration(
                                  color: innerCardBg,
                                  borderRadius: BorderRadius.circular(16 * s),
                                  border: Border.all(
                                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Iconsax.document_favorite,
                                      size: 20 * s,
                                      color: NColors.textSecondary(context).withValues(alpha: 0.3),
                                    ),
                                    SizedBox(height: 8 * s),
                                    Text(
                                      'No meals logged yet today.',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 12 * fs,
                                        fontWeight: FontWeight.w600,
                                        color: NColors.textSecondary(context).withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // AI suggestions carousel
                            if (widget.suggestions != null && widget.suggestions!.isNotEmpty) ...[
                              SizedBox(height: 20 * s),
                              _buildHorizontalSuggestions(context, widget.suggestions!, accentColor, s, fs, innerCardBg),
                            ],

                            SizedBox(height: 16 * s),

                            // Mini Calorie Limit Bar
                            Container(
                              padding: EdgeInsets.all(12 * s),
                              decoration: BoxDecoration(
                                color: innerCardBg,
                                borderRadius: BorderRadius.circular(16 * s),
                                border: Border.all(
                                  color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        calProgress >= 1.0 ? 'Goal Completed!' : 'Remaining Calories',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11 * fs,
                                          fontWeight: FontWeight.w700,
                                          color: NColors.textSecondary(context),
                                        ),
                                      ),
                                      Text(
                                        calProgress >= 1.0 ? '100%' : '$caloriesLeft kcal remaining',
                                        style: GoogleFonts.montserrat(
                                          fontSize: 11 * fs,
                                          fontWeight: FontWeight.w800,
                                          color: calProgress >= 1.0 ? accentColor : NColors.textPrimary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8 * s),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4 * s),
                                    child: SizedBox(
                                      height: 5 * s,
                                      child: Stack(
                                        children: [
                                          Container(
                                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                          ),
                                          FractionallySizedBox(
                                            widthFactor: calProgress,
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [accentColor, accentColor.withValues(alpha: 0.7)],
                                                ),
                                                borderRadius: BorderRadius.circular(4 * s),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      crossFadeState: _isExpanded 
                          ? CrossFadeState.showSecond 
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 350),
                      sizeCurve: Curves.easeInOutCubic,
                    ),
                  ],
                ),

                // 2. Positioned Left Accent Line (drawn on top of background panels)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4.5 * s,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic);
  }

  // Formatting helpers for meal title parts
  String _getSplitTitleFirstPart() {
    final name = widget.mealType.displayName;
    if (name.length > 5) {
      return name.substring(0, 5).toUpperCase();
    }
    return name.toUpperCase();
  }

  String _getSplitTitleSecondPart() {
    final name = widget.mealType.displayName;
    if (name.length > 5) {
      return name.substring(5).toUpperCase();
    }
    return '';
  }

  // Timeline list item row builder
  Widget _buildTimelineRow(
    BuildContext context, 
    MealLog log, 
    Color accentColor, 
    double s, 
    double fs,
    BeFitThemeExtension customColors,
    Color innerCardBg
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final food = log.foodItem;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Timeline Glowing node dot
        SizedBox(
          width: 28 * s,
          child: Center(
            child: Container(
              width: 7 * s,
              height: 7 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.6),
                    blurRadius: 5 * s,
                    spreadRadius: 1 * s,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 4 * s),

        // Borderless Food capsule row
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8 * s, horizontal: 12 * s),
            decoration: BoxDecoration(
              color: innerCardBg,
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                width: 1 * s,
              ),
            ),
            child: Row(
              children: [
                // Network Food Image or letter thumbnail
                Container(
                  width: 38 * s,
                  height: 38 * s,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF22252F) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10 * s),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10 * s),
                    child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: food.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: accentColor.withValues(alpha: 0.05)),
                          )
                        : Center(
                            child: Text(
                              food.name.isNotEmpty ? food.name[0].toUpperCase() : 'F',
                              style: GoogleFonts.montserrat(
                                fontSize: 16 * s,
                                fontWeight: FontWeight.w900,
                                color: accentColor,
                              ),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: 12 * s),

                // Name & Macro breakdown details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13 * fs,
                          fontWeight: FontWeight.w800,
                          color: NColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          children: [
                            Text(
                              '${log.loggedCalories.toInt()} kcal',
                              style: GoogleFonts.montserrat(
                                fontSize: 10.5 * fs,
                                fontWeight: FontWeight.w700,
                                color: NColors.textSecondary(context),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                color: NColors.textSecondary(context).withValues(alpha: 0.3),
                                fontSize: 10 * fs,
                              ),
                            ),
                            _miniMacroText('${log.loggedProtein.round()}g P', customColors.protein, fs),
                            const SizedBox(width: 4),
                            _miniMacroText('${log.loggedCarbs.round()}g C', customColors.carbs, fs),
                            const SizedBox(width: 4),
                            _miniMacroText('${log.loggedFat.round()}g F', customColors.fat, fs),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * s),

                // Delete Icon Action
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onDeleteFood(log.id, log),
                    borderRadius: BorderRadius.circular(10 * s),
                    child: Container(
                      width: 28 * s,
                      height: 28 * s,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: theme.colorScheme.error.withValues(alpha: 0.7),
                        size: 16 * s,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _miniMacroText(String text, Color color, double fs) {
    return Text(
      text,
      style: GoogleFonts.montserrat(
        fontSize: 10 * fs,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }

  // Horizontal AI recommendations deck
  Widget _buildHorizontalSuggestions(
    BuildContext context,
    List<SmartMealRecipe> recipes,
    Color accentColor,
    double s,
    double fs,
    Color innerCardBg
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 8 * s),
          child: Row(
            children: [
              Icon(Iconsax.magic_star, size: 13 * s, color: accentColor),
              SizedBox(width: 6 * s),
              Text(
                'AI SUGGESTIONS',
                style: GoogleFonts.montserrat(
                  fontSize: 9.5 * fs,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 56 * s,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: recipes.length,
            separatorBuilder: (context, index) => SizedBox(width: 10 * s),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Container(
                width: 170 * s,
                padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 8 * s),
                decoration: BoxDecoration(
                  color: innerCardBg,
                  borderRadius: BorderRadius.circular(14 * s),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.1),
                    width: 1 * s,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            recipe.food,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 11.5 * fs,
                              fontWeight: FontWeight.w800,
                              color: NColors.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${recipe.calories.toInt()} kcal · ${recipe.protein.toInt()}g P',
                            style: GoogleFonts.montserrat(
                              fontSize: 9.5 * fs,
                              fontWeight: FontWeight.w600,
                              color: NColors.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    
                    // Simple Add Circle Button
                    Material(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onAddSuggestion?.call(recipe);
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 24 * s,
                          height: 24 * s,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.add_rounded,
                            color: accentColor,
                            size: 15 * s,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Double Concentric Ring Painter
// ─────────────────────────────────────────────────────────────────────────────

class _DoubleProgressPainter extends CustomPainter {
  final double calorieProgress;
  final double macroProgress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _DoubleProgressPainter({
    required this.calorieProgress,
    required this.macroProgress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Outer Ring (Calorie progress)
    final radius1 = (size.width - strokeWidth) / 2;
    final rect1 = Rect.fromCircle(center: center, radius: radius1);

    // Inner Ring (Macro average progress)
    final radius2 = radius1 - strokeWidth - 2.5;
    final rect2 = Rect.fromCircle(center: center, radius: radius2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Draw tracks
    canvas.drawCircle(center, radius1, trackPaint);
    canvas.drawCircle(center, radius2, trackPaint);

    const startAngle = -math.pi / 2;

    // Active Outer ring sweep
    if (calorieProgress > 0) {
      final activePaint1 = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final sweepAngle1 = 2 * math.pi * calorieProgress;
      canvas.drawArc(rect1, startAngle, sweepAngle1, false, activePaint1);
    }

    // Active Inner ring sweep (toned down opacity to create visual hierarchy)
    if (macroProgress > 0) {
      final activePaint2 = Paint()
        ..color = color.withValues(alpha: 0.60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle2 = 2 * math.pi * macroProgress;
      canvas.drawArc(rect2, startAngle, sweepAngle2, false, activePaint2);
    }
  }

  @override
  bool shouldRepaint(covariant _DoubleProgressPainter oldDelegate) {
    return oldDelegate.calorieProgress != calorieProgress ||
        oldDelegate.macroProgress != macroProgress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Macronutrient Capsule Progress Indicator
// ─────────────────────────────────────────────────────────────────────────────

class _MacroCapsule extends StatelessWidget {
  final String label;
  final double current;
  final double goal;
  final Color color;
  final double s;
  final double fs;
  final Color innerCardBg;

  const _MacroCapsule({
    required this.label,
    required this.current,
    required this.goal,
    required this.color,
    required this.s,
    required this.fs,
    required this.innerCardBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progress = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: EdgeInsets.all(8 * s),
      decoration: BoxDecoration(
        color: innerCardBg,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.08 : 0.05),
          width: 1 * s,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 9 * fs,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                '${current.round()}g',
                style: GoogleFonts.montserrat(
                  fontSize: 9.5 * fs,
                  fontWeight: FontWeight.w800,
                  color: NColors.textPrimary(context),
                ),
              ),
            ],
          ),
          SizedBox(height: 6 * s),
          ClipRRect(
            borderRadius: BorderRadius.circular(3 * s),
            child: SizedBox(
              height: 4 * s,
              child: Stack(
                children: [
                  Container(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  ),
                  FractionallySizedBox(
                    widthFactor: progress,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action & Navigation Mini Add Button
// ─────────────────────────────────────────────────────────────────────────────

class _SmallAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accentColor;
  final double s;
  final double fs;

  const _SmallAddButton({
    required this.onTap,
    required this.accentColor,
    required this.s,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8 * s),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 4 * s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: accentColor, size: 14 * s),
              SizedBox(width: 2 * s),
              Text(
                'Add Food',
                style: GoogleFonts.montserrat(
                  fontSize: 10.5 * fs,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
