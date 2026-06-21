// lib/features/nutrition/presentation/screens/recipe_detail_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../data/models/food_item.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/recipe.dart';
import '../providers/nutrition_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/nutrition_colors.dart';
import '../widgets/recipe_lead_image.dart';

import '../widgets/nutrition_ui_utils.dart';

class RecipeDetailScreen extends StatefulWidget {
  /// When opened from browse, full or partial [recipe] is passed via GoRouter `extra`.
  final Recipe? recipe;

  /// Deep-link style open with id only (no `extra`).
  final int? lookupId;

  // ignore: prefer_const_constructors_in_immutables — [recipe]/[lookupId] are not compile-time const.
  RecipeDetailScreen({super.key, this.recipe, this.lookupId})
    : assert(recipe != null || lookupId != null);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late final int _id;

  @override
  void initState() {
    super.initState();
    _id = widget.recipe?.id ?? widget.lookupId!;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<RecipeProvider>().loadRecipeDetail(
        _id,
        initial: widget.recipe,
      );
    });
  }

  void _popDetail(BuildContext context) {
    HapticFeedback.lightImpact();
    context.pop();
  }

  Color _ingredientDotColor(BuildContext context, String? category) {
    switch (category?.toLowerCase()) {
      case 'spice':
        return NColors.warningAccent(context);
      case 'vegetable':
      case 'veg':
        return NColors.accentPrimary(context);
      case 'dairy':
        return NColors.accentSecondary(context);
      case 'meat':
      case 'protein':
        return NColors.dangerAccent(context);
      default:
        return NColors.textTertiary(context);
    }
  }

  Recipe _visibleRecipe(RecipeProvider p) {
    final d = p.detailRecipe;
    if (d != null && d.id == _id) return d;
    if (widget.recipe != null) return widget.recipe!;
    return d ?? Recipe(id: _id, name: 'Recipe');
  }

  Future<void> _pickMealAndLog(BuildContext context, Recipe r) async {
    final meal = await showModalBottomSheet<MealType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: NColors.bgSecondary(ctx),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(NColors.radiusModal),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Log to meal',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: NColors.textPrimary(ctx),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...MealType.values.map(
                    (m) => ListTile(
                      leading: Icon(
                        Iconsax.arrow_right_3,
                        color: NColors.mealColor(ctx, m.displayName),
                      ),
                      title: Text(
                        m.displayName,
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                          color: NColors.textPrimary(ctx),
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, m),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!context.mounted || meal == null) return;

    final food = FoodItem(
      id: 'recipe_${r.id}',
      name: r.name,
      brand: 'BeFit Recipes',
      caloriesPer100g: r.caloriesPerServing.toDouble(),
      proteinPer100g: r.protein.toDouble(),
      carbsPer100g: 0.0,
      fatPer100g: 0.0,
      servingSize: '1 serving',
      servingGrams: 100.0,
    );

    context.read<NutritionProvider>().addFoodLog(meal, food, 100.0);

    NutritionUi.showSuccessSnackBar(context, 'Added to ${meal.displayName}!');
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 390;

    return Scaffold(
      backgroundColor: NColors.bgPrimary(context),
      body: Consumer<RecipeProvider>(
        builder: (context, p, _) {
          final r = _visibleRecipe(p);

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(context, p, r, s),
                  SliverToBoxAdapter(child: _metaRow(context, r)),
                  SliverToBoxAdapter(child: _macrosCard(context, r)),
                  if (r.description != null && r.description!.trim().isNotEmpty)
                    SliverToBoxAdapter(child: _about(context, r)),
                  SliverToBoxAdapter(child: _ingredients(context, r)),
                  SliverToBoxAdapter(child: _instructions(context, r)),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
              _bottomBar(context, r),
              if (p.isLoadingDetail)
                Positioned(
                  top: MediaQuery.paddingOf(context).top,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    color: NColors.accentPrimary(context),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    RecipeProvider p,
    Recipe r,
    double s,
  ) {
    return SliverAppBar(
      expandedHeight: 280 * s,
      pinned: true,
      elevation: 0,
      backgroundColor: NColors.bgPrimary(context),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _circleIcon(
          context,
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => _popDetail(context),
          size: 36 * s,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _circleIcon(
            context,
            icon: r.isFavorite ? Iconsax.archive_15 : Iconsax.archive_1,
            onTap: () {
              HapticFeedback.selectionClick();
              p.toggleFavorite(r);
            },
            iconColor: r.isFavorite
                ? NColors.accentPrimary(context)
                : NColors.textPrimary(context),
            size: 36 * s,
          ),
        ),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            RecipeLeadImage(recipe: r, variant: RecipeLeadImageVariant.hero),
            Positioned(
              left: 20 * s,
              right: 20 * s,
              bottom: 20 * s,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 26 * s,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      shadows: [
                        Shadow(color: Colors.black26, blurRadius: 10 * s),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _heroChip(
                          Iconsax.flash_1,
                          '${r.caloriesPerServing} kcal',
                          s,
                        ),
                        const SizedBox(width: 8),
                        _heroChip(Iconsax.weight_1, '${r.protein}g protein', s),
                        const SizedBox(width: 8),
                        _heroChip(Iconsax.timer_1, '${r.totalTime} min', s),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
    double size = 48,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: NColors.bgSecondary(context).withValues(alpha: 0.7),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor ?? NColors.textPrimary(context),
                  size: size * 0.45,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroChip(IconData icon, String label, double s) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12 * s, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 11 * s,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, Recipe r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (r.cuisine != null && r.cuisine!.isNotEmpty)
            _softChip(context, _capitalize(r.cuisine!)),
          if (r.difficulty != null && r.difficulty!.isNotEmpty)
            _softChip(context, _capitalize(r.difficulty!)),
          ...r.dietaryTags.map(
            (t) => _softChip(context, _capitalize(t.replaceAll('_', ' '))),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _softChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NColors.bgSecondary(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: NColors.divider(context)),
        boxShadow: NColors.cardGlow(context),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: NColors.textSecondary(context),
        ),
      ),
    );
  }

  Widget _macrosCard(BuildContext context, Recipe r) {
    Widget stat(String big, String label) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: NColors.bgSecondary(context),
            borderRadius: BorderRadius.circular(NColors.radiusCard),
            border: Border.all(color: NColors.divider(context)),
            boxShadow: NColors.cardGlow(context),
          ),
          child: Column(
            children: [
              Text(
                big,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: NColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: NColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              stat('${r.caloriesPerServing}', 'Calories'),
              const SizedBox(width: 10),
              stat('${r.protein}g', 'Protein'),
              const SizedBox(width: 10),
              stat('${r.prepTime}', 'Prep'),
              const SizedBox(width: 10),
              stat('${r.cookTime}', 'Cook'),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 320.ms, delay: 40.ms)
        .slideY(begin: 0.06, end: 0);
  }

  Widget _about(BuildContext context, Recipe r) {
    return Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                r.description!.trim(),
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                  color: NColors.textSecondary(context),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 320.ms, delay: 80.ms)
        .slideY(begin: 0.06, end: 0);
  }

  Widget _ingredients(BuildContext context, Recipe r) {
    return Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingredients (${r.ingredients.length})',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: NColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 12),
              ...r.ingredients.map((ing) => _ingredientTile(context, ing)),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 320.ms, delay: 100.ms)
        .slideY(begin: 0.06, end: 0);
  }

  Widget _ingredientTile(BuildContext context, RecipeIngredient ing) {
    final dot = _ingredientDotColor(context, ing.category);
    final qty = _formatQty(ing);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ing.name,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: NColors.textPrimary(context),
              ),
            ),
          ),
          if (qty.isNotEmpty)
            Text(
              qty,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: NColors.textSecondary(context),
              ),
            ),
          if (ing.optional) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: NColors.bgPrimary(context),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NColors.divider(context)),
              ),
              child: Text(
                'Optional',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: NColors.textTertiary(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatQty(RecipeIngredient ing) {
    if (ing.unit == null || ing.unit!.isEmpty) {
      if (ing.quantity == 0) return '';
      return _trimNum(ing.quantity);
    }
    if (ing.quantity == 0) return ing.unit!;
    return '${_trimNum(ing.quantity)} ${ing.unit}';
  }

  String _trimNum(double q) {
    if (q == q.roundToDouble()) return '${q.toInt()}';
    return q.toStringAsFixed(1);
  }

  Widget _instructions(BuildContext context, Recipe r) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: NColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(r.instructions.length, (i) {
            final step = r.instructions[i];
            return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: NColors.accentPrimary(context),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step,
                          style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                            color: NColors.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 350.ms, delay: (80 + i * 60).ms)
                .slideX(
                  begin: 0.04,
                  end: 0,
                  duration: 350.ms,
                  delay: (80 + i * 60).ms,
                );
          }),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, Recipe r) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.paddingOf(context).bottom + 12,
        ),
        decoration: BoxDecoration(
          color: NColors.bgSecondary(context).withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(
              color: NColors.divider(context).withValues(alpha: 0.8),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: NColors.bgPrimary(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: NColors.divider(context).withValues(alpha: 0.5),
                ),
              ),
              child: IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<RecipeProvider>().toggleFavorite(r);
                },
                icon: Icon(
                  r.isFavorite ? Iconsax.archive_15 : Iconsax.archive_1,
                  color: r.isFavorite
                      ? NColors.accentPrimary(context)
                      : NColors.textPrimary(context),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  _pickMealAndLog(context, r);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: NColors.accentPrimary(context),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NColors.radiusButton),
                  ),
                ),
                icon: Icon(Iconsax.add, color: Colors.white),
                label: Text(
                  'Log this meal',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}
