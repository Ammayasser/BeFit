// lib/features/nutrition/presentation/providers/recipe_provider.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/recipe.dart';
import '../../data/models/recipe_browse_section.dart';
import '../../data/services/recipe_api_exception.dart';
import '../../data/services/recipe_service.dart';

class RecipeProvider extends ChangeNotifier {
  RecipeProvider({RecipeService? recipeService})
    : _service = recipeService ?? RecipeService() {
    // Restore user state immediately on startup
    loadFavoritesFromPrefs();
  }

  final RecipeService _service;

  Future<void> refresh() async {
    if (isSectionBrowseHome) {
      await loadSectionRails();
    } else if (_showingFavorites) {
      await loadFavorites();
    } else {
      await loadRecipes(reset: true);
    }
  }

  static const String _prefsFavoriteIdsKey = 'befit_recipe_favorites';

  // ── Browse / search ─────────────────────────────────────────
  List<Recipe> _recipes = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _currentPage = 1;
  bool _hasNextPage = true;
  int _totalCount = 0;

  // ── Active filters ────────────────────────────────────────────
  String? _searchQuery;
  String? _selectedCuisine;
  String? _selectedMealType;
  String? _selectedDifficulty;
  String? _selectedDietaryTag;
  int? _caloriesMax;
  int? _proteinMin;
  int? _prepTimeMax;
  int? _minCarbs;
  int? _maxCarbs;
  String? _ingredientsCsv;
  String _sortBy = 'name';

  /// UI-only chip id (e.g. lunch vs dinner both map to API `main`).
  String? _selectedMealChipId;

  /// When set, user opened "View more" for a home rail; main grid shows that query.
  String? _browseSectionId;

  // ── Home section rails (horizontal previews) ─────────────────
  final Map<String, List<Recipe>> _sectionRecipes = {};
  bool _sectionRailsLoading = false;
  String? _sectionRailsError;
  bool _sectionRailsInitialized = false;

  // ── Random / discover ─────────────────────────────────────────
  Recipe? _randomRecipe;
  bool _isLoadingRandom = false;

  // ── Favorites ─────────────────────────────────────────────────
  final Set<int> _favoriteIds = {};
  List<Recipe> _favoriteRecipes = [];
  bool _showingFavorites = false;
  bool _isLoadingFavorites = false;

  // ── Detail ────────────────────────────────────────────────────
  Recipe? _detailRecipe;
  int? _detailForId;
  bool _isLoadingDetail = false;

  Timer? _searchDebounce;

  // ── Getters ───────────────────────────────────────────────────
  List<Recipe> get recipes =>
      _showingFavorites ? _favoriteRecipes : List.unmodifiable(_recipes);
  bool get isLoading => _showingFavorites ? _isLoadingFavorites : _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  int get currentPage => _currentPage;
  bool get hasNextPage => _showingFavorites ? false : _hasNextPage;
  int get totalCount =>
      _showingFavorites ? _favoriteRecipes.length : _totalCount;

  bool get showingFavorites => _showingFavorites;

  String? get searchQuery => _searchQuery;
  String? get selectedCuisine => _selectedCuisine;
  String? get selectedMealType => _selectedMealType;
  String? get selectedDifficulty => _selectedDifficulty;
  String? get selectedDietaryTag => _selectedDietaryTag;
  int? get caloriesMax => _caloriesMax;
  int? get proteinMin => _proteinMin;
  int? get prepTimeMax => _prepTimeMax;
  String? get ingredientsCsv => _ingredientsCsv;
  String get sortBy => _sortBy;
  String? get selectedMealChipId => _selectedMealChipId;

  String? get browseSectionId => _browseSectionId;

  String? get browseSectionTitle {
    final id = _browseSectionId;
    if (id == null) return null;
    return browseSectionForId(id)?.title;
  }

  Map<String, List<Recipe>> get sectionRecipes =>
      Map.unmodifiable(_sectionRecipes);

  bool get sectionRailsLoading => _sectionRailsLoading;

  String? get sectionRailsError => _sectionRailsError;

  bool get sectionRailsInitialized => _sectionRailsInitialized;

  /// Default home: no search, no category/filter sheet state, not in section full list.
  bool get isSectionBrowseHome {
    if (_showingFavorites) return false;
    final q = _searchQuery;
    if (q != null && q.trim().isNotEmpty) return false;
    if (_browseSectionId != null) return false;
    if (filtersActive) return false;
    return true;
  }

  bool get filtersActive =>
      !_showingFavorites &&
      ((_selectedCuisine != null && _selectedCuisine!.isNotEmpty) ||
          (_selectedMealType != null && _selectedMealType!.isNotEmpty) ||
          (_selectedDifficulty != null && _selectedDifficulty!.isNotEmpty) ||
          (_selectedDietaryTag != null && _selectedDietaryTag!.isNotEmpty) ||
          _caloriesMax != null ||
          _proteinMin != null ||
          _prepTimeMax != null ||
          _minCarbs != null ||
          _maxCarbs != null ||
          (_ingredientsCsv != null && _ingredientsCsv!.trim().isNotEmpty));

