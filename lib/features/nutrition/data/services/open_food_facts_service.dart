// lib/features/nutrition/data/services/open_food_facts_service.dart

import 'package:openfoodfacts/openfoodfacts.dart';

import '../models/food_item.dart';
import '../utils/food_search_relevance.dart';
import '../utils/off_device_country.dart';
import 'usda_food_service.dart';

class OpenFoodFactsService {
  static bool _initialized = false;

  final UsdaFoodService _usdaService = UsdaFoodService();

  /// Initialize the Open Food Facts API configuration.
  /// Call once at app startup.
  static void initialize() {
    if (_initialized) return;
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'BeFit',
      version: '1.0.0',
      comment: 'Flutter fitness and nutrition tracker',
    );
    OpenFoodAPIConfiguration.globalLanguages = [
      OpenFoodFactsLanguage.ENGLISH,
    ];
    // Biases search + product fetch to the device region (`cc`), so users
    // are not flooded with unrelated EU/US-only packaging by default.
    OpenFoodAPIConfiguration.globalCountry = resolveOffDeviceCountry();
    _initialized = true;
  }

  static final List<ProductField> _commonFields = [
    ProductField.NAME,
    ProductField.BRANDS,
    ProductField.BARCODE,
    ProductField.IMAGE_FRONT_SMALL_URL,
    ProductField.NUTRIMENTS,
    ProductField.NUTRISCORE,
    ProductField.NOVA_GROUP,
    ProductField.SERVING_SIZE,
    ProductField.SERVING_QUANTITY,
    ProductField.ECOSCORE_GRADE,
  ];

  /// Search for foods by name.
  ///
  /// Runs two searches **in parallel**:
  /// 1. USDA FoodData Central → generic/whole foods (egg, chicken, rice…)
  /// 2. Open Food Facts → branded/packaged products (scoped to device region)
  ///
  /// Results from both sources are scored by name relevance and merged.
  Future<List<FoodItem>> searchByName(String query, {int page = 1}) async {
    initialize();
    final lowerQuery = query.trim().toLowerCase();

    final results = await Future.wait([
      _usdaService.search(query, pageSize: 15).catchError((_) => <FoodItem>[]),
      _searchOpenFoodFacts(query, lowerQuery, page),
    ]);

    final usdaResults = results[0];
    final offResults = results[1];

    final scoredUsda = usdaResults
        .map(
          (item) => _MapEntry(
            item,
            foodNameRelevanceScore(
              item.name,
              lowerQuery,
              secondaryLabel: item.brand,
            ),
          ),
        )
        .toList();

    final scoredOff = offResults
        .take(30)
        .map(
          (item) => _MapEntry(
            item,
            foodNameRelevanceScore(
              item.name,
              lowerQuery,
              secondaryLabel: item.brand,
            ),
          ),
        )
        .toList();

    final merged = [...scoredUsda, ...scoredOff];
    merged.sort((a, b) {
      // 1. First by relevance score category (High vs Medium vs Low)
      final scoreA = a.score;
      final scoreB = b.score;
      
      // If both are extremely relevant, prefer the generic one
      if (scoreA >= 90 && scoreB >= 90) {
        if (a.item.isGeneric != b.item.isGeneric) {
          return a.item.isGeneric ? -1 : 1;
        }
      }

      final byScore = scoreB.compareTo(scoreA);
      if (byScore != 0) return byScore;

      // 2. Tie-break with isGeneric
      if (a.item.isGeneric != b.item.isGeneric) {
        return a.item.isGeneric ? -1 : 1;
      }

      // 3. Tie-break with name length (usually shorter is more direct)
      return a.item.name.length.compareTo(b.item.name.length);
    });

    final seenNames = <String>{};
    final seenIds = <String>{};
    final unique = <FoodItem>[];
    for (final entry in merged) {
      final nameLower = entry.item.name.toLowerCase();
      // More aggressive deduplication for professional feel
      final head = nameLower.split(',').first.trim();
      
      final isNewId = seenIds.add(entry.item.id);
      final isNewName = seenNames.add(nameLower) && seenNames.add(head);

      if (isNewId && (isNewName || entry.item.isGeneric)) {
        unique.add(entry.item);
      }
    }

    return unique;
  }

  /// Search Open Food Facts for branded/packaged products.
  Future<List<FoodItem>> _searchOpenFoodFacts(
    String query,
    String lowerQuery,
    int page,
  ) async {
    try {
      final config = ProductSearchQueryConfiguration(
        parametersList: [
          SearchTerms(terms: [query]),
          const PageSize(size: 50),
          PageNumber(page: page),
          const SortBy(option: SortOption.POPULARITY),
          TagFilter.fromType(
            tagFilterType: TagFilterType.LANGUAGES,
            tagName: 'en',
          ),
        ],
        language: OpenFoodFactsLanguage.ENGLISH,
        country: OpenFoodAPIConfiguration.globalCountry ?? resolveOffDeviceCountry(),
        version: ProductQueryVersion.v3,
        fields: _commonFields,
      );

      final result = await OpenFoodAPIClient.searchProducts(null, config);
      if (result.products == null) return [];

      final allApi = result.products!
          .where((p) => p.productName != null && p.productName!.isNotEmpty)
          .map(_mapToFoodItem)
          .toList();

      // Re-rank: name matches first, ingredient-only matches last
      int relevance(FoodItem item) => foodNameRelevanceScore(
            item.name,
            lowerQuery,
            secondaryLabel: item.brand,
          );

      allApi.sort((a, b) => relevance(b).compareTo(relevance(a)));

      // De-duplicate
      final seen = <String>{};
      final unique = <FoodItem>[];
      for (final item in allApi) {
        if (seen.add(item.id)) unique.add(item);
      }
      return unique;
    } catch (_) {
      return [];
    }
  }

  /// Look up a product by its barcode
  Future<FoodItem?> getByBarcode(String barcode) async {
    initialize();
    final config = ProductQueryConfiguration(
      barcode,
      version: ProductQueryVersion.v3,
      language: OpenFoodFactsLanguage.ENGLISH,
      country: OpenFoodAPIConfiguration.globalCountry ?? resolveOffDeviceCountry(),
      fields: _commonFields,
    );
    final result = await OpenFoodAPIClient.getProductV3(config);
    if (result.product == null || result.product!.productName == null) {
      return null;
    }
    return _mapToFoodItem(result.product!);
  }

  /// Map an OpenFoodFacts Product → domain FoodItem
  FoodItem _mapToFoodItem(Product product) {
    final n = product.nutriments;
    return FoodItem(
      id: product.barcode ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: product.productName ?? 'Unknown Product',
      brand: product.brands,
      imageUrl: product.imageFrontSmallUrl,
      caloriesPer100g: n?.getValue(Nutrient.energyKCal, PerSize.oneHundredGrams) ?? 0.0,
      proteinPer100g: n?.getValue(Nutrient.proteins, PerSize.oneHundredGrams) ?? 0.0,
      carbsPer100g: n?.getValue(Nutrient.carbohydrates, PerSize.oneHundredGrams) ?? 0.0,
      fatPer100g: n?.getValue(Nutrient.fat, PerSize.oneHundredGrams) ?? 0.0,
      fiberPer100g: n?.getValue(Nutrient.fiber, PerSize.oneHundredGrams),
      sugarPer100g: n?.getValue(Nutrient.sugars, PerSize.oneHundredGrams),
      saturatedFatPer100g: n?.getValue(Nutrient.saturatedFat, PerSize.oneHundredGrams),
      sodiumPer100g: n?.getValue(Nutrient.sodium, PerSize.oneHundredGrams),
      servingSize: product.servingSize,
      servingGrams: product.servingQuantity,
      nutriScore: product.nutriscore,
      novaGroup: product.novaGroup,
    );
  }
}

class _MapEntry {
  final FoodItem item;
  final int score;
  const _MapEntry(this.item, this.score);
}
