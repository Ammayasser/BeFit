// lib/features/nutrition/data/models/recipe.dart

/// Recipe model (backed by [Spoonacular Food API](https://spoonacular.com/food-api)).
class Recipe {
  final int id;
  final String name;
  final String? description;
  final String? difficulty;
  final String? mealType;
  final String? cuisine;
  final List<String> dietaryTags;
  final int servings;
  final int prepTime;
  final int cookTime;
  final int caloriesPerServing;
  final int protein;
  final List<String> instructions;
  final List<RecipeIngredient> ingredients;
  final bool isFavorite;
  final String? imageUrl;

  const Recipe({
    required this.id,
    required this.name,
    this.description,
    this.difficulty,
    this.mealType,
    this.cuisine,
    this.dietaryTags = const [],
    this.servings = 1,
    this.prepTime = 0,
    this.cookTime = 0,
    this.caloriesPerServing = 0,
    this.protein = 0,
    this.instructions = const [],
    this.ingredients = const [],
    this.isFavorite = false,
    this.imageUrl,
  });

  int get totalTime => prepTime + cookTime;

  /// API does not expose carbs; placeholder for diary / display extensions.
  double get carbsPerServingPlaceholder => 0.0;

  Recipe copyWith({
    int? id,
    String? name,
    String? description,
    String? difficulty,
    String? mealType,
    String? cuisine,
    List<String>? dietaryTags,
    int? servings,
    int? prepTime,
    int? cookTime,
    int? caloriesPerServing,
    int? protein,
    List<String>? instructions,
    List<RecipeIngredient>? ingredients,
    bool? isFavorite,
    String? imageUrl,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      mealType: mealType ?? this.mealType,
      cuisine: cuisine ?? this.cuisine,
      dietaryTags: dietaryTags ?? this.dietaryTags,
      servings: servings ?? this.servings,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      protein: protein ?? this.protein,
      instructions: instructions ?? this.instructions,
      ingredients: ingredients ?? this.ingredients,
      isFavorite: isFavorite ?? this.isFavorite,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'difficulty': difficulty,
        'meal_type': mealType,
        'cuisine': cuisine,
        'dietary_tags': dietaryTags,
        'servings': servings,
        'prep_time': prepTime,
        'cook_time': cookTime,
        'calories_per_serving': caloriesPerServing,
        'protein': protein,
        'instructions': instructions,
        'ingredients': ingredients.map((e) => e.toJson()).toList(),
        'isFavorite': isFavorite,
        'imageUrl': imageUrl,
      };

  static String? _parseImageUrl(Map<String, dynamic> json) {
    bool isHttp(String? s) =>
        s != null && (s.startsWith('http://') || s.startsWith('https://'));
    for (final key in [
      'image_url',
      'image',
      'thumbnail_url',
      'photo_url',
      'cover_image',
      'hero_image',
    ]) {
      final v = json[key];
      if (v is String && isHttp(v)) return v.trim();
      if (v is Map && v['url'] is String && isHttp(v['url'] as String)) {
        return (v['url'] as String).trim();
      }
    }
    return null;
  }

  factory Recipe.fromJson(Map<String, dynamic> json, {bool isFavorite = false}) {
    final tags = json['dietary_tags'];
    final instructionsRaw = json['instructions'];
    final ingredientsRaw = json['ingredients'];

    return Recipe(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      difficulty: json['difficulty'] as String?,
      mealType: json['meal_type'] as String?,
      cuisine: json['cuisine'] as String?,
      dietaryTags: tags is List
          ? tags.map((e) => e.toString()).toList()
          : const <String>[],
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      prepTime: (json['prep_time'] as num?)?.toInt() ?? 0,
      cookTime: (json['cook_time'] as num?)?.toInt() ?? 0,
      caloriesPerServing:
          (json['calories_per_serving'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      instructions: instructionsRaw is List
          ? instructionsRaw.map((e) => e.toString()).toList()
          : const <String>[],
      ingredients: ingredientsRaw is List
          ? ingredientsRaw
              .whereType<Map>()
              .map(
                (e) => RecipeIngredient.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const <RecipeIngredient>[],
      isFavorite: isFavorite,
      imageUrl: _parseImageUrl(json),
    );
  }

  static double? _nutrientAmount(List? nutrients, String name) {
    if (nutrients == null) return null;
    final want = name.toLowerCase();
    for (final n in nutrients) {
      if (n is! Map) continue;
      final nm = (n['name'] as String?)?.toLowerCase();
      if (nm == want) return (n['amount'] as num?)?.toDouble();
    }
    return null;
  }

  static String? _healthToDifficulty(double? score) {
    if (score == null) return null;
    if (score >= 66) return 'easy';
    if (score >= 33) return 'medium';
    return 'hard';
  }

  static String? _stripHtml(String? html) {
    if (html == null) return null;
    return html
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> _instructionsFromAnalyzed(List? analyzed) {
    final out = <String>[];
    if (analyzed is! List) return out;
    for (final block in analyzed) {
      if (block is! Map) continue;
      final steps = block['steps'] as List?;
      for (final s in steps ?? const []) {
        if (s is Map && s['step'] is String) {
          final t = (s['step'] as String).trim();
          if (t.isNotEmpty) out.add(t);
        }
      }
    }
    return out;
  }

  /// Spoonacular [complexSearch] result row (`addRecipeInformation` + `addRecipeNutrition`).
  factory Recipe.fromSpoonacularSearch(
    Map<String, dynamic> json, {
    bool isFavorite = false,
  }) {
    final nutrients = (json['nutrition'] as Map?)?['nutrients'] as List?;
    final cal = _nutrientAmount(nutrients, 'Calories')?.round() ?? 0;
    final prot = _nutrientAmount(nutrients, 'Protein')?.round() ?? 0;
    final ready = (json['readyInMinutes'] as num?)?.toInt() ?? 0;
    var prep = (json['preparationMinutes'] as num?)?.toInt() ?? 0;
    var cook = (json['cookingMinutes'] as num?)?.toInt() ?? 0;
    if (prep == 0 && cook == 0 && ready > 0) {
      prep = (ready * 0.45).round();
      cook = ready - prep;
    }
    final dishTypes = json['dishTypes'] as List?;
    final mealType = dishTypes != null && dishTypes.isNotEmpty
        ? dishTypes.first.toString().toLowerCase().replaceAll(' ', '_')
        : null;
    final cuisines = json['cuisines'] as List?;
    final cuisine = cuisines != null && cuisines.isNotEmpty
        ? cuisines.first.toString().toLowerCase()
        : null;
    final diets = json['diets'] as List?;
    final dietaryTags = diets != null
        ? diets
            .map((e) => e.toString().toLowerCase().replaceAll(' ', '_'))
            .toList()
        : const <String>[];
    final hs = (json['healthScore'] as num?)?.toDouble();
    final img = json['image'] as String?;
    return Recipe(
      id: (json['id'] as num).toInt(),
      name: json['title'] as String? ?? '',
      description: _stripHtml(json['summary'] as String?),
      difficulty: _healthToDifficulty(hs),
      mealType: mealType,
      cuisine: cuisine,
      dietaryTags: List<String>.from(dietaryTags),
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      prepTime: prep,
      cookTime: cook,
      caloriesPerServing: cal,
      protein: prot,
      instructions: const [],
      ingredients: const [],
      isFavorite: isFavorite,
      imageUrl: img != null && img.isNotEmpty ? img : null,
    );
  }

  /// Spoonacular [Get Recipe Information](https://spoonacular.com/food-api/docs#Get-Recipe-Information).
  factory Recipe.fromSpoonacularInformation(
    Map<String, dynamic> json, {
    bool isFavorite = false,
  }) {
    final analyzed = json['analyzedInstructions'] as List?;
    var steps = _instructionsFromAnalyzed(analyzed);
    if (steps.isEmpty) {
      final plain = json['instructions'] as String?;
      if (plain != null && plain.trim().isNotEmpty) {
        steps = plain
            .split(RegExp(r'\r?\n+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    final ext = json['extendedIngredients'] as List?;
    final ingredients = ext != null
        ? ext
            .whereType<Map>()
            .map((e) => RecipeIngredient.fromSpoonacular(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : const <RecipeIngredient>[];

    final nutrients = (json['nutrition'] as Map?)?['nutrients'] as List?;
    final cal = _nutrientAmount(nutrients, 'Calories')?.round() ?? 0;
    final prot = _nutrientAmount(nutrients, 'Protein')?.round() ?? 0;
    final ready = (json['readyInMinutes'] as num?)?.toInt() ?? 0;
    var prep = (json['preparationMinutes'] as num?)?.toInt() ?? 0;
    var cook = (json['cookingMinutes'] as num?)?.toInt() ?? 0;
    if (prep == 0 && cook == 0 && ready > 0) {
      prep = (ready * 0.45).round();
      cook = ready - prep;
    }
    final dishTypes = json['dishTypes'] as List?;
    final mealType = dishTypes != null && dishTypes.isNotEmpty
        ? dishTypes.first.toString().toLowerCase().replaceAll(' ', '_')
        : null;
    final cuisines = json['cuisines'] as List?;
    final cuisine = cuisines != null && cuisines.isNotEmpty
        ? cuisines.first.toString().toLowerCase()
        : null;
    final diets = json['diets'] as List?;
    final dietaryTags = diets != null
        ? diets
            .map((e) => e.toString().toLowerCase().replaceAll(' ', '_'))
            .toList()
        : const <String>[];
    final hs = (json['healthScore'] as num?)?.toDouble();
    final img = json['image'] as String?;
    return Recipe(
      id: (json['id'] as num).toInt(),
      name: json['title'] as String? ?? '',
      description: _stripHtml(json['summary'] as String?),
      difficulty: _healthToDifficulty(hs),
      mealType: mealType,
      cuisine: cuisine,
      dietaryTags: List<String>.from(dietaryTags),
      servings: (json['servings'] as num?)?.toInt() ?? 1,
      prepTime: prep,
      cookTime: cook,
      caloriesPerServing: cal,
      protein: prot,
      instructions: steps,
      ingredients: ingredients,
      isFavorite: isFavorite,
      imageUrl: img != null && img.isNotEmpty ? img : null,
    );
  }
}

class RecipeIngredient {
  final int id;
  final String name;
  final String? category;
  final double quantity;
  final String? unit;
  final bool optional;

  const RecipeIngredient({
    required this.id,
    required this.name,
    this.category,
    this.quantity = 0,
    this.unit,
    this.optional = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'optional': optional,
      };

  factory RecipeIngredient.fromSpoonacular(Map<String, dynamic> json) {
    final meta = json['meta'] as List?;
    final optional = meta != null &&
        meta.any((e) => e.toString().toLowerCase().contains('optional'));
    return RecipeIngredient(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?)?.trim() ?? '',
      category: json['aisle'] as String?,
      quantity: (json['amount'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String?,
      optional: optional,
    );
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String?,
      optional: json['optional'] as bool? ?? false,
    );
  }
}
