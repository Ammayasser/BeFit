// lib/features/nutrition/data/services/usda_food_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/food_item.dart';

/// Service that queries the USDA FoodData Central API for generic/whole foods.
///
/// This API returns real foods (egg, chicken breast, rice, etc.) with
/// accurate USDA nutritional data — unlike Open Food Facts which is
/// a packaged-product database.
///
/// Uses `Foundation` and `SR Legacy` data types which contain only
/// generic whole foods, not branded products.
class UsdaFoodService {
  static const String _baseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const String _apiKey = String.fromEnvironment('BEFIT_USDA_API_KEY');

  /// Nutrient IDs in the USDA system
  static const int _energyKcal = 1008;
  /// Foundation foods often omit 1008 in search payloads and use Atwater energies.
  static const int _energyAtwaterGeneral = 2047;
  static const int _energyAtwaterSpecific = 2048;
  static const int _protein = 1003;
  static const int _fat = 1004;
  static const int _carbs = 1005;
  static const int _fiber = 1079;
  static const int _sugar = 2000; // Total Sugars
  static const int _sugarAlt = 1063; // Sugars, Total (Foundation)
  static const int _saturatedFat = 1258;
  static const int _sodium = 1093;

  /// Search for generic/whole foods by name.
  ///
  /// Returns foods from the USDA Foundation and SR Legacy databases,
  /// which contain only generic whole foods (not branded products).
  Future<List<FoodItem>> search(String query, {int pageSize = 15}) async {
    if (query.trim().length < 2) return [];

    final uri = Uri.parse('$_baseUrl/foods/search').replace(
      queryParameters: {
        'api_key': _apiKey,
        'query': query,
        'dataType': 'Foundation,SR Legacy',
        'pageSize': pageSize.toString(),
        'sortBy': 'score',
        'sortOrder': 'desc',
      },
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];

      final data = json.decode(response.body) as Map<String, dynamic>;
      final foods = data['foods'] as List<dynamic>? ?? [];

      return foods
          .map((f) => _mapToFoodItem(f as Map<String, dynamic>))
          .where((item) => item != null)
          .cast<FoodItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  FoodItem? _mapToFoodItem(Map<String, dynamic> food) {
    final description = food['description'] as String? ?? '';
    if (description.isEmpty) return null;

    final nutrients = food['foodNutrients'] as List<dynamic>? ?? [];

    // Build a lookup map: nutrientId → value
    final nutrientMap = <int, double>{};
    for (final n in nutrients) {
      if (n is! Map<String, dynamic>) continue;
      final id = _readNutrientId(n);
      final value = _readNutrientValue(n);
      if (id != null && value != null) {
        nutrientMap[id] = value;
      }
    }

    final calories = _resolveEnergyKcal(nutrientMap);
    // Skip entries with no usable calorie data — they add noise to search results
    if (calories <= 0) return null;

    final protein = nutrientMap[_protein] ?? 0;
    final fat = nutrientMap[_fat] ?? 0;
    final carbs = nutrientMap[_carbs] ?? 0;

    // Clean up the description (remove "Eggs, Grade A, Large, " prefix style)
    final cleanName = _cleanDescription(description);

    return FoodItem(
      id: 'usda_${food['fdcId']}',
      name: cleanName,
      brand: food['foodCategory'] as String?,
      imageUrl: null,
      caloriesPer100g: calories,
      proteinPer100g: protein,
      carbsPer100g: carbs,
      fatPer100g: fat,
      fiberPer100g: nutrientMap[_fiber],
      sugarPer100g: nutrientMap[_sugar] ?? nutrientMap[_sugarAlt],
      saturatedFatPer100g: nutrientMap[_saturatedFat],
      sodiumPer100g: nutrientMap[_sodium],
      servingSize: null,
      servingGrams: 100,
      nutriScore: null,
      novaGroup: null,
      isGeneric: true,
    );
  }

  /// Clean up USDA descriptions to be more user-friendly.
  /// e.g. "Eggs, Grade A, Large, egg whole" → "Egg, whole (Grade A, Large)"
  /// e.g. "Chicken, broilers or fryers, breast" → "Chicken breast"
  String _cleanDescription(String desc) {
    // Capitalize first letter of each word nicely
    var cleaned = desc
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .join(', ');

    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }

    return cleaned;
  }

  static int? _readNutrientId(Map<String, dynamic> n) {
    final raw = n['nutrientId'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final nested = n['nutrient'];
    if (nested is Map<String, dynamic>) {
      final id = nested['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
    }
    return null;
  }

  static double? _readNutrientValue(Map<String, dynamic> n) {
    final raw = n['value'] ?? n['amount'];
    if (raw is num) return raw.toDouble();
    return null;
  }

  /// SR Legacy usually exposes 1008; Foundation search often exposes 2047/2048 only.
  static double _resolveEnergyKcal(Map<int, double> nutrientMap) {
    final k1008 = nutrientMap[_energyKcal];
    if (k1008 != null && k1008 > 0) return k1008;
    final k2048 = nutrientMap[_energyAtwaterSpecific];
    if (k2048 != null && k2048 > 0) return k2048;
    final k2047 = nutrientMap[_energyAtwaterGeneral];
    if (k2047 != null && k2047 > 0) return k2047;
    final p = nutrientMap[_protein] ?? 0;
    final f = nutrientMap[_fat] ?? 0;
    final c = nutrientMap[_carbs] ?? 0;
    if (p > 0 || f > 0 || c > 0) {
      return 4 * p + 4 * c + 9 * f;
    }
    return 0;
  }
}
