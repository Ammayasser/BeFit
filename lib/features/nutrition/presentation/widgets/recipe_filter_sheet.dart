// lib/features/nutrition/presentation/widgets/recipe_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'nutrition_colors.dart';

typedef RecipeFilterApplyCallback = void Function({
  String? cuisine,
  String? mealType,
  String? difficulty,
  String? dietaryTag,
  int? caloriesMax,
  int? proteinMin,
  int? prepTimeMax,
  String? ingredients,
  String? sortBy,
});

class RecipeFilterSheet extends StatefulWidget {
  final String? cuisine;
  final String? mealType;
  final String? difficulty;
  final String? dietaryTag;
  final int? caloriesMax;
  final int? proteinMin;
  final int? prepTimeMax;
  final String? ingredients;
  final String sortBy;
  final RecipeFilterApplyCallback onApply;
  final VoidCallback onClearAll;

  const RecipeFilterSheet({
    super.key,
    required this.cuisine,
    required this.mealType,
    required this.difficulty,
    required this.dietaryTag,
    required this.caloriesMax,
    required this.proteinMin,
    required this.prepTimeMax,
    required this.ingredients,
    required this.sortBy,
    required this.onApply,
    required this.onClearAll,
  });

  static Future<void> show(
    BuildContext context, {
    required String? cuisine,
    required String? mealType,
    required String? difficulty,
    required String? dietaryTag,
    required int? caloriesMax,
    required int? proteinMin,
    required int? prepTimeMax,
    required String? ingredients,
    required String sortBy,
    required RecipeFilterApplyCallback onApply,
    required VoidCallback onClearAll,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecipeFilterSheet(
        cuisine: cuisine,
        mealType: mealType,
        difficulty: difficulty,
        dietaryTag: dietaryTag,
        caloriesMax: caloriesMax,
        proteinMin: proteinMin,
        prepTimeMax: prepTimeMax,
        ingredients: ingredients,
        sortBy: sortBy,
        onApply: onApply,
        onClearAll: onClearAll,
      ),
    );
  }

  @override
  State<RecipeFilterSheet> createState() => _RecipeFilterSheetState();
}

class _RecipeFilterSheetState extends State<RecipeFilterSheet> {
  static const List<String> _cuisines = [
    'american',
    'french',
    'greek',
    'italian',
    'japanese',
    'mexican',
    'portuguese',
    'spanish',
    'thai',
    'turkish',
  ];

  static const List<String> _dietary = [
    'vegetarian',
    'vegan',
    'gluten_free',
    'dairy_free',
    'nut_free',
    'halal',
    'kosher',
  ];

  static const List<String> _sortOptions = [
    'name',
    'prep_time',
    'cook_time',
    'calories_per_serving',
    'protein',
  ];

