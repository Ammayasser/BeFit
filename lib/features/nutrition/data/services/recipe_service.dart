// lib/features/nutrition/data/services/recipe_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:befit/core/constants/api_constants.dart';

import '../models/recipe.dart';
import 'recipe_api_exception.dart';

/// Paginated list response (Spoonacular [complexSearch]).
class RecipeListResult {
  final List<Recipe> recipes;
  final int totalCount;
  final int currentPage;
  final int lastPage;
  final bool hasNextPage;

  const RecipeListResult({
    required this.recipes,
    required this.totalCount,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
  });
}

class RecipeService {
  RecipeService({http.Client? httpClient}) : _client = httpClient ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 25);

  Uri _uri(String path, [Map<String, String>? query]) {
    final q = <String, String>{
      'apiKey': ApiConstants.spoonacularApiKey.trim(),
      if (query != null) ...query,
    };
    return Uri.parse('${ApiConstants.spoonacularBaseUrl}$path').replace(
      queryParameters: q,
    );
  }

  void _ensureKey() {
    if (ApiConstants.spoonacularApiKey.trim().isEmpty) {
      throw const RecipeApiException(
        'Spoonacular API key is not configured. Build with '
        '--dart-define=BEFIT_SPOONACULAR_API_KEY=your_key',
        null,
      );
    }
  }

  /// [Spoonacular complexSearch](https://spoonacular.com/food-api/docs#Search-Recipes-Complex)
  Future<RecipeListResult> searchRecipes({
    String? query,
    String? cuisine,
    String? mealType,
    String? difficulty,
    String? dietaryTag,
    int? caloriesMin,
    int? caloriesMax,
    int? proteinMin,
    int? prepTimeMax,
    int? minCarbs,
    int? maxCarbs,
    String? ingredients,
    String sortBy = 'name',
    int page = 1,
    int perPage = 10,
    int? customOffset,
  }) async {
    _ensureKey();
    final number = perPage.clamp(1, 100);
    final offset = (customOffset ?? ((page - 1) * number)).clamp(0, 900);

    final q = <String, String>{
      'number': '$number',
      'offset': '$offset',
      'addRecipeInformation': 'true',
      'addRecipeNutrition': 'true',
      'instructionsRequired': 'true',
    };

    final t = query?.trim();
    if (t != null && t.isNotEmpty) q['query'] = t;

    if (cuisine != null && cuisine.isNotEmpty) {
      q['cuisine'] = _capitalizeWords(cuisine.replaceAll('_', ' '));
    }

    final spoonType = _mealTypeToSpoonacularType(mealType);
    if (spoonType != null) q['type'] = spoonType;

    final dietIntol = _dietaryToDietAndIntolerances(dietaryTag);
    if (dietIntol.$1 != null) q['diet'] = dietIntol.$1!;
    if (dietIntol.$2 != null) q['intolerances'] = dietIntol.$2!;

    if (caloriesMin != null) q['minCalories'] = '$caloriesMin';
    if (caloriesMax != null) q['maxCalories'] = '$caloriesMax';
    if (proteinMin != null) q['minProtein'] = '$proteinMin';
    if (prepTimeMax != null) q['maxReadyTime'] = '$prepTimeMax';
    if (minCarbs != null) q['minCarbs'] = '$minCarbs';
    if (maxCarbs != null) q['maxCarbs'] = '$maxCarbs';

    if (ingredients != null && ingredients.trim().isNotEmpty) {
      q['includeIngredients'] = ingredients;
    }

    final sort = _mapSort(sortBy);
    if (sort.isNotEmpty) {
      q['sort'] = sort;
      q['sortDirection'] = _sortDirectionFor(sort);
    }

    final uri = _uri('/recipes/complexSearch', q);

    // ── Caching Logic ────────
    final cacheKey = _generateCacheKey(q);
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    if (cachedData != null) {
      try {
        final cacheMap = jsonDecode(cachedData) as Map<String, dynamic>;
        final timestamp = cacheMap['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        // 24 hour cache
        if (now - timestamp < 24 * 60 * 60 * 1000) {
          final body = cacheMap['body'] as String;
          return _processSearchResponse(body, number, offset);
        }
      } catch (_) {
        // Cache miss or corrupt
      }
    }

    try {
      final res = await _client.get(uri).timeout(_timeout);
      _throwIfError(res);

      // Save to cache
      await prefs.setString(
        cacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'body': res.body,
        }),
      );

      return _processSearchResponse(res.body, number, offset);
    } on RecipeApiException {
      rethrow;
    } on SocketException {
      throw const RecipeApiException(
        'No internet connection. Check your network and try again.',
        null,
      );
    } on TimeoutException {
      throw const RecipeApiException(
        'The request timed out. Please try again.',
        null,
      );
    } catch (e) {
      throw RecipeApiException('Failed to load recipes: $e', null);
    }
  }

  /// [Get Recipe Information](https://spoonacular.com/food-api/docs#Get-Recipe-Information)
  Future<Recipe> getRecipeById(int id) async {
    _ensureKey();
    final q = {'includeNutrition': 'true'};
    final uri = _uri('/recipes/$id/information', q);

    final cacheKey = 'spoon_detail_$id';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final cacheMap = jsonDecode(cached) as Map<String, dynamic>;
        final ts = cacheMap['timestamp'] as int;
        if (DateTime.now().millisecondsSinceEpoch - ts < 24 * 60 * 60 * 1000) {
          return Recipe.fromSpoonacularInformation(
            jsonDecode(cacheMap['body']),
          );
        }
      } catch (_) {}
    }

    try {
      final res = await _client.get(uri).timeout(_timeout);
      if (res.statusCode == 404) {
        throw const RecipeApiException('Recipe not found.', 404);
      }
      _throwIfError(res);

      await prefs.setString(
        cacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'body': res.body,
        }),
      );

      final map = jsonDecode(res.body) as Map<String, dynamic>;
      return Recipe.fromSpoonacularInformation(map);
    } on RecipeApiException {
      rethrow;
    } on SocketException {
      throw const RecipeApiException(
        'No internet connection. Check your network and try again.',
        null,
      );
    } on TimeoutException {
      throw const RecipeApiException(
        'The request timed out. Please try again.',
        null,
      );
    } catch (e) {
      throw RecipeApiException('Failed to load recipe: $e', null);
    }
  }

  /// Random recipe via [complexSearch] `sort=random` so filters match search.
  Future<Recipe> getRandomRecipe({
    String? cuisine,
    String? mealType,
    String? difficulty,
    String? dietaryTag,
  }) async {
    final r = await searchRecipes(
      query: null,
      cuisine: cuisine,
      mealType: mealType,
      difficulty: difficulty,
      dietaryTag: dietaryTag,
      sortBy: 'random',
      page: 1,
      perPage: 1,
      customOffset: Random().nextInt(450),
    );
    if (r.recipes.isEmpty) {
      throw const RecipeApiException(
        'No recipe found matching your filters.',
        404,
      );
    }
    return r.recipes.first;
  }

  static String _capitalizeWords(String raw) {
    return raw
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String? _mealTypeToSpoonacularType(String? mealType) {
    if (mealType == null || mealType.isEmpty) return null;
    switch (mealType.toLowerCase()) {
      case 'main':
        return 'main course';
      case 'side_dish':
        return 'side dish';
      case 'starter':
        return 'starter';
      case 'breakfast':
        return 'breakfast';
      case 'brunch':
        return 'brunch';
      case 'snack':
        return 'snack';
      case 'dessert':
        return 'dessert';
      case 'appetizer':
        return 'appetizer';
      case 'soup':
        return 'soup';
      case 'drink':
        return 'drink';
      case 'sauce':
        return 'sauce';
      default:
        return mealType.replaceAll('_', ' ');
    }
  }

  /// Returns `(diet, intolerances)` — at most one diet from a single tag.
  static (String?, String?) _dietaryToDietAndIntolerances(String? tag) {
    if (tag == null || tag.isEmpty) return (null, null);
    final t = tag.toLowerCase().replaceAll('_', ' ');
    switch (t) {
      case 'vegetarian':
      case 'vegan':
      case 'pescetarian':
      case 'paleo':
      case 'primal':
      case 'ketogenic':
        return (t, null);
      case 'gluten free':
      case 'gluten_free':
        return (null, 'gluten');
      case 'dairy free':
      case 'dairy_free':
        return (null, 'dairy');
      case 'nut free':
      case 'nut_free':
        return (null, 'peanut,tree nut');
      default:
        return (t, null);
    }
  }

  static String _mapSort(String sortBy) {
    switch (sortBy) {
      case 'prep_time':
      case 'cook_time':
        return 'time';
      case 'calories_per_serving':
        return 'calories';
      case 'protein':
        return 'protein';
      case 'random':
        return 'random';
      case 'name':
      default:
        return 'meta-score';
    }
  }

  static String _sortDirectionFor(String sort) {
    switch (sort) {
      case 'calories':
        return 'asc';
      case 'time':
        return 'asc';
      case 'protein':
        return 'desc';
      case 'meta-score':
      case 'popularity':
        return 'desc';
      default:
        return 'desc';
    }
  }

  /// [Spoonacular Get Recipe Information Bulk](https://spoonacular.com/food-api/docs#Get-Recipe-Information-Bulk)
  Future<List<Recipe>> getRecipesBulk(List<int> ids) async {
    if (ids.isEmpty) return [];
    _ensureKey();

    final q = {
      'ids': ids.join(','),
      'includeNutrition': 'true',
    };
    final uri = _uri('/recipes/informationBulk', q);

    final cacheKey = 'spoon_bulk_${ids.join('_')}';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      try {
        final cacheMap = jsonDecode(cached) as Map<String, dynamic>;
        final ts = cacheMap['timestamp'] as int;
        if (DateTime.now().millisecondsSinceEpoch - ts < 24 * 60 * 60 * 1000) {
          final list = jsonDecode(cacheMap['body']) as List;
          return list
              .whereType<Map>()
              .map((e) => Recipe.fromSpoonacularInformation(
                  Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }

    try {
      final res = await _client.get(uri).timeout(_timeout);
      _throwIfError(res);

      await prefs.setString(
        cacheKey,
        jsonEncode({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'body': res.body,
        }),
      );

      final list = jsonDecode(res.body) as List;
      return list
          .whereType<Map>()
          .map((e) => Recipe.fromSpoonacularInformation(
              Map<String, dynamic>.from(e)))
          .toList();
    } on RecipeApiException {
      rethrow;
    } on SocketException {
      throw const RecipeApiException(
        'No internet connection. Check your network and try again.',
        null,
      );
    } on TimeoutException {
      throw const RecipeApiException(
        'The request timed out. Please try again.',
        null,
      );
    } catch (e) {
      throw RecipeApiException('Failed to load recipes: $e', null);
    }
  }

  String _generateCacheKey(Map<String, String> q) {
    final sortedKeys = q.keys.toList()..sort();
    final parts = sortedKeys.map((k) => '$k=${q[k]}').toList();
    return 'spoon_search_${parts.join('_')}';
  }

  RecipeListResult _processSearchResponse(String body, int number, int offset) {
    final map = jsonDecode(body) as Map<String, dynamic>;
    final list = (map['results'] as List?) ?? const [];
    final total = (map['totalResults'] as num?)?.toInt() ?? list.length;
    final recipes = list
        .whereType<Map>()
        .map((e) => Recipe.fromSpoonacularSearch(Map<String, dynamic>.from(e)))
        .toList();

    final lastPage = total <= 0 ? 1 : ((total - 1) ~/ number) + 1;
    final current = (offset ~/ number) + 1;
    final hasNext = offset + recipes.length < total;

    return RecipeListResult(
      recipes: recipes,
      totalCount: total,
      currentPage: current,
      lastPage: lastPage,
      hasNextPage: hasNext,
    );
  }

  void _throwIfError(http.Response res) {
    final code = res.statusCode;
    if (code >= 200 && code < 300) return;

    String? serverMessage;
    try {
      final body = jsonDecode(res.body);
      if (body is Map) {
        serverMessage = body['message'] as String? ?? body['status'] as String?;
      }
    } catch (_) {}

    if (code == 401 || code == 403) {
      throw RecipeApiException(
        serverMessage ??
            'Invalid or blocked Spoonacular API key. Check BEFIT_SPOONACULAR_API_KEY.',
        code,
      );
    }
    if (code == 402) {
      throw RecipeApiException(
        serverMessage ??
            'Spoonacular quota exceeded. Upgrade your plan or try later.',
        402,
      );
    }
    if (code == 429) {
      throw RecipeApiException(
        serverMessage ?? 'Too many requests. Please wait and try again.',
        429,
      );
    }
    if (code == 404) {
      throw RecipeApiException(
        serverMessage ?? 'Resource not found.',
        404,
      );
    }

    throw RecipeApiException(
      serverMessage ?? 'Recipe service error (${res.statusCode}).',
      code,
    );
  }

  void close() {
    _client.close();
  }
}
