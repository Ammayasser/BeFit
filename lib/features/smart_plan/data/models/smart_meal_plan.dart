// lib/features/smart_plan/data/models/smart_meal_plan.dart

class SmartMealRecipe {
  final String food;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;

  const SmartMealRecipe({
    required this.food,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
  });

  factory SmartMealRecipe.fromJson(Map<String, dynamic> json) {
    return SmartMealRecipe(
      food: json['food']?.toString() ?? '',
      calories: _toDouble(json['calories']),
      protein: _toDouble(json['protein']),
      carbohydrates: _toDouble(json['carbohydrates']),
      fat: _toDouble(json['fat']),
    );
  }

  Map<String, dynamic> toJson() => {
        'food': food,
        'calories': calories,
        'protein': protein,
        'carbohydrates': carbohydrates,
        'fat': fat,
      };

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class SmartMealPlan {
  final double recommendedCalories;
  final double bmi;
  final String bmiCategory;
  final double bmr;
  final double tdee;
  final String goal;
  final List<SmartMealRecipe> breakfast;
  final List<SmartMealRecipe> lunch;
  final List<SmartMealRecipe> dinner;
  final DateTime generatedAt;

  const SmartMealPlan({
    required this.recommendedCalories,
    required this.bmi,
    required this.bmiCategory,
    required this.bmr,
    required this.tdee,
    required this.goal,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.generatedAt,
  });

  factory SmartMealPlan.fromApiResponse(Map<String, dynamic> json) {
    List<SmartMealRecipe> parseRecipes(dynamic mealJson) {
      if (mealJson == null) return [];
      final recipes = mealJson['recipes'];
      if (recipes is! List) return [];
      return recipes
          .whereType<Map<String, dynamic>>()
          .map((r) => SmartMealRecipe.fromJson(r))
          .toList();
    }

    final meals = json['meals'] as Map<String, dynamic>? ?? {};

    return SmartMealPlan(
      recommendedCalories: _toDouble(json['recommended_calories']),
      bmi: _toDouble(json['bmi']),
      bmiCategory: json['bmi_category']?.toString() ?? '',
      bmr: _toDouble(json['bmr']),
      tdee: _toDouble(json['tdee']),
      goal: json['goal']?.toString() ?? '',
      breakfast: parseRecipes(meals['breakfast']),
      lunch: parseRecipes(meals['lunch']),
      dinner: parseRecipes(meals['dinner']),
      generatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'recommendedCalories': recommendedCalories,
        'bmi': bmi,
        'bmiCategory': bmiCategory,
        'bmr': bmr,
        'tdee': tdee,
        'goal': goal,
        'breakfast': breakfast.map((r) => r.toJson()).toList(),
        'lunch': lunch.map((r) => r.toJson()).toList(),
        'dinner': dinner.map((r) => r.toJson()).toList(),
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory SmartMealPlan.fromJson(Map<String, dynamic> json) {
    List<SmartMealRecipe> parseRecipes(dynamic list) {
      if (list is! List) return [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((r) => SmartMealRecipe.fromJson(r))
          .toList();
    }

    return SmartMealPlan(
      recommendedCalories: _toDouble(json['recommendedCalories']),
      bmi: _toDouble(json['bmi']),
      bmiCategory: json['bmiCategory']?.toString() ?? '',
      bmr: _toDouble(json['bmr']),
      tdee: _toDouble(json['tdee']),
      goal: json['goal']?.toString() ?? '',
      breakfast: parseRecipes(json['breakfast']),
      lunch: parseRecipes(json['lunch']),
      dinner: parseRecipes(json['dinner']),
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'].toString())
          : DateTime.now(),
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
