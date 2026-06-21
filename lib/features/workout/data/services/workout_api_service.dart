// lib/features/workout/data/services/workout_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/workout_models.dart';

/// Single point of contact for https://workout.runasp.net
/// All other code talks to this service, never to the URL directly.
class WorkoutApiService {
  final http.Client _client;

  /// In-memory cache populated on first [fetchAll] call.
  static List<dynamic>? _cachedExercises;

  WorkoutApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  // ── Core fetch helpers ──────────────────────────────────────────────────────

  List<dynamic>? _extractExerciseList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['value', 'data', 'exercises', 'results', 'items']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return null;
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Fetches and caches ALL exercises. Returns the full cached list.
  Future<List<Map<String, dynamic>>> fetchAll() async {
    try {
      if (_cachedExercises == null) {
        final url = Uri.parse('${ApiConstants.exerciseApiBase}/api/Exercises');
        debugPrint('[WorkoutApiService] Fetching full exercise list...');
        final response = await _client
            .get(url, headers: _headers)
            .timeout(const Duration(seconds: 20));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = _extractExerciseList(decoded);
          if (list != null) {
            _cachedExercises = list;
          } else {
            debugPrint('[WorkoutApiService] Unexpected payload shape: ${decoded.runtimeType}');
            return [];
          }
        } else {
          debugPrint('[WorkoutApiService] fetchAll error: status ${response.statusCode}');
          return [];
        }
      }
      return _cachedExercises!.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[WorkoutApiService] fetchAll exception: $e');
      return [];
    }
  }

  /// Fetches a single exercise by ID.
  Future<Map<String, dynamic>?> fetchById(String id) async {
    try {
      final url = Uri.parse('${ApiConstants.exerciseApiBase}/api/Exercises/$id');
      debugPrint('[WorkoutApiService] Fetching exercise by id: $id');
      final response = await _client
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return null;
    } catch (e) {
      debugPrint('[WorkoutApiService] fetchById exception: $e');
      return null;
    }
  }

  /// Returns total exercise count by fetching a small batch if cache is empty.
  Future<int?> fetchExerciseTotal() async {
    try {
      // We don't know the total without fetching.
      // Most .NET APIs return total in @odata.count or similar,
      // but if not, we fetch all.
      if (_cachedExercises == null) {
        final url = Uri.parse('${ApiConstants.exerciseApiBase}/api/Exercises');
        final response = await _client.get(url, headers: _headers);
        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final list = _extractExerciseList(decoded);
          if (list != null) {
            _cachedExercises = list;
            return list.length;
          }
        }
      }
      return _cachedExercises?.length;
    } catch (e) {
      debugPrint('[WorkoutApiService] fetchExerciseTotal exception: $e');
      return null;
    }
  }

  /// Returns a paginated slice from the cache. Falls back to fetching if cache
  /// is empty.
  Future<List<dynamic>> fetchExercisesBatch(int limit, int offset) async {
    try {
      // Only fetch from network if cache is empty
      if (_cachedExercises == null) {
        await fetchAll(); 
      }

      if (_cachedExercises == null || _cachedExercises!.isEmpty) return [];

      final total = _cachedExercises!.length;
      if (offset >= total) return [];
      
      final end = (offset + limit).clamp(0, total);
      return _cachedExercises!.sublist(offset, end);
    } catch (e) {
      debugPrint('[WorkoutApiService] fetchExercisesBatch exception: $e');
      return [];
    }
  }

  /// Searches exercises by name.
  Future<List<dynamic>> searchExercises(String query) async {
    try {
      final url = Uri.parse(
          '${ApiConstants.exerciseApiBase}/api/Exercises/search?name=${Uri.encodeComponent(query)}');
      debugPrint('[WorkoutApiService] Searching: $query');
      final response = await _client
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractExerciseList(decoded);
        if (list != null) return list;
      }

      // Fallback: filter cache
      if (_cachedExercises != null) {
        final q = query.toLowerCase();
        return _cachedExercises!
            .where((e) => (e['name']?.toString().toLowerCase() ?? '').contains(q))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[WorkoutApiService] searchExercises exception: $e');
      // Fallback to cache
      if (_cachedExercises != null) {
        final q = query.toLowerCase();
        return _cachedExercises!
            .where((e) => (e['name']?.toString().toLowerCase() ?? '').contains(q))
            .toList();
      }
      return [];
    }
  }

  /// Filters exercises by muscle, equipment, and/or level.
  Future<List<dynamic>> filterExercises({
    String? muscle,
    String? equipment,
    String? level,
  }) async {
    try {
      final queryParams = <String>[];
      if (muscle != null && muscle.isNotEmpty) {
        queryParams.add('muscle=${Uri.encodeComponent(muscle)}');
      }
      if (equipment != null && equipment.isNotEmpty) {
        queryParams.add('equipment=${Uri.encodeComponent(equipment)}');
      }
      if (level != null && level.isNotEmpty) {
        queryParams.add('level=${Uri.encodeComponent(level)}');
      }

      final queryString =
          queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final url = Uri.parse(
          '${ApiConstants.exerciseApiBase}/api/Exercises$queryString');

      debugPrint('[WorkoutApiService] Filtering: $queryString');
      final response = await _client
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = _extractExerciseList(decoded);
        if (list != null) return list;
      }

      // Fallback: filter cache
      if (_cachedExercises != null) {
        return _cachedExercises!.where((e) {
          final item = e as Map<String, dynamic>;
          if (muscle != null && muscle.isNotEmpty) {
            final primaries = item['primaryMuscles'] as List?;
            if (primaries == null ||
                !primaries
                    .any((m) => m.toString().toLowerCase() == muscle)) {
              return false;
            }
          }
          if (equipment != null && equipment.isNotEmpty) {
            if ((item['equipment']?.toString().toLowerCase() ?? '') !=
                equipment) {
              return false;
            }
          }
          if (level != null && level.isNotEmpty) {
            if ((item['level']?.toString().toLowerCase() ?? '') != level) {
              return false;
            }
          }
          return true;
        }).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[WorkoutApiService] filterExercises exception: $e');
      return [];
    }
  }

  /// POSTs a finished session's summary to the BeFit progress API.
  Future<Map<String, dynamic>> postWorkoutProgress(
      String token, WorkoutSession session) async {
    try {
      final url = Uri.parse(ApiConstants.progress);
      debugPrint('[WorkoutApiService] Posting progress to $url');
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'workoutName': session.workoutName,
              'durationSeconds': session.duration.inSeconds,
              'totalSets': session.totalSets,
              'totalReps': session.totalReps,
              'totalVolume': session.totalVolume,
              'completedAt':
                  (session.finishedAt ?? DateTime.now()).toIso8601String(),
              'notes': session.sessionNote ?? '',
              'rating': session.moodRating ?? 3,
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('[WorkoutApiService] post progress status: ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true};
      }
      return {
        'success': false,
        'message':
            'Failed to sync progress with server (${response.statusCode})',
      };
    } catch (e) {
      debugPrint('[WorkoutApiService] postWorkoutProgress exception: $e');
      return {
        'success': false,
        'message': 'Network error syncing workout progress.',
      };
    }
  }

  /// Clears the in-memory cache (useful for testing or forced refresh).
  static void clearCache() {
    _cachedExercises = null;
  }
}
