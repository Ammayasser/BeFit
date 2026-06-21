import 'package:befit/core/theme/befit_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

import '../../data/models/food_item.dart';
import '../../data/models/meal_log.dart';
import '../../data/utils/food_search_relevance.dart';
import '../providers/nutrition_provider.dart';
import '../screens/barcode_scanner_screen.dart';
import 'food_portion_sheet.dart';
import 'food_search_tile.dart';
import 'nutrition_colors.dart';

class AddFoodBottomSheet extends StatefulWidget {
  final MealType? preSelectedMeal;

  const AddFoodBottomSheet({super.key, this.preSelectedMeal});

  static Future<void> show(BuildContext context, {MealType? mealType}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<NutritionProvider>(),
        child: AddFoodBottomSheet(preSelectedMeal: mealType),
      ),
    );
  }

  @override
  State<AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<AddFoodBottomSheet> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  late MealType _currentMeal = widget.preSelectedMeal ?? MealType.breakfast;

  Color get _mealAccent => NColors.mealColor(context, _currentMeal.displayName);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final colorScheme = Theme.of(context).colorScheme;
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        height: (h * 0.92).clamp(480.0, h * 0.96),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                isDark ? colors.bgPrimary : const Color(0xFFF8FAFC),
                _mealAccent,
                0.06,
              )!,
              colors.bgSecondary,
              colors.bgSecondary,
            ],
            stops: const [0.0, 0.12, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.18),
              blurRadius: 40,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top gradient rail + grab handle
            Container(
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _mealAccent.withValues(alpha: 0.35),
                    _mealAccent,
                    Color.lerp(
                      _mealAccent,
                      isDark ? Colors.black : const Color(0xFF0F172A),
                      0.2,
                    )!,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? colors.border
                      : const Color(0xFFCBD5E1).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
              child: Row(
                children: [
                  Material(
                    color: isDark ? colors.surfaceCard : Colors.white,
                    shape: const CircleBorder(),
                    elevation: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Ink(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? colors.border
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Iconsax.arrow_left_2,
                          color: colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add food',
                          style: GoogleFonts.montserrat(
                            color: colorScheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search the database or scan a barcode',
                          style: GoogleFonts.inter(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Meal selector chips
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (final m in MealType.values) ...[
                      _MealChoiceChip(
                        meal: m,
                        selected: _currentMeal == m,
                        color: NColors.mealColor(context, m.displayName),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentMeal = m);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),

            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _mealAccent.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: isDark ? colors.surfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, _) {
                      return TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        style: GoogleFonts.inter(
                          color: colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        cursorColor: _mealAccent,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDark ? colors.surfaceCard : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: isDark
                                  ? colors.border
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: isDark
                                  ? colors.border
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                              color: _mealAccent,
                              width: 2,
                            ),
                          ),
                          prefixIcon: Icon(
                            Iconsax.search_normal_1,
                            color: colorScheme.onSurfaceVariant,
                            size: 22,
                          ),
                          hintText: 'Foods, brands, keywords…',
                          hintStyle: GoogleFonts.inter(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.6,
                            ),
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (value.text.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    _searchController.clear();
                                    context
                                        .read<NutritionProvider>()
                                        .clearSearch();
                                  },
                                  icon: Icon(
                                    Iconsax.close_circle,
                                    color: NColors.textSecondary(context),
                                    size: 22,
                                  ),
                                )
                              else
                                Material(
                                  color: _mealAccent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BarcodeScannerScreen(
                                            preSelectedMeal: _currentMeal,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Iconsax.scan_barcode,
                                            color: _mealAccent,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Scan',
                                            style: GoogleFonts.inter(
                                              color: _mealAccent,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),
                        onChanged: (val) {
                          context.read<NutritionProvider>().searchFoods(val);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Section title (suggestions vs results)
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _searchController,
              builder: (context, value, _) {
                final searching = value.text.trim().isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _mealAccent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _mealAccent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(
                          searching ? Iconsax.search_status : Iconsax.flash_1,
                          color: _mealAccent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              searching ? 'Results' : 'Suggestions',
                              style: GoogleFonts.montserrat(
                                color: colorScheme.onSurface,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              searching
                                  ? 'Tap an item to log portion to ${_currentMeal.displayName}'
                                  : 'Quick picks — type to search Open Food Facts',
                              style: GoogleFonts.inter(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, searchTx, _) {
                  return Consumer<NutritionProvider>(
                    builder: (context, provider, _) {
                      if (provider.isSearching) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: _mealAccent,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Searching…',
                                style: GoogleFonts.inter(
                                  color: NColors.textSecondary(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final queryRaw = searchTx.text.trim();
                      final lowerQ = queryRaw.toLowerCase();
                      final isQueryEmpty = queryRaw.isEmpty;

                      if (isQueryEmpty) {
                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            if (provider.recentSearches.isNotEmpty) ...[
                              _searchSectionLabel(
                                'Recent Searches',
                                'Your last search queries',
                              ),
                              for (final rs in provider.recentSearches)
                                ListTile(
                                  leading: Icon(
                                    Iconsax.clock,
                                    color: NColors.textTertiary(context),
                                    size: 18,
                                  ),
                                  title: Text(
                                    rs,
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: NColors.textPrimary(context),
                                    ),
                                  ),
                                  trailing: Icon(
                                    Iconsax.arrow_right_3,
                                    color: NColors.textTertiary(
                                      context,
                                    ).withValues(alpha: 0.5),
                                    size: 16,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  onTap: () {
                                    _searchController.text = rs;
                                    provider.searchFoods(rs);
                                  },
                                ).animate().fadeIn(duration: 200.ms),
                              const SizedBox(height: 20),
                            ],
                            _searchSectionLabel(
                              'Suggestions',
                              'Quick picks for you',
                            ),
                            ..._defaultSuggestions.map(
                              (food) => FoodSearchTile(
                                food: food,
                                accentColor: _mealAccent,
                                onTap: () => _openPortionSheet(context, food),
                              ),
                            ),
                            const SizedBox(height: 28),
                          ],
                        );
                      }

                      final results = provider.searchResults;

                      if (results.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _mealAccent.withValues(alpha: 0.1),
                                  border: Border.all(
                                    color: _mealAccent.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Icon(
                                  Iconsax.search_normal,
                                  size: 40,
                                  color: _mealAccent,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No matches',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: NColors.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try another keyword or use Scan for packaged foods.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: NColors.textSecondary(context),
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final useGroupedSearch =
                          !isQueryEmpty &&
                          lowerQ.length >= 2 &&
                          foodNameRelevanceScore(
                                results.first.name,
                                lowerQ,
                                secondaryLabel: results.first.brand,
                              ) >=
                              90;

                      if (!useGroupedSearch) {
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                          physics: const BouncingScrollPhysics(),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final food = results[index];
                            return FoodSearchTile(
                                  food: food,
                                  accentColor: _mealAccent,
                                  onTap: () => _openPortionSheet(context, food),
                                )
                                .animate()
                                .fadeIn(
                                  duration: 200.ms,
                                  delay: Duration(milliseconds: 24 * index),
                                )
                                .slideY(begin: 0.04, end: 0, duration: 200.ms);
                          },
                        );
                      }

                      final best = results.first;
                      final rest = results.skip(1).toList();
                      var index = 0;
                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _searchSectionLabel(
                            'Best match',
                            'Closest name match for “$queryRaw”',
                          ),
                          FoodSearchTile(
                                food: best,
                                accentColor: _mealAccent,
                                onTap: () => _openPortionSheet(context, best),
                              )
                              .animate()
                              .fadeIn(
                                duration: 200.ms,
                                delay: Duration(milliseconds: 24 * index++),
                              )
                              .slideY(begin: 0.04, end: 0, duration: 200.ms),
                          if (rest.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _searchSectionLabel(
                              'More results',
                              'Other foods that mention your search',
                            ),
                            ...rest.map((food) {
                              final i = index++;
                              return FoodSearchTile(
                                    food: food,
                                    accentColor: _mealAccent,
                                    onTap: () =>
                                        _openPortionSheet(context, food),
                                  )
                                  .animate()
                                  .fadeIn(
                                    duration: 200.ms,
                                    delay: Duration(milliseconds: 24 * i),
                                  )
                                  .slideY(
                                    begin: 0.04,
                                    end: 0,
                                    duration: 200.ms,
                                  );
                            }),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<FoodItem> _defaultSuggestions = [
    FoodItem(
      id: 'usda_sugar',
      name: 'Sugar',
      caloriesPer100g: 400,
      servingSize: '1 teaspoon',
      servingGrams: 4,
      proteinPer100g: 0,
      carbsPer100g: 100,
      fatPer100g: 0,
      isGeneric: true,
    ),
    FoodItem(
      id: 'usda_olive_oil',
      name: 'Olive oil',
      caloriesPer100g: 884,
      servingSize: '1 tbsp',
      servingGrams: 14,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 100,
      isGeneric: true,
    ),
    FoodItem(
      id: 'usda_white_rice',
      name: 'White Rice',
      caloriesPer100g: 130,
      servingSize: '100 gram, Cooked',
      servingGrams: 100,
      proteinPer100g: 2.7,
      carbsPer100g: 28.2,
      fatPer100g: 0.3,
      isGeneric: true,
    ),
    FoodItem(
      id: 'usda_banana',
      name: 'Banana',
      caloriesPer100g: 89,
      servingSize: '1 medium',
      servingGrams: 118,
      proteinPer100g: 1.1,
      carbsPer100g: 22.8,
      fatPer100g: 0.3,
      isGeneric: true,
    ),
    FoodItem(
      id: 'usda_egg',
      name: 'Egg',
      caloriesPer100g: 144,
      servingSize: '1 large',
      servingGrams: 50,
      proteinPer100g: 12.6,
      carbsPer100g: 0.7,
      fatPer100g: 9.5,
      isGeneric: true,
    ),
    FoodItem(
      id: 'usda_whole_milk',
      name: 'Whole milk',
      caloriesPer100g: 61,
      servingSize: '1 cup',
      servingGrams: 240,
      proteinPer100g: 3.2,
      carbsPer100g: 4.8,
      fatPer100g: 3.3,
      isGeneric: true,
    ),
  ];

  Widget _searchSectionLabel(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.montserrat(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openPortionSheet(BuildContext context, FoodItem food) async {
    final navigator = Navigator.of(context);
    final provider = context.read<NutritionProvider>();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FoodPortionSheet(food: food, preSelectedMeal: _currentMeal),
        ),
      ),
    );

    if (result != null && mounted) {
      navigator.pop();
      provider.addFoodLog(
        result['meal'] as MealType,
        food,
        result['grams'] as double,
      );
    }
  }
}

class _MealChoiceChip extends StatelessWidget {
  final MealType meal;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _MealChoiceChip({
    required this.meal,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.customColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: selected
                  ? LinearGradient(
                      colors: [color, Color.lerp(color, isDark ? Colors.white : Colors.black, 0.12)!],
                    )
                  : null,
              color: selected ? null : (isDark ? colors.surfaceCard : Colors.white),
              border: Border.all(
                color: selected ? Colors.transparent : (isDark ? colors.border : const Color(0xFFE2E8F0)),
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              meal.displayName,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
