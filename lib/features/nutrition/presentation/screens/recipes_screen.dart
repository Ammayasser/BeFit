// lib/features/nutrition/presentation/screens/recipes_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:befit/core/router/app_routes.dart';

import '../../data/models/recipe.dart';
import '../../data/models/recipe_browse_section.dart';
import '../providers/nutrition_provider.dart';
import '../providers/recipe_provider.dart';
import '../widgets/nutrition_colors.dart';
import '../widgets/recipe_card.dart';
import '../widgets/recipe_filter_sheet.dart';
import '../widgets/recipe_horizontal_card.dart';
import '../widgets/recipe_shimmer.dart';
import '../../data/models/meal_log.dart';
import '../../data/models/food_item.dart';

import '../widgets/nutrition_ui_utils.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const List<({String id, String label, String? apiMeal})> _categories =
      [
        (id: 'all', label: 'All', apiMeal: null),
        (id: 'breakfast', label: 'Breakfast', apiMeal: 'breakfast'),
        (id: 'lunch', label: 'Lunch', apiMeal: 'main'),
        (id: 'dinner', label: 'Dinner', apiMeal: 'main'),
        (id: 'snack', label: 'Snack', apiMeal: 'snack'),
        (id: 'starter', label: 'Starter', apiMeal: 'starter'),
        (id: 'dessert', label: 'Dessert', apiMeal: 'dessert'),
        (id: 'side', label: 'Side Dish', apiMeal: 'side_dish'),
      ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final p = context.read<RecipeProvider>();
      if (p.isSectionBrowseHome &&
          !p.sectionRailsInitialized &&
          !p.sectionRailsLoading) {
        p.loadSectionRails();
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final p = context.read<RecipeProvider>();
    if (p.isSectionBrowseHome || p.recipes.isEmpty) return;
    final max = _scrollController.position.maxScrollExtent;
    final off = _scrollController.offset;
    if (max - off < 200) {
      context.read<RecipeProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final p = context.read<RecipeProvider>();
    if (p.isSectionBrowseHome) {
      await p.loadSectionRails();
    } else {
      await p.loadRecipes(reset: true);
    }
  }

  void _openFilters(RecipeProvider p) {
    HapticFeedback.selectionClick();
    RecipeFilterSheet.show(
      context,
      cuisine: p.selectedCuisine,
      mealType: p.selectedMealType,
      difficulty: p.selectedDifficulty,
      dietaryTag: p.selectedDietaryTag,
      caloriesMax: p.caloriesMax,
      proteinMin: p.proteinMin,
      prepTimeMax: p.prepTimeMax,
      ingredients: p.ingredientsCsv,
      sortBy: p.sortBy,
      onApply:
          ({
            cuisine,
            mealType,
            difficulty,
            dietaryTag,
            caloriesMax,
            proteinMin,
            prepTimeMax,
            ingredients,
            sortBy,
          }) {
            p.setFilter(
              cuisine: cuisine,
              mealType: mealType,
              difficulty: difficulty,
              dietaryTag: dietaryTag,
              caloriesMax: caloriesMax,
              proteinMin: proteinMin,
              prepTimeMax: prepTimeMax,
              ingredients: ingredients,
              sortBy: sortBy,
            );
          },
      onClearAll: () {
        p.clearFilters();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: NColors.bgPrimary(context),
        body: Consumer<RecipeProvider>(
          builder: (context, p, _) {
            final searchActive =
                p.searchQuery != null && p.searchQuery!.isNotEmpty;
            final sectionHome = p.isSectionBrowseHome;

            return RefreshIndicator(
              color: NColors.accentPrimary(context),
              backgroundColor: NColors.bgSecondary(context),
              onRefresh: _onRefresh,
              child: Stack(
                children: [
                  // Subtle top gradient background
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NColors.accentPrimary(context).withValues(alpha: 0.05),
                      ),
                    ),
                  ),

                  CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      _buildModernAppBar(context, p),
                      if (!p.showingFavorites) ...[
                        if (searchActive && !p.isLoading)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: NColors.accentPrimary(context),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${p.totalCount} results for "${p.searchQuery}"',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: NColors.textPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(child: _buildModernCategoryRow(p)),
                      ],
                      if (!searchActive && sectionHome)
                        SliverToBoxAdapter(child: _buildModernDiscover(p)),
                      if (p.browseSectionId != null && !sectionHome)
                        SliverToBoxAdapter(
                          child: _SectionBrowseBackBar(
                            title: p.browseSectionTitle ?? 'Browse',
                            onBack: () {
                              HapticFeedback.lightImpact();
                              _searchController.clear();
                              p.closeSectionFullBrowse();
                            },
                          ),
                        ),
                      if (sectionHome) ..._buildSectionHomeSlivers(context, p),
                      if (!sectionHome) ..._buildRecipeGridSlivers(context, p),
                      if (p.isLoadingMore && !sectionHome)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: NColors.accentPrimary(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 120)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModernAppBar(BuildContext context, RecipeProvider p) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      elevation: 0,
      backgroundColor: NColors.bgPrimary(context),
      surfaceTintColor: Colors.transparent,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: _ModernRoundButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            if (p.showingFavorites) {
              p.toggleShowingFavorites();
            } else {
              context.pop();
            }
          },
        ),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            p.showingFavorites ? 'Saved' : 'Recipes',
            style: GoogleFonts.montserrat(
              color: NColors.textPrimary(context),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (!p.showingFavorites)
            Text(
              'What are we cooking today?',
              style: GoogleFonts.montserrat(
                color: NColors.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _ModernRoundButton(
            icon: p.showingFavorites ? Iconsax.archive_15 : Iconsax.archive_1,
            color: p.showingFavorites ? NColors.accentPrimary(context) : null,
            onTap: () {
              HapticFeedback.selectionClick();
              p.toggleShowingFavorites();
            },
          ),
        ),
      ],
      bottom: p.showingFavorites
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(82),
              child: _ModernSearchBar(
                controller: _searchController,
                isLoading: p.isLoading,
                onChanged: (v) => p.search(v),
                onClear: () {
                  _searchController.clear();
                  p.search('');
                },
                onFilter: () => _openFilters(p),
                activeFilterCount: p.activeFilterCount,
              ),
            ),
    );
  }

  Widget _buildModernCategoryRow(RecipeProvider p) {
    return Container(
      height: 54,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final c = _categories[i];
          final selected = c.id == 'all'
              ? p.selectedMealChipId == null
              : p.selectedMealChipId == c.id;

          return AnimatedContainer(
            duration: 250.ms,
            curve: Curves.easeOutCubic,
            child: Material(
              color: selected
                  ? NColors.accentPrimary(context)
                  : NColors.bgSecondary(context),
              borderRadius: BorderRadius.circular(20),
              elevation: selected ? 8 : 0,
              shadowColor: NColors.accentPrimary(context).withValues(alpha: 0.4),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (c.id == 'all') {
                    p.setMealCategoryChip(chipId: 'all', apiMealType: null);
                  } else {
                    p.setMealCategoryChip(chipId: c.id, apiMealType: c.apiMeal);
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: Text(
                      c.label,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: selected
                            ? Colors.white
                            : NColors.textPrimary(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernDiscover(RecipeProvider p) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF0F172A),
                const Color(0xFF1E293B).withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Decorative elements
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            PhosphorIcons.sparkle(PhosphorIconsStyle.fill),
                            color: const Color(0xFFFACC15), // Gold Sparkle
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recipe Roulette',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              Text(
                                'Let AI decide your next meal',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    if (p.randomRecipe != null)
                      _ModernRandomResult(
                        recipe: p.randomRecipe!,
                        onTap: () {
                          final r = p.randomRecipe!;
                          context.push('${AppRoutes.recipes}/${r.id}', extra: r);
                        },
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0)
                    else
                      Text(
                        'Ready for a culinary surprise? Our AI will pick a healthy recipe matching your goals.',
                        style: GoogleFonts.montserrat(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: p.isLoadingRandom
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                p.loadRandom();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: NColors.accentPrimary(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 4,
                        ),
                        child: p.isLoadingRandom
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Iconsax.magic_star, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Spin the Wheel',
                                    style: GoogleFonts.montserrat(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
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
      ),
    );
  }

  SliverGridDelegate _gridDelegate(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    
    int cross;
    double ratio;
    
    if (w < 360) {
      cross = 1;
      ratio = 1.45;
    } else if (w < 600) {
      cross = 2;
      ratio = 0.66;
    } else if (w < 900) {
      cross = 3;
      ratio = 0.72;
    } else if (w < 1200) {
      cross = 4;
      ratio = 0.78;
    } else {
      cross = 5;
      ratio = 0.82;
    }

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: cross,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: ratio,
    );
  }

  List<Widget> _buildSectionHomeSlivers(
    BuildContext context,
    RecipeProvider p,
  ) {
    final out = <Widget>[];
    if (p.sectionRailsError != null) {
      out.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: _SectionRailsErrorBanner(
              message: p.sectionRailsError!,
              onRetry: () => p.loadSectionRails(),
            ),
          ),
        ),
      );
    }

    if (p.sectionRailsLoading && !p.sectionRailsInitialized) {
      final defs = RecipeBrowseSection.homeRails;
      final n = defs.length < 5 ? defs.length : 5;
      for (var i = 0; i < n; i++) {
        out.add(
          SliverToBoxAdapter(child: _SectionRailShimmer(title: defs[i].title)),
        );
      }
      return out;
    }

    for (final s in RecipeBrowseSection.homeRails) {
      out.add(
        SliverToBoxAdapter(
          child: _RecipeSectionRow(
            section: s,
            recipes: p.sectionRecipes[s.id] ?? const [],
            onViewMore: () {
              HapticFeedback.selectionClick();
              p.openSectionFullBrowse(s.id);
            },
            onRecipeTap: (recipe) {
              HapticFeedback.selectionClick();
              // Using context.push to navigate to recipe details
              context.push('${AppRoutes.recipes}/${recipe.id}', extra: recipe);
            },
            onFavoriteTap: (recipe) => _toggleFavorite(recipe, p),
            onAddTap: _logRecipe,
          ),
        ),
      );
    }
    out.add(const SliverToBoxAdapter(child: SizedBox(height: 96)));
    return out;
  }

  void _toggleFavorite(Recipe recipe, RecipeProvider p) async {
    HapticFeedback.mediumImpact();
    final wasFavorite = recipe.isFavorite;
    await p.toggleFavorite(recipe);
    
    if (!mounted) return;
    NutritionUi.showInfoSnackBar(
      context,
      wasFavorite ? 'Removed from favorites' : 'Saved to favorites',
      icon: wasFavorite ? Iconsax.archive_1 : Iconsax.archive_15,
      color: wasFavorite ? Colors.grey : NColors.accentPrimary(context),
      duration: const Duration(milliseconds: 1500),
    );
  }

  void _logRecipe(Recipe recipe, MealType type) {
    HapticFeedback.mediumImpact();
    final foodItem = FoodItem(
      id: recipe.id.toString(),
      name: recipe.name,
      caloriesPer100g: recipe.caloriesPerServing.toDouble(),
      proteinPer100g: recipe.protein.toDouble(),
      carbsPer100g: recipe.carbsPerServingPlaceholder,
      fatPer100g: 0.0, // API does not expose fat
      imageUrl: recipe.imageUrl,
    );
    context.read<NutritionProvider>().addFoodLog(type, foodItem, 100.0);
    NutritionUi.showSuccessSnackBar(
      context,
      'Added ${recipe.name} to ${type.displayName}',
    );
  }

  List<Widget> _buildRecipeGridSlivers(BuildContext context, RecipeProvider p) {
    if (p.error != null && p.recipes.isEmpty && !p.isLoading) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _ErrorState(
            message: p.error!,
            onRetry: () {
              p.clearError();
              p.loadRecipes(reset: true);
            },
          ),
        ),
      ];
    }
    if (p.isLoading && p.recipes.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          sliver: SliverGrid(
            gridDelegate: _gridDelegate(context),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const RecipeShimmerCard(),
              childCount: 6,
            ),
          ),
        ),
      ];
    }
    if (!p.isLoading && p.recipes.isEmpty && p.error == null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            onReset: () {
              _searchController.clear();
              p.clearFilters();
              p.search('');
            },
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        sliver: SliverGrid(
          gridDelegate: _gridDelegate(context),
          delegate: SliverChildBuilderDelegate((context, index) {
            final recipe = p.recipes[index];
            return RecipeCard(
                  recipe: recipe,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push(
                      '${AppRoutes.recipes}/${recipe.id}',
                      extra: recipe,
                    );
                  },
                  onFavoriteTap: () => _toggleFavorite(recipe, p),
                  onAddTap: (type) => _logRecipe(recipe, type),
                )
                .animate()
                .fadeIn(duration: 300.ms)
                .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 300.ms,
                  delay: (index * 50).ms,
                );
          }, childCount: p.recipes.length),
        ),
      ),
    ];
  }
}

