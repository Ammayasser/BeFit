import '../../core/exercise_media.dart';
import '../curated_workouts.dart';
import '../repositories/exercise_repository.dart';

/// Resolves a cover image URL for workout cards and hero headers.
class WorkoutCoverResolver {
  WorkoutCoverResolver({ExerciseRepository? repository})
      : _repository = repository ?? ExerciseRepository();

  final ExerciseRepository _repository;
  static final Map<String, String?> _cache = {};

  Future<String?> resolve({
    required String workoutRouteId,
    String? muscleGroup,
    String? category,
    List<String>? imageUrls,
  }) async {
    final cacheKey = workoutRouteId;
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];

    if (imageUrls != null && imageUrls.isNotEmpty) {
      _cache[cacheKey] = imageUrls.first;
      return imageUrls.first;
    }

    String? url;

    final curated = curatedWorkoutByRouteId(workoutRouteId);
    if (curated != null) {
      if (curated.imageUrl != null && curated.imageUrl!.isNotEmpty) {
        url = curated.imageUrl;
      } else {
        url = await _firstGifFromCurated(curated.name);
      }
      muscleGroup ??= curated.muscleGroup;
      category ??= curated.category;
    }

    url ??= stockWorkoutCoverUrl(
      name: curated?.name,
      muscleGroup: muscleGroup,
      category: category,
    );
    return null;
    
    // Final absolute fallback to the trainer asset if stock URLs fail or are loading


  }

  Future<String?> resolveFromExerciseNames(List<String> names) async {
    for (final name in names) {
      final url = await _gifForName(name);
      if (url != null) return url;
    }
    return null;
  }

  Future<String?> _firstGifFromCurated(String workoutName) async {
    final presets = curatedWorkoutExerciseSets[workoutName] ?? [];
    for (final e in presets) {
      final url = await _gifForName(e['name'] as String);
      if (url != null) return url;
    }
    return null;
  }

  Future<String?> _gifForName(String name) async {
    final item = await _repository.getExerciseByName(name) ??
        await _repository.findExerciseByFuzzyName(name);
    if (item?.gifUrl != null && item!.gifUrl!.trim().isNotEmpty) {
      return normalizeExerciseMediaUrl(item.gifUrl);
    }
    return null;
  }

  static void clearCache() => _cache.clear();
}