  int get activeFilterCount {
    if (_showingFavorites) return 0;
    var n = 0;
    if (_selectedCuisine != null && _selectedCuisine!.isNotEmpty) n++;
    if (_selectedMealType != null && _selectedMealType!.isNotEmpty) n++;
    if (_selectedDifficulty != null && _selectedDifficulty!.isNotEmpty) n++;
    if (_selectedDietaryTag != null && _selectedDietaryTag!.isNotEmpty) n++;
    if (_caloriesMax != null) n++;
    if (_proteinMin != null) n++;
    if (_prepTimeMax != null) n++;
    if (_minCarbs != null) n++;
    if (_maxCarbs != null) n++;
    if (_ingredientsCsv != null && _ingredientsCsv!.trim().isNotEmpty) n++;
    return n;
  }

  Recipe? get randomRecipe => _randomRecipe;
  bool get isLoadingRandom => _isLoadingRandom;

  Set<int> get favoriteIds => Set.unmodifiable(_favoriteIds);
  List<Recipe> get favoriteRecipes => List.unmodifiable(_favoriteRecipes);

  Recipe? get detailRecipe => _detailRecipe;
  int? get detailForId => _detailForId;
  bool get isLoadingDetail => _isLoadingDetail;

  Recipe _withFavorite(Recipe r) =>
      r.copyWith(isFavorite: _favoriteIds.contains(r.id));

