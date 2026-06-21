import 'package:flutter/foundation.dart';
import '../../data/models/fitbod_workout_model.dart';
import '../../data/repositories/fitbod_workout_repository.dart';
import '../../data/repositories/exercise_repository.dart';
import '../../data/models/workout_models.dart';

class WorkoutSection {
  final String title;
  final List<FitbodWorkout> workouts;
  WorkoutSection(this.title, this.workouts);
}

class FitbodWorkoutProvider extends ChangeNotifier {
  final FitbodWorkoutRepository _workoutRepository;
  final ExerciseRepository _exerciseRepository;

  FitbodWorkoutProvider({
    FitbodWorkoutRepository? workoutRepository,
    ExerciseRepository? exerciseRepository,
  }) : _workoutRepository = workoutRepository ?? FitbodWorkoutRepository(),
       _exerciseRepository = exerciseRepository ?? ExerciseRepository();

  List<String> _categories = [];
  List<FitbodWorkout> _workouts = [];
  List<FitbodWorkout> _featuredWorkouts = [];

  // Dynamic Gender Sections
  List<WorkoutSection> _genderSections = [];

  // Personalized & Shared Lists
  List<FitbodWorkout> _experienceWorkouts = [];
  List<FitbodWorkout> _goalWorkouts = [];
  List<FitbodWorkout> _quickWorkouts = [];

  // ─── Internal cache ──────────────────────────────────────────────────────────
  // The full dataset for the current gender, loaded once.
  List<FitbodWorkout> _allWorkouts = [];
  String _loadedForGender = '';

  // Speed optimization: Pre-indexed lookups
  final Map<String, List<FitbodWorkout>> _workoutsByCategory = {};
  final Map<String, List<FitbodWorkout>> _workoutsByMuscle = {};

  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  List<String> get categories => _categories;
  List<FitbodWorkout> get workouts => _workouts;
  List<FitbodWorkout> get featuredWorkouts => _featuredWorkouts;

  // Section Getters
  List<WorkoutSection> get genderSections => _genderSections;

  // Shared & Personalized Getters
  List<FitbodWorkout> get experienceWorkouts => _experienceWorkouts;
  List<FitbodWorkout> get goalWorkouts => _goalWorkouts;
  List<FitbodWorkout> get quickWorkouts => _quickWorkouts;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get loadedForGender => _loadedForGender;