  late String? _cuisine;
  late String? _difficulty;
  late String? _dietaryTag;
  late double _caloriesMax;
  late double _proteinMin;
  late double _prepTimeMax;
  late TextEditingController _ingredientsCtrl;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _cuisine = widget.cuisine;
    _difficulty = widget.difficulty;
    _dietaryTag = widget.dietaryTag;
    _caloriesMax = (widget.caloriesMax ?? 2000).toDouble().clamp(200, 2000);
    _proteinMin = (widget.proteinMin ?? 0).toDouble().clamp(0, 80);
    _prepTimeMax = (widget.prepTimeMax ?? 240).toDouble().clamp(5, 240);
    _ingredientsCtrl = TextEditingController(text: widget.ingredients ?? '');
    _sortBy = widget.sortBy;
  }

  @override
  void dispose() {
    _ingredientsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final maxHeight = availableHeight * 0.65 + mediaQuery.viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: NColors.bgSecondary(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(NColors.radiusModal),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NColors.divider(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filters',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: NColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Refine recipes by cuisine, diet, macros, and prep time.',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: NColors.textSecondary(context),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionTitle('Cuisine', context),
                      const SizedBox(height: 8),
                      _dropdown<String?>(
                        context: context,
                        value: _cuisine,
                        hint: 'Any cuisine',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Any'),
                          ),
                          ..._cuisines.map(
                            (c) => DropdownMenuItem<String?>(
                              value: c,
                              child: Text(_labelize(c)),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _cuisine = v),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Difficulty', context),
                      const SizedBox(height: 8),
                      _dropdown<String?>(
                        context: context,
                        value: _difficulty,
                        hint: 'Any difficulty',
                        items: const [
                          DropdownMenuItem<String?>(value: null, child: Text('Any')),
                          DropdownMenuItem(value: 'easy', child: Text('Easy')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'hard', child: Text('Hard')),
                        ],
                        onChanged: (v) => setState(() => _difficulty = v),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Dietary tag', context),
                      const SizedBox(height: 8),
                      _dropdown<String?>(
                        context: context,
                        value: _dietaryTag,
                        hint: 'Any',
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Any'),
                          ),
                          ..._dietary.map(
                            (d) => DropdownMenuItem<String?>(
                              value: d,
                              child: Text(_labelize(d.replaceAll('_', ' '))),
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _dietaryTag = v),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Sort by', context),
                      const SizedBox(height: 8),
                      _dropdown<String>(
                        context: context,
                        value: _sortBy,
                        hint: 'Sort',
                        items: _sortOptions
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(_labelize(s.replaceAll('_', ' '))),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _sortBy = v);
                        },
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Max calories / serving', context),
                      Slider(
                        value: _caloriesMax,
                        min: 200,
                        max: 2000,
                        divisions: 36,
                        label: '${_caloriesMax.round()} kcal',
                        activeColor: NColors.accentPrimary(context),
                        onChanged: (v) => setState(() => _caloriesMax = v),
                      ),
                      const SizedBox(height: 4),
                      _sectionTitle('Min protein / serving (g)', context),
                      Slider(
                        value: _proteinMin,
                        min: 0,
                        max: 80,
                        divisions: 16,
                        label: '${_proteinMin.round()} g',
                        activeColor: NColors.accentSecondary(context),
                        onChanged: (v) => setState(() => _proteinMin = v),
                      ),
                      const SizedBox(height: 4),
                      _sectionTitle('Max prep time (minutes)', context),
                      Slider(
                        value: _prepTimeMax,
                        min: 5,
                        max: 240,
                        divisions: 47,
                        label: '${_prepTimeMax.round()} min',
                        activeColor: NColors.warningAccent(context),
                        onChanged: (v) => setState(() => _prepTimeMax = v),
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Ingredients (comma-separated)', context),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _ingredientsCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'tomato, basil, chicken',
                          filled: true,
                          fillColor: NColors.bgPrimary(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(NColors.radiusInput),
                            borderSide: BorderSide(color: NColors.divider(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(NColors.radiusInput),
                            borderSide: BorderSide(color: NColors.divider(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(NColors.radiusInput),
                            borderSide: BorderSide(color: NColors.accentPrimary(context)),
                          ),
                        ),
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          color: NColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      widget.onClearAll();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Clear all',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        color: NColors.textSecondary(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        widget.onApply(
                          cuisine: _cuisine,
                          mealType: widget.mealType,
                          difficulty: _difficulty,
                          dietaryTag: _dietaryTag,
                          caloriesMax: _caloriesMax >= 1990 ? null : _caloriesMax.round(),
                          proteinMin: _proteinMin <= 0 ? null : _proteinMin.round(),
                          prepTimeMax: _prepTimeMax >= 235 ? null : _prepTimeMax.round(),
                          ingredients: _ingredientsCtrl.text.trim().isEmpty
                              ? null
                              : _ingredientsCtrl.text.trim(),
                          sortBy: _sortBy,
                        );
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: NColors.accentPrimary(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(NColors.radiusButton),
                        ),
                      ),
                      child: Text(
                        'Apply filters',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t, BuildContext context) {
    return Text(
      t,
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: NColors.textPrimary(context),
        letterSpacing: 0.2,
      ),
    );
  }

  String _labelize(String raw) {
    return raw
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map(
          (w) => w[0].toUpperCase() + w.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  Widget _dropdown<T>({
    required BuildContext context,
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: NColors.bgPrimary(context),
        borderRadius: BorderRadius.circular(NColors.radiusInput),
        border: Border.all(color: NColors.divider(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: GoogleFonts.montserrat(color: NColors.textSecondary(context))),
          items: items,
          onChanged: onChanged,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: NColors.textPrimary(context),
          ),
          borderRadius: BorderRadius.circular(NColors.radiusInput),
        ),
      ),
    );
  }
}
