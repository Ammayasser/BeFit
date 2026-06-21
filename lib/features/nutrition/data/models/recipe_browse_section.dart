// lib/features/nutrition/data/models/recipe_browse_section.dart

/// Home browse rail: maps to Spoonacular [complexSearch] filters.
class RecipeBrowseSection {
  const RecipeBrowseSection({
    required this.id,
    required this.title,
    this.query,
    this.mealType,
    this.dietaryTag,
    this.proteinMin,
    this.caloriesMax,
    this.prepTimeMax,
    this.minCarbs,
    this.maxCarbs,
    this.sortBy = 'name',
  });

  final String id;
  final String title;
  final String? query;
  final String? mealType;
  final String? dietaryTag;
  final int? proteinMin;
  final int? caloriesMax;
  final int? prepTimeMax;
  final int? minCarbs;
  final int? maxCarbs;
  final String sortBy;

  /// Curated rails shown on the recipes home (vertical stack, horizontal scroll each).
  static const List<RecipeBrowseSection> homeRails = [
    RecipeBrowseSection(
      id: 'breakfast',
      title: 'Breakfast',
      mealType: 'breakfast',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'lunch',
      title: 'Lunch',
      mealType: 'main',
      query: 'lunch',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'dinner',
      title: 'Dinner',
      mealType: 'main',
      query: 'dinner',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'snacks',
      title: 'Snacks',
      mealType: 'snack',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'high_protein',
      title: 'High protein',
      proteinMin: 28,
      sortBy: 'protein',
    ),
    RecipeBrowseSection(
      id: 'higher_carb',
      title: 'Higher carb',
      minCarbs: 35,
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'healthy',
      title: 'Healthy',
      caloriesMax: 520,
      proteinMin: 12,
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'pre_workout',
      title: 'Pre-workout',
      prepTimeMax: 30,
      minCarbs: 18,
      sortBy: 'prep_time',
    ),
    RecipeBrowseSection(
      id: 'post_workout',
      title: 'Post-workout',
      proteinMin: 24,
      sortBy: 'protein',
    ),
    RecipeBrowseSection(
      id: 'low_carb',
      title: 'Low carb',
      maxCarbs: 22,
      proteinMin: 15,
      sortBy: 'protein',
    ),
    RecipeBrowseSection(
      id: 'vegetarian',
      title: 'Vegetarian',
      dietaryTag: 'vegetarian',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'vegan',
      title: 'Vegan',
      dietaryTag: 'vegan',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'quick',
      title: 'Quick & easy',
      prepTimeMax: 25,
      sortBy: 'prep_time',
    ),
    RecipeBrowseSection(
      id: 'desserts',
      title: 'Desserts',
      mealType: 'dessert',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'soups',
      title: 'Soups',
      mealType: 'soup',
      sortBy: 'name',
    ),
    RecipeBrowseSection(
      id: 'keto',
      title: 'Keto-friendly',
      dietaryTag: 'ketogenic',
      sortBy: 'name',
    ),
  ];
}