class _ModernRoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _ModernRoundButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NColors.bgSecondary(context),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: color ?? NColors.textPrimary(context),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ModernSearchBar extends StatelessWidget {
  const _ModernSearchBar({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onClear,
    required this.onFilter,
    required this.activeFilterCount,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilter;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: NColors.bgSecondary(context),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    return Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(
                          Iconsax.search_normal_1,
                          color: NColors.textTertiary(context),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            onChanged: onChanged,
                            textInputAction: TextInputAction.search,
                            style: GoogleFonts.montserrat(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: NColors.textPrimary(context),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search 5000+ recipes...',
                              hintStyle: GoogleFonts.montserrat(
                                color: NColors.textTertiary(context),
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        if (isLoading)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: NColors.accentPrimary(context),
                              ),
                            ),
                          ),
                        if (value.text.isNotEmpty)
                          IconButton(
                            onPressed: onClear,
                            icon: Icon(
                              Iconsax.close_circle5,
                              color: NColors.textSecondary(context),
                              size: 20,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ModernRoundButton(
                  icon: Iconsax.filter_edit,
                  onTap: onFilter,
                ),
                if (activeFilterCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: NColors.accentPrimary(context),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '$activeFilterCount',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernRandomResult extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _ModernRandomResult({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: recipe.imageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(recipe.imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: recipe.imageUrl == null
                    ? Icon(Iconsax.image, color: Colors.white24)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _ModernSmallTag(
                          label: '${recipe.caloriesPerServing} kcal',
                          icon: Iconsax.flash,
                        ),
                        const SizedBox(width: 8),
                        _ModernSmallTag(
                          label: '${recipe.totalTime} min',
                          icon: Iconsax.timer_1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernSmallTag extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ModernSmallTag({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.warning_2,
            size: 56,
            color: NColors.dangerAccent(context).withValues(alpha: 0.85),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: NColors.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: NColors.accentPrimary(context),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NColors.radiusButton),
              ),
            ),
            child: Text(
              'Try again',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionBrowseBackBar extends StatelessWidget {
  const _SectionBrowseBackBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: NColors.bgSecondary(context),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Iconsax.arrow_left_3,
                  color: NColors.accentPrimary(context),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: NColors.textPrimary(context),
                        ),
                      ),
                      Text(
                        'Back to all sections',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: NColors.textSecondary(context),
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
    );
  }
}

class _SectionRailsErrorBanner extends StatelessWidget {
  const _SectionRailsErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NColors.dangerAccent(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NColors.dangerAccent(context).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: NColors.textSecondary(context),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                color: NColors.accentPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRailShimmer extends StatelessWidget {
  const _SectionRailShimmer({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final railHeight = w < 600 ? 228.0 : 280.0;
    final cardWidth = w < 600 ? 166.0 : 210.0;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: NColors.textPrimary(context),
                  ),
                ),
              ),
              Container(
                width: 72,
                height: 12,
                decoration: BoxDecoration(
                  color: NColors.divider(context).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: railHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) => Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: NColors.bgSecondary(context),
                  borderRadius: BorderRadius.circular(NColors.radiusCard),
                  border: Border.all(
                    color: NColors.divider(context).withValues(alpha: 0.5),
                  ),
                ),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: NColors.accentPrimary(context),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeSectionRow extends StatelessWidget {
  const _RecipeSectionRow({
    required this.section,
    required this.recipes,
    required this.onViewMore,
    required this.onRecipeTap,
    required this.onFavoriteTap,
    this.onAddTap,
  });

  final RecipeBrowseSection section;
  final List<Recipe> recipes;
  final VoidCallback onViewMore;
  final void Function(Recipe recipe) onRecipeTap;
  final void Function(Recipe recipe) onFavoriteTap;
  final void Function(Recipe recipe, MealType type)? onAddTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cardWidth = w < 600 ? 172.0 : 210.0;
    final railHeight = w < 600 ? 232.0 : 280.0;

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 0, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: NColors.textPrimary(context),
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 24,
                        height: 3,
                        decoration: BoxDecoration(
                          color: NColors.accentPrimary(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onViewMore,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Text(
                          'View all',
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: NColors.accentPrimary(context),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10,
                          color: NColors.accentPrimary(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (recipes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: NColors.bgSecondary(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: NColors.divider(context).withValues(alpha: 0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No recipes in this row right now.',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: NColors.textTertiary(context),
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: railHeight,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: recipes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 16),
                itemBuilder: (context, i) {
                  final r = recipes[i];
                  return RecipeHorizontalCard(
                    recipe: r,
                    width: cardWidth,
                    onTap: () => onRecipeTap(r),
                    onFavoriteTap: () => onFavoriteTap(r),
                    onAddTap:
                        onAddTap != null ? (type) => onAddTap!(r, type) : null,
                  ).animate().fadeIn(duration: 400.ms).slideX(
                    begin: 0.1,
                    end: 0,
                    curve: Curves.easeOutCubic,
                    delay: (i * 100).ms,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.cookingPot(PhosphorIconsStyle.duotone),
            size: 72,
            color: NColors.textTertiary(context),
          ),
          const SizedBox(height: 16),
          Text(
            'No recipes found',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: NColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different filters or search terms.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: NColors.textSecondary(context),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: NColors.accentPrimary(context),
              side: BorderSide(color: NColors.accentPrimary(context)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(NColors.radiusButton),
              ),
            ),
            child: Text(
              'Reset search',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
