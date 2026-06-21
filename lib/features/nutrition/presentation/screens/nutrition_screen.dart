// lib/features/nutrition/presentation/screens/nutrition_screen.dart

import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:befit/features/nutrition/presentation/widgets/nutrition_colors.dart';
import 'package:befit/features/workout/presentation/providers/workout_history_provider.dart';
import 'package:befit/features/workout/presentation/providers/workout_hub_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../data/models/daily_nutrition.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/food_item.dart';
import '../providers/nutrition_provider.dart';
import '../../../smart_plan/data/models/smart_meal_plan.dart';
import '../widgets/professional_nutrition_header.dart';
import '../widgets/daily_summary_card.dart';
import '../widgets/meal_section.dart';
import '../widgets/nutrition_summary_sheet.dart';
import '../widgets/add_food_bottom_sheet.dart';
import '../../../smart_plan/presentation/providers/smart_plan_provider.dart';
import 'ai_nutrition_vision_screen.dart';
import 'hydration_screen.dart';

import '../widgets/nutrition_ui_utils.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final s = size.width / 390;
    final isTablet = size.width > 600;
    final smartPlan = context.watch<SmartPlanProvider>();

    return Scaffold(
      backgroundColor: NColors.bgPrimary(context),
      body:
          Consumer3<
            NutritionProvider,
            WorkoutHubProvider,
            WorkoutHistoryProvider
          >(
            builder: (context, provider, workoutHub, historyProvider, _) {
              final nutrition = provider.dailyNutrition;
              final burned = workoutHub.stats.caloriesToday;

              return SafeArea(
                bottom: false,
                child: RefreshIndicator(
                  onRefresh: provider.refresh,
                  color: NColors.accentPrimary(context),
                  backgroundColor: NColors.bgSecondary(context),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      // ── 1. Top Navigation & Date ────────────────────
                      SliverAppBar(
                        pinned: true,
                        floating: false,
                        backgroundColor: NColors.bgPrimary(
                          context,
                        ).withValues(alpha: 0.9),
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        centerTitle: false,
                        expandedHeight: 110 * s,
                        collapsedHeight: 64 * s,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: EdgeInsets.symmetric(
                            horizontal: isTablet ? size.width * 0.1 : 20 * s,
                            vertical: 12 * s,
                          ),
                          centerTitle: false,
                          title: Text(
                            'Nutrition',
                            style: GoogleFonts.montserrat(
                              color: NColors.textPrimary(context),
                              fontSize: isTablet ? 32 : 26 * s,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                            ),
                          ),
                          background: Container(color: Colors.transparent),
                        ),
                        actions: [
                          Padding(
                            padding: EdgeInsets.only(
                              top: 8,
                              right: isTablet ? size.width * 0.1 : 16 * s,
                            ),
                            child: _LuxuryDateChip(provider: provider, s: s),
                          ),
                        ],
                      ),

                      // ── 3. Hero Progress Card ───────────────────────
                      SliverToBoxAdapter(
                        child: DailySummaryCard(
                          nutrition: nutrition,
                          burnedCalories: burned,
                        ),
                      ),

                      // ── 4. Professional High-Fidelity Header ────────
                      SliverToBoxAdapter(
                        child: ProfessionalNutritionHeader(
                          onAddFood: () => _openAddFood(null),
                          onRecipes: () => context.push(AppRoutes.recipes),
                          onWater: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HydrationScreen(),
                            ),
                          ),
                          onScan: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AINutritionVisionScreen(),
                            ),
                          ),
                        ),
                      ),

                      // ── 5. Meal Timeline ─────────────────────────────
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          vertical: 8 * s,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _buildMealSection(
                                  MealType.breakfast,
                                  nutrition,
                                  provider,
                                  smartPlan,
                                )
                                .animate()
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                            _buildMealSection(
                                  MealType.lunch,
                                  nutrition,
                                  provider,
                                  smartPlan,
                                )
                                .animate(delay: 100.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                            _buildMealSection(
                                  MealType.dinner,
                                  nutrition,
                                  provider,
                                  smartPlan,
                                )
                                .animate(delay: 200.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                            _buildMealSection(
                                  MealType.snacks,
                                  nutrition,
                                  provider,
                                  smartPlan,
                                )
                                .animate(delay: 300.ms)
                                .fadeIn(duration: 400.ms)
                                .slideY(begin: 0.1, end: 0),
                          ]),
                        ),
                      ),

                      // ── 6. Impressive Reports Card ──────────────────
                      SliverToBoxAdapter(
                        child: _HeroReportsCard(nutrition: nutrition, s: s),
                      ),

                      const SliverPadding(
                        padding: EdgeInsets.only(bottom: 120),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  Widget _buildMealSection(
    MealType type,
    dynamic nutrition,
    NutritionProvider provider,
    SmartPlanProvider smartPlan,
  ) {
    IconData icon;
    switch (type) {
      case MealType.breakfast:
        icon = PhosphorIcons.sunHorizon(PhosphorIconsStyle.fill);
        break;
      case MealType.lunch:
        icon = PhosphorIcons.bowlFood(PhosphorIconsStyle.fill);
        break;
      case MealType.dinner:
        icon = PhosphorIcons.moonStars(PhosphorIconsStyle.fill);
        break;
      case MealType.snacks:
        icon = PhosphorIcons.orangeSlice(PhosphorIconsStyle.fill);
        break;
    }

    double mealGoal;
    switch (type) {
      case MealType.breakfast:
        mealGoal = nutrition.calorieGoal * 0.25;
        break;
      case MealType.lunch:
        mealGoal = nutrition.calorieGoal * 0.35;
        break;
      case MealType.dinner:
        mealGoal = nutrition.calorieGoal * 0.30;
        break;
      case MealType.snacks:
        mealGoal = nutrition.calorieGoal * 0.10;
        break;
    }

    List<SmartMealRecipe>? mealSuggestions;
    if (smartPlan.hasMealPlan) {
      switch (type) {
        case MealType.breakfast:
          mealSuggestions = smartPlan.mealPlan?.breakfast;
          break;
        case MealType.lunch:
          mealSuggestions = smartPlan.mealPlan?.lunch;
          break;
        case MealType.dinner:
          mealSuggestions = smartPlan.mealPlan?.dinner;
          break;
        case MealType.snacks:
          mealSuggestions = null;
          break;
      }
    }

    return MealSection(
      mealType: type,
      icon: icon,
      foodLogs: nutrition.logsForMeal(type),
      mealCalories: nutrition.mealCalories(type),
      mealGoal: mealGoal,
      onAddFood: () => _openAddFood(type),
      onDeleteFood: _handleDelete,
      suggestions: mealSuggestions,
      onAddSuggestion: (recipe) {
        final foodItem = FoodItem(
          id: 'suggestion_${recipe.food}_${DateTime.now().millisecondsSinceEpoch}',
          name: recipe.food,
          caloriesPer100g: recipe.calories,
          proteinPer100g: recipe.protein,
          carbsPer100g: recipe.carbohydrates,
          fatPer100g: recipe.fat,
          isGeneric: true,
        );
        provider.addFoodLog(type, foodItem, 100);

        HapticFeedback.mediumImpact();
        NutritionUi.showSuccessSnackBar(context, 'Logged ${recipe.food}');
      },
    );
  }

  void _openAddFood(MealType? mealType) {
    AddFoodBottomSheet.show(
      context,
      mealType: mealType ?? context.read<NutritionProvider>().suggestedMealType,
    );
  }

  void _handleDelete(String logId, MealLog log) {
    final provider = context.read<NutritionProvider>();
    provider.deleteFoodLog(logId);
    HapticFeedback.mediumImpact();
    
    NutritionUi.showInfoSnackBar(
      context,
      'Removed ${log.foodItem.name}',
      icon: Iconsax.trash,
      color: Colors.redAccent,
      duration: const Duration(milliseconds: 1500),
    );
  }
}