  Future<void> loadFavoritesFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsFavoriteIdsKey);
      if (raw == null || raw.isEmpty) return;
      final list = jsonDecode(raw);
      if (list is! List) return;
      _favoriteIds
        ..clear()
        ..addAll(list.map((e) => (e as num).toInt()));
      _recipes = _recipes.map(_withFavorite).toList();
      _favoriteRecipes = _favoriteRecipes.map(_withFavorite).toList();
      for (final k in _sectionRecipes.keys.toList()) {
        _sectionRecipes[k] = _sectionRecipes[k]!.map(_withFavorite).toList();
      }
      if (_randomRecipe != null) {
        _randomRecipe = _withFavorite(_randomRecipe!);
      }
      if (_detailRecipe != null) {
        _detailRecipe = _withFavorite(_detailRecipe!);
      }
      notifyListeners();
    } catch (_) {
      // Ignore corrupt prefs
    }
  }

  Future<void> _saveFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsFavoriteIdsKey,
      jsonEncode(_favoriteIds.toList()..sort()),
    );
  }

  void toggleShowingFavorites() {
    _showingFavorites = !_showingFavorites;
    if (_showingFavorites) {
      loadFavorites();
    }
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    if (_favoriteIds.isEmpty) {
      _favoriteRecipes = [];
      notifyListeners();
      return;
    }

    _isLoadingFavorites = true;
    _error = null;
    notifyListeners();

    try {
      final list = await _service.getRecipesBulk(_favoriteIds.toList());
      _favoriteRecipes = list.map(_withFavorite).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingFavorites = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Debounced search (400 ms). Resets to page 1.
  void search(String query) {
    _showingFavorites = false;
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    _searchQuery = trimmed.isEmpty ? null : trimmed;

    if (_searchQuery == null) {
      _browseSectionId = null;
      if (filtersActive) {
        loadRecipes(reset: true);
      } else {
        _recipes = [];
        _currentPage = 1;
        _hasNextPage = true;
        _totalCount = 0;
        _error = null;
        notifyListeners();
        unawaited(loadSectionRails());
      }
      return;
    }

    _browseSectionId = null;
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      loadRecipes(reset: true);
    });
  }

  void setMealCategoryChip({required String chipId, String? apiMealType}) {
    _showingFavorites = false;
    _browseSectionId = null;
    if (chipId == 'all') {
      _selectedMealChipId = null;
      _selectedMealType = null;
    } else {
      _selectedMealChipId = chipId;
      _selectedMealType = apiMealType;
    }
    final searching = _searchQuery != null && _searchQuery!.trim().isNotEmpty;
    if (searching) {
      loadRecipes(reset: true);
    } else if (filtersActive) {
      loadRecipes(reset: true);
    } else {
      _recipes = [];
      _currentPage = 1;
      _hasNextPage = true;
      _totalCount = 0;
      _error = null;
      notifyListeners();
      unawaited(loadSectionRails());
    }
  }

  void setFilter({
    String? cuisine,
    String? mealType,
    String? difficulty,
    String? dietaryTag,
    int? caloriesMax,
    int? proteinMin,
    int? prepTimeMax,
    String? ingredients,
    String? sortBy,
  }) {
    _showingFavorites = false;
    _browseSectionId = null;
    _minCarbs = null;
    _maxCarbs = null;
    _selectedCuisine = cuisine;
    _selectedMealType = mealType;
    _selectedDifficulty = difficulty;
    _selectedDietaryTag = dietaryTag;
    _caloriesMax = caloriesMax;
    _proteinMin = proteinMin;
    _prepTimeMax = prepTimeMax;
    _ingredientsCsv = ingredients;
    if (sortBy != null && sortBy.isNotEmpty) {
      _sortBy = sortBy;
    }
    loadRecipes(reset: true);
  }

  void clearFilters() {
    _showingFavorites = false;
    _browseSectionId = null;
    _selectedCuisine = null;
    _selectedMealType = null;
    _selectedDifficulty = null;
    _selectedDietaryTag = null;
    _caloriesMax = null;
    _proteinMin = null;
    _prepTimeMax = null;
    _minCarbs = null;
    _maxCarbs = null;
    _ingredientsCsv = null;
    _selectedMealChipId = null;
    _sortBy = 'name';
    final searching = _searchQuery != null && _searchQuery!.trim().isNotEmpty;
    if (searching) {
      loadRecipes(reset: true);
    } else {
      _recipes = [];
      _currentPage = 1;
      _hasNextPage = true;
      _totalCount = 0;
      _error = null;
      notifyListeners();
      unawaited(loadSectionRails());
    }
  }

  void _applyBrowseSection(RecipeBrowseSection s) {
    _showingFavorites = false;
    final q = s.query?.trim();
    _searchQuery = q != null && q.isNotEmpty ? q : null;
    _selectedCuisine = null;
    _selectedMealType = s.mealType;
    _selectedDifficulty = null;
    _selectedDietaryTag = s.dietaryTag;
    _caloriesMax = s.caloriesMax;
    _proteinMin = s.proteinMin;
    _prepTimeMax = s.prepTimeMax;
    _minCarbs = s.minCarbs;
    _maxCarbs = s.maxCarbs;
    _ingredientsCsv = null;
    _sortBy = s.sortBy;
    _selectedMealChipId = null;
  }

  RecipeBrowseSection? browseSectionForId(String id) {
    for (final s in RecipeBrowseSection.homeRails) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Loads preview rows for each home rail (parallel API calls).
  Future<void> loadSectionRails({bool force = false}) async {
    if (!force && _sectionRailsInitialized) return;
    if (_sectionRailsLoading) return;
    _showingFavorites = false;
    _sectionRailsLoading = true;
    _sectionRailsError = null;
    notifyListeners();

    try {
      final defs = RecipeBrowseSection.homeRails;
      final lists = await Future.wait(defs.map((d) => _fetchSectionPreview(d)));
      _sectionRecipes.clear();
      for (var i = 0; i < defs.length; i++) {
        _sectionRecipes[defs[i].id] = lists[i];
      }
      _sectionRailsInitialized = true;
    } catch (e) {
      _sectionRailsError = e.toString();
    } finally {
      _sectionRailsLoading = false;
      notifyListeners();
    }
  }

  Future<List<Recipe>> _fetchSectionPreview(RecipeBrowseSection d) async {
    try {
      final r = await _service.searchRecipes(
        query: d.query,
        mealType: d.mealType,
        dietaryTag: d.dietaryTag,
        proteinMin: d.proteinMin,
        caloriesMax: d.caloriesMax,
        prepTimeMax: d.prepTimeMax,
        minCarbs: d.minCarbs,
        maxCarbs: d.maxCarbs,
        sortBy: d.sortBy,
        page: 1,
        perPage: 8,
        customOffset: d.id.hashCode % 280,
      );
      return r.recipes.map(_withFavorite).toList();
    } catch (_) {
      return [];
    }
  }

  void openSectionFullBrowse(String sectionId) {
    _showingFavorites = false;
    final s = browseSectionForId(sectionId);
    if (s == null) return;
    _browseSectionId = sectionId;
    _applyBrowseSection(s);
    loadRecipes(reset: true);
  }

  void closeSectionFullBrowse() {
    _showingFavorites = false;
    _browseSectionId = null;
    _searchQuery = null;
    _minCarbs = null;
    _maxCarbs = null;
    _selectedCuisine = null;
    _selectedMealType = null;
    _selectedDifficulty = null;
    _selectedDietaryTag = null;
    _caloriesMax = null;
    _proteinMin = null;
    _prepTimeMax = null;
    _ingredientsCsv = null;
    _selectedMealChipId = null;
    _sortBy = 'name';
    _recipes = [];
    _hasNextPage = true;
    _currentPage = 1;
    _totalCount = 0;
    _error = null;
    notifyListeners();
    unawaited(loadSectionRails());
  }

  Future<void> loadRecipes({bool reset = false}) async {
    _showingFavorites = false;
    if (reset) {
      _currentPage = 1;
      _hasNextPage = true;
      _recipes = [];
    }

    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.searchRecipes(
        query: _searchQuery,
        cuisine: _selectedCuisine,
        mealType: _selectedMealType,
        difficulty: _selectedDifficulty,
        dietaryTag: _selectedDietaryTag,
        caloriesMax: _caloriesMax,
        proteinMin: _proteinMin,
        prepTimeMax: _prepTimeMax,
        minCarbs: _minCarbs,
        maxCarbs: _maxCarbs,
        ingredients: _ingredientsCsv,
        sortBy: _sortBy,
        page: 1,
        perPage: 10,
      );

      _recipes = result.recipes.map(_withFavorite).toList();
      _currentPage = result.currentPage;
      _hasNextPage = result.hasNextPage;
      _totalCount = result.totalCount;
      _error = null;
    } on RecipeApiException catch (e) {
      _error = e.message;
      _recipes = [];
      _hasNextPage = false;
    } catch (e) {
      _error = e.toString();
      _recipes = [];
      _hasNextPage = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_showingFavorites ||
        _isLoading ||
        _isLoadingMore ||
        !_hasNextPage ||
        _recipes.isEmpty) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final result = await _service.searchRecipes(
        query: _searchQuery,
        cuisine: _selectedCuisine,
        mealType: _selectedMealType,
        difficulty: _selectedDifficulty,
        dietaryTag: _selectedDietaryTag,
        caloriesMax: _caloriesMax,
        proteinMin: _proteinMin,
        prepTimeMax: _prepTimeMax,
        minCarbs: _minCarbs,
        maxCarbs: _maxCarbs,
        ingredients: _ingredientsCsv,
        sortBy: _sortBy,
        page: nextPage,
        perPage: 10,
      );

      final merged = [..._recipes, ...result.recipes.map(_withFavorite)];
      _recipes = merged;
      _currentPage = result.currentPage;
      _hasNextPage = result.hasNextPage;
      _totalCount = result.totalCount;
    } on RecipeApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadRandom({
    String? cuisine,
    String? mealType,
    String? difficulty,
    String? dietaryTag,
  }) async {
    _isLoadingRandom = true;
    _error = null;
    notifyListeners();

    try {
      final r = await _service.getRandomRecipe(
        cuisine: cuisine ?? _selectedCuisine,
        mealType: mealType ?? _selectedMealType,
        difficulty: difficulty ?? _selectedDifficulty,
        dietaryTag: dietaryTag ?? _selectedDietaryTag,
      );
      _randomRecipe = _withFavorite(r);
    } on RecipeApiException catch (e) {
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingRandom = false;
      notifyListeners();
    }
  }

  Future<void> loadRecipeDetail(int id, {Recipe? initial}) async {
    _detailForId = id;
    _detailRecipe = initial != null ? _withFavorite(initial) : null;
    _isLoadingDetail = true;
    _error = null;
    notifyListeners();

    try {
      final r = await _service.getRecipeById(id);
      _detailRecipe = _withFavorite(r);
    } on RecipeApiException catch (e) {
      _error = e.message;
      _detailRecipe ??= initial != null ? _withFavorite(initial) : null;
    } catch (e) {
      _error = e.toString();
      _detailRecipe ??= initial != null ? _withFavorite(initial) : null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Recipe recipe) async {
    final id = recipe.id;
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
      _favoriteRecipes.removeWhere((r) => r.id == id);
    } else {
      _favoriteIds.add(id);
      // We don't have the full details if we just toggled from a list where it wasn't saved.
      // But usually it's already in the list if we can toggle it.
      if (!_favoriteRecipes.any((r) => r.id == id)) {
        _favoriteRecipes.add(recipe.copyWith(isFavorite: true));
      }
    }

    final fav = _favoriteIds.contains(id);
    _recipes = _recipes
        .map((r) => r.id == id ? r.copyWith(isFavorite: fav) : r)
        .toList();
    if (_randomRecipe?.id == id) {
      _randomRecipe = _randomRecipe!.copyWith(isFavorite: fav);
    }
    if (_detailRecipe?.id == id) {
      _detailRecipe = _detailRecipe!.copyWith(isFavorite: fav);
    }

    for (final k in _sectionRecipes.keys.toList()) {
      _sectionRecipes[k] = _sectionRecipes[k]!
          .map((r) => r.id == id ? r.copyWith(isFavorite: fav) : r)
          .toList();
    }

    notifyListeners();
    await _saveFavoriteIds();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _service.close();
    super.dispose();
  }
}