  Future<void> loadCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _categories = await _workoutRepository.getCategories();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFeatured() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // If we have data in memory, use it for featured (faster)
      if (_allWorkouts.isNotEmpty) {
        _featuredWorkouts = _take(10, _allWorkouts..shuffle());
      } else {
        _featuredWorkouts = await _workoutRepository.getFeaturedWorkouts(10);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadByCategory(String category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final cat = category.toLowerCase().trim();
      // Use memory cache if available for instant result
      if (_workoutsByCategory.containsKey(cat)) {
        _workouts = _workoutsByCategory[cat]!;
      } else {
        _workouts = await _workoutRepository.getWorkoutsByCategory(category);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> search(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (query.isEmpty) {
        _workouts = [];
      } else {
        final q = query.toLowerCase();
        // Memory search for speed
        if (_allWorkouts.isNotEmpty) {
          _workouts = _allWorkouts
              .where(
                (w) =>
                    w.name.toLowerCase().contains(q) ||
                    w.category.toLowerCase().contains(q) ||
                    w.primaryMuscles.any((m) => m.toLowerCase().contains(q)),
              )
              .toList();
        } else {
          _workouts = await _workoutRepository.searchWorkouts(query);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    String? category,
    String? difficulty,
    String? goal,
    String? muscle,
    String? gender,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For complex filtering, we still hit the DB to ensure full accuracy
      // though we could optimize this later if needed.
      _workouts = await _workoutRepository.filterWorkouts(
        category: category,
        difficulty: difficulty,
        goal: goal,
        muscle: muscle,
        gender: gender,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Public entry point ───────────────────────────────────────────────────────

  void initForUser(
    String uid, {
    String? gender,
    String? experience,
    String? goal,
  }) {
    // GUARD: if gender is not provided, we cannot load the correct sections.
    // AppInitManager must pass gender after loadProfile() completes.
    // If gender is null here, WorkoutScreen._loadData will handle it when the
    // profile is ready and the screen is mounted.
    if (gender == null) {
      debugPrint(
        '[FitbodProvider] initForUser called without gender — skipping. '
        'WorkoutScreen will load on mount.',
      );
      return;
    }

    final g = gender.toLowerCase().trim();

    // Skip if already loaded for this gender
    if (_isLoading || (_isInitialized && _loadedForGender == g)) return;

    _isInitialized = false;
    _loadAll(
      gender: g,
      experience: (experience ?? 'intermediate').toLowerCase().trim(),
      goal: goal ?? '',
    );
  }

  // ─── Core loader: 2 DB queries, then pure Dart slicing ────────────────────────

  Future<void> _loadAll({
    required String gender,
    required String experience,
    required String goal,
    bool forceRefresh = false,
  }) async {
    final genderNorm = gender.toLowerCase().trim();
    if (_isLoading) return;
    if (_isInitialized && !forceRefresh && _loadedForGender == genderNorm)
      return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Fetch entire dataset in one optimized call
      _allWorkouts = await _workoutRepository.loadAllForGender(genderNorm);
      _loadedForGender = genderNorm;

      // 2. Pre-index for O(1) section slicing
      _workoutsByCategory.clear();
      _workoutsByMuscle.clear();
      for (final w in _allWorkouts) {
        final cat = (w.category).toLowerCase().trim();
        _workoutsByCategory.putIfAbsent(cat, () => []).add(w);

        for (final m in w.primaryMuscles) {
          final muscle = m.toLowerCase().trim();
          _workoutsByMuscle.putIfAbsent(muscle, () => []).add(w);
        }
      }

      debugPrint(
        '[FitbodProvider] Loaded & Indexed ${_allWorkouts.length} workouts for $genderNorm',
      );
      debugPrint(
        '[FitbodProvider] Categories in DB: ${_workoutsByCategory.keys.toList()}',
      );

      // 3. Slice sections in-memory (instant)
      _sliceIntoSections(
        gender: genderNorm,
        experience: experience,
        goal: goal,
      );

      _isInitialized = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('[FitbodProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Pure Dart slicing — instant lookups ──────────────────────────────────────

  void _sliceIntoSections({
    required String gender,
    required String experience,
    required String goal,
  }) {
    final genderNorm = gender.toLowerCase().trim();
    final isMale = genderNorm == 'male' || genderNorm == 'men';
    final all = _allWorkouts;

    // Helper: Flexible search across names, categories, and muscles
    List<FitbodWorkout> findWorkouts(
      List<String> keywords, {
      bool strictMuscle = false,
    }) {
      if (all.isEmpty) return [];

      final results = all.where((w) {
        final cat = (w.category).toLowerCase();
        final muscleList = (w.primaryMuscles)
            .map((m) => m.toString().toLowerCase())
            .toList();
        final musclesJoined = muscleList.join(' ');
        final name = (w.name).toLowerCase();

        // If strictMuscle is true, at least one keyword MUST match a primary muscle exactly
        if (strictMuscle) {
          final hasMuscleMatch = keywords.any(
            (k) => muscleList.any((m) => m == k.toLowerCase()),
          );
          if (!hasMuscleMatch) return false;
        }

        final searchStr = '$cat $musclesJoined $name';
        return keywords.any((k) => searchStr.contains(k.toLowerCase()));
      }).toList();

      return _take(12, _dedup(results));
    }

    _genderSections.clear();

    if (isMale) {
      _genderSections = [
        WorkoutSection(
          '🔥 Push Day',
          findWorkouts([
            'push',
            'chest',
            'shoulder',
            'tricep',
          ], strictMuscle: true),
        ),
        WorkoutSection(
          '💪 Pull Day',
          findWorkouts([
            'pull',
            'back',
            'bicep',
            'trap',
            'lats',
          ], strictMuscle: true),
        ),
        WorkoutSection(
          '🦵 Leg Day',
          findWorkouts([
            'leg',
            'quad',
            'hamstring',
            'calf',
            'glute',
          ], strictMuscle: true),
        ),
        WorkoutSection(
          '⚡ Full Body',
          findWorkouts(['full body', 'general', 'circuit']),
        ),
        WorkoutSection(
          '🏋️ Upper Body',
          findWorkouts(['upper body', 'chest', 'back', 'shoulder', 'arm']),
        ),
      ];
    } else {
      _genderSections = [
        WorkoutSection(
          '🍑 Glute Builder',
          findWorkouts([
            'glute',
            'booty',
            'butt',
            'abductor',
            'adductor',
          ], strictMuscle: true),
        ),
        WorkoutSection(
          '🔥 Lower Body Sculpt',
          findWorkouts([
            'leg',
            'lower body',
            'thigh',
            'quad',
            'hamstring',
          ], strictMuscle: true),
        ),
        WorkoutSection(
          '🧘 Core & Pilates',
          findWorkouts(['core', 'abs', 'pilates', 'yoga', 'abdominals']),
        ),
        WorkoutSection(
          '💪 Upper Body Toning',
          findWorkouts(['upper body', 'arm', 'back', 'shoulder', 'toning']),
        ),
        WorkoutSection(
          '⚡ Full Body Burn',
          findWorkouts(['full body', 'cardio', 'general', 'hiit', 'burn']),
        ),
        WorkoutSection(
          '🌸 Home Workout',
          findWorkouts(['home', 'no equipment', 'bodyweight']),
        ),
      ];
    }

    // DIAGNOSTIC LOGGING
    for (var s in _genderSections) {
      debugPrint(
        '[FitbodProvider] Section "${s.title}" has ${s.workouts.length} workouts',
      );
    }

    // ENSURE VISIBILITY: If specific sections are empty, add a fallback
    if (_genderSections.every((s) => s.workouts.isEmpty)) {
      debugPrint(
        '[FitbodProvider] All sections empty - adding fallback "All Workouts" (Total available: ${all.length})',
      );
      if (all.isNotEmpty) {
        _genderSections = [
          WorkoutSection(
            'Recommended Workouts',
            _take(15, List.from(all)..shuffle()),
          ),
        ];
      }
    }

    // Experience section
    String normalizedExp = experience.toLowerCase().trim();
    if (normalizedExp == 'novice') normalizedExp = 'beginner';
    if (normalizedExp == 'expert') normalizedExp = 'advanced';

    final d = normalizedExp.toLowerCase();
    _experienceWorkouts = _take(
      15,
      _dedup(all.where((w) => w.difficulty.toLowerCase() == d).toList()),
    );
    if (_experienceWorkouts.isEmpty) _experienceWorkouts = _take(15, all);

    // Goal section
    final goalLower = goal.toLowerCase().trim();
    String fitnessGoal = '';
    if (goalLower.contains('muscle') || goalLower.contains('build')) {
      fitnessGoal = 'build muscle';
    } else if (goalLower.contains('weight') ||
        goalLower.contains('fat') ||
        goalLower.contains('lose')) {
      fitnessGoal = 'lean';
    } else if (goalLower.contains('strength') || goalLower.contains('power')) {
      fitnessGoal = 'strength';
    }

    if (fitnessGoal.isNotEmpty) {
      final target = fitnessGoal.toLowerCase();
      _goalWorkouts = _take(
        15,
        _dedup(
          all.where((w) => w.goal.toLowerCase().contains(target)).toList(),
        ),
      );
    } else {
      _goalWorkouts = _take(15, all);
    }
    if (_goalWorkouts.isEmpty) _goalWorkouts = _take(15, all);

    _quickWorkouts = _take(
      10,
      _dedup(
        all.where((w) => (w.exercises.length * 7).clamp(20, 60) <= 30).toList(),
      ),
    );
  }

  // ─── Public refresh entry point ───────────────────────────────────────────────

  Future<void> loadCustomSections(
    String gender, {
    bool forceRefresh = false,
  }) async {
    final g = gender.toLowerCase().trim();
    if (!forceRefresh && _loadedForGender == g && _allWorkouts.isNotEmpty) {
      _sliceIntoSections(
        gender: g,
        experience: _lastExperience,
        goal: _lastGoal,
      );
      notifyListeners();
      return;
    }
    await _loadAll(
      gender: g,
      experience: _lastExperience,
      goal: _lastGoal,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> loadPersonalizedSections({
    required String gender,
    required String experience,
    required String goal,
  }) async {
    _lastExperience = experience;
    _lastGoal = goal;
    final g = gender.toLowerCase().trim();
    if (_allWorkouts.isNotEmpty && _loadedForGender == g) {
      _sliceIntoSections(gender: g, experience: experience, goal: goal);
      notifyListeners();
      return;
    }
    await _loadAll(gender: g, experience: experience, goal: goal);
  }

  String _lastExperience = 'intermediate';
  String _lastGoal = '';

  List<FitbodWorkout> _dedup(List<FitbodWorkout> list) {
    final seen = <String>{};
    return list.where((w) => seen.add(w.id)).toList();
  }

  List<FitbodWorkout> _take(int n, List<FitbodWorkout> list) {
    if (list.length <= n) return list;
    return list.sublist(0, n);
  }

  Future<List<ExerciseLibraryItem>> getExercisesForWorkout(
    FitbodWorkout workout,
  ) async {
    final ids = workout.exercises.map((e) => e.exerciseId).toList();
    return await _exerciseRepository.getExercisesByIds(ids);
  }

  void reset() {
    _allWorkouts = [];
    _loadedForGender = '';
    _workoutsByCategory.clear();
    _workoutsByMuscle.clear();
    _isInitialized = false;
    _lastExperience = 'intermediate';
    _lastGoal = '';

    _genderSections = [];

    _experienceWorkouts = [];
    _goalWorkouts = [];
    _quickWorkouts = [];
    _error = null;
    notifyListeners();
  }
}