class _LuxuryDateChip extends StatelessWidget {
  final NutritionProvider provider;
  final double s;
  const _LuxuryDateChip({required this.provider, required this.s});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NColors.bgSecondary(context),
      borderRadius: BorderRadius.circular(20 * s),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: provider.selectedDate,
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
          );
          if (date != null) provider.selectDate(date);
        },
        borderRadius: BorderRadius.circular(20 * s),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20 * s),
            border: Border.all(
              color: NColors.divider(context).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.calendar_1,
                size: 16 * s,
                color: NColors.accentPrimary(context),
              ),
              SizedBox(width: 8 * s),
              Text(
                provider.isToday ? 'Today' : provider.formattedDate,
                style: GoogleFonts.montserrat(
                  fontSize: 13 * s,
                  fontWeight: FontWeight.w800,
                  color: NColors.textPrimary(context),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16 * s,
                color: NColors.textTertiary(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroReportsCard extends StatelessWidget {
  final DailyNutrition nutrition;
  final double s;
  const _HeroReportsCard({required this.nutrition, required this.s});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.customColors;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
        child: Container(
          margin: EdgeInsets.fromLTRB(
            isTablet ? 0 : 20 * s,
            32 * s,
            isTablet ? 0 : 20 * s,
            12 * s,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32 * s),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [colors.surfaceElevated, colors.surfaceCard]
                  : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                blurRadius: 24 * s,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32 * s),
            child: Stack(
              children: [
                Positioned(
                  right: -30 * s,
                  bottom: -30 * s,
                  child: Icon(
                    Iconsax.chart_21,
                    size: 180 * s,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(28 * s),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10 * s,
                              vertical: 6 * s,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10 * s),
                              border: Border.all(
                                color: colorScheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insights_rounded,
                                  color: isDark
                                      ? colors.success
                                      : const Color(0xFF818CF8),
                                  size: 14 * s,
                                ),
                                SizedBox(width: 6 * s),
                                Text(
                                  'WEEKLY INSIGHTS',
                                  style: GoogleFonts.montserrat(
                                    color: isDark
                                        ? colors.success
                                        : const Color(0xFF818CF8),
                                    fontSize: 10 * s,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Iconsax.more,
                            color: Colors.white.withValues(alpha: 0.3),
                            size: 20 * s,
                          ),
                        ],
                      ),
                      SizedBox(height: 24 * s),
                      Text(
                        'Nutrition Performance',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 24 * s,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 8 * s),
                      Text(
                        'Your weekly average is looking great!\nYou are staying within 5% of your macro goals.',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14 * s,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 32 * s),
                      Material(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(16 * s),
                        child: InkWell(
                          onTap: () => NutritionSummarySheet.show(context),
                          borderRadius: BorderRadius.circular(16 * s),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16 * s),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View Detailed Reports',
                                    style: GoogleFonts.montserrat(
                                      color: isDark
                                          ? colors.bgPrimary
                                          : Colors.white,
                                      fontSize: 15 * s,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 8 * s),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: isDark
                                        ? colors.bgPrimary
                                        : Colors.white,
                                    size: 18 * s,
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
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }
}
