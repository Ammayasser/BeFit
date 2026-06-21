// lib/core/services/ai_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';
import '../../features/workout/data/repositories/exercise_repository.dart';
import '../../features/workout/data/models/workout_models.dart';
import '../../features/workout/data/services/workout_api_service.dart';
import '../database/database_helper.dart';

class AIService {
  static const String _apiHost = 'https://generativelanguage.googleapis.com';
  static const String _apiVersion = 'v1beta';
  static const String _currentModel = 'gemini-2.5-flash';

  final ExerciseRepository _exerciseRepository = ExerciseRepository();

  /// Safely converts dynamic values (String or num) to double.
  double _asDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) {
      return double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  /// Tries to find a matching exercise in the local library by name, or falls back to a related database exercise.
  Future<ExerciseLibraryItem?> findLocalMatch(String aiName) async {
    // 1. Try exact match
    var match = await _exerciseRepository.getExerciseByName(aiName);
    if (match != null) return match;

    // 2. Try fuzzy match
    match = await _exerciseRepository.findExerciseByFuzzyName(aiName);
    if (match != null) return match;

    // 3. Clean and try again
    final cleanName = aiName.replaceAll(RegExp(r'(Dumbbell|Barbell|Machine|Cable|Weighted|Bodyweight|assisted|seated|standing|inclined|declined)', caseSensitive: false), '').trim();
    if (cleanName.length > 3) {
      match = await _exerciseRepository.findExerciseByFuzzyName(cleanName);
      if (match != null) return match;
    }

    // 4. Try matching normalized names of all exercises in the library
    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> allExercises = await db.query(
        'exercises_library', 
        columns: ['id', 'name', 'target', 'body_part', 'gif_url', 'secondary_muscles', 'equipment', 'difficulty', 'category', 'mechanic', 'force_type', 'met', 'calories_per_min', 'description', 'instructions', 'images']
      );
      
      final normalizedAiName = aiName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
      
      for (final ex in allExercises) {
        final name = ex['name']?.toString() ?? '';
        final normalizedName = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '').trim();
        if (normalizedName == normalizedAiName || normalizedName.contains(normalizedAiName) || normalizedAiName.contains(normalizedName)) {
          return ExerciseLibraryItem.fromJson(ex);
        }
      }

      // 5. Ultimate Fallback: match by muscle keyword if found in aiName
      final lowerAiName = aiName.toLowerCase();
      String? targetMuscle;
      if (lowerAiName.contains('chest') || lowerAiName.contains('pec')) {
        targetMuscle = 'chest';
      } else if (lowerAiName.contains('back') || lowerAiName.contains('lat') || lowerAiName.contains('row') || lowerAiName.contains('pull')) {
        targetMuscle = 'back';
      } else if (lowerAiName.contains('bicep') || lowerAiName.contains('curl')) {
        targetMuscle = 'biceps';
      } else if (lowerAiName.contains('tricep') || lowerAiName.contains('dip')) {
        targetMuscle = 'triceps';
      } else if (lowerAiName.contains('shoulder') || lowerAiName.contains('deltoid') || lowerAiName.contains('raise')) {
        targetMuscle = 'shoulders';
      } else if (lowerAiName.contains('squat') || lowerAiName.contains('leg') || lowerAiName.contains('quad') || lowerAiName.contains('hamstring') || lowerAiName.contains('lunge')) {
        targetMuscle = 'quadriceps';
      } else if (lowerAiName.contains('calf') || lowerAiName.contains('calve')) {
        targetMuscle = 'calves';
      } else if (lowerAiName.contains('abs') || lowerAiName.contains('crunch') || lowerAiName.contains('core') || lowerAiName.contains('plank')) {
        targetMuscle = 'abdominals';
      }

      if (targetMuscle != null) {
        final results = await db.query(
          'exercises_library',
          where: 'target LIKE ? OR body_part LIKE ?',
          whereArgs: ['%$targetMuscle%', '%$targetMuscle%'],
          limit: 1,
        );
        if (results.isNotEmpty) {
          return ExerciseLibraryItem.fromJson(results.first);
        }
      }

      // 6. Last resort: just return the first exercise in the library so it's not null and has a valid ID/image
      if (allExercises.isNotEmpty) {
        return ExerciseLibraryItem.fromJson(allExercises.first);
      }
    } catch (e) {
      print('findLocalMatch database fallback exception: $e');
    }

    return null;
  }

  Future<Map<String, dynamic>?> generateWorkoutPlan({
    required String goal,
    required String experience,
    required String location,
    required int daysPerWeek,
    required int durationMinutes,
  }) async {
    // 1. Fetch available exercises from SQLite based on constraints
    List<Map<String, String>> availableExs = [];
    try {
      availableExs = await _exerciseRepository.getAvailableExercisesForAI(location);
    } catch (e) {
      print('AIService generateWorkoutPlan query error: $e');
    }

    // 2. Fallback to API if DB is not synced yet
    if (availableExs.isEmpty) {
      try {
        final apiService = WorkoutApiService();
        final apiExs = await apiService.fetchAll();
        availableExs = apiExs.map((e) => {
          'name': e['name']?.toString() ?? '',
          'target': (e['primaryMuscles'] as List?)?.firstOrNull?.toString() ?? '',
          'equipment': e['equipment']?.toString() ?? '',
        }).toList();
      } catch (_) {}
    }

    // 3. Fallback to hardcoded list if both DB and API call fail / empty
    if (availableExs.isEmpty) {
      final loc = location.toLowerCase();
      final isHome = loc.contains('home') || loc.contains('no equipment') || loc == 'home';
      final isOutdoor = loc.contains('outdoor') || loc.contains('minimal') || loc == 'outdoor';
      
      availableExs = fallbackExercises.where((e) {
        final eq = (e['equipment'] ?? '').toLowerCase();
        if (isHome) {
          return eq == 'body weight' || eq == 'none' || eq == '';
        } else if (isOutdoor) {
          return eq == 'body weight' || eq == 'none' || eq == 'bands' || eq == '';
        }
        return true;
      }).toList();
    }

    final exerciseListStr = availableExs.map((e) => "- ${e['name']} (${e['target']}, equipment: ${e['equipment']})").join('\n');

    final prompt = '''
      You are a Master Fitness Trainer with 20 years of experience in exercise science and professional bodybuilding/athletic coaching. 
      Generate a professional, highly-effective 7-day workout plan for a user with these specs:
      - Goal: $goal
      - Experience: $experience (Scale difficulty and volume accordingly)
      - Location: $location (Prioritize appropriate equipment)
      - Training Frequency: $daysPerWeek days per week
      - Session Duration: $durationMinutes minutes

      SCIENTIFIC PROGRAMMING RULES:
      1. Use professional training splits based on frequency:
         - 3 days: Full Body
         - 4 days: Upper / Lower split
         - 5-6 days: Push / Pull / Legs split
      2. DO NOT pair random exercises. Each day must have a clear muscle group focus. 
      3. For each workout day, follow this structure: 
         - Start with 1-2 heavy Compound movements (e.g., Squats, Bench, Rows).
         - Follow with 2-3 Accessory movements targeting the same or supporting muscle groups.
         - Finish with 1-2 Isolation or Core movements.
      4. DO NOT put Bicep Curls on a Chest/Push day unless it's a specific "Arms" day in a high-frequency split.
      5. Ensure appropriate rest days are marked (is_rest_day: true) to fill exactly 7 days.

      CRITICAL RULE:
      You MUST choose exercises ONLY from the list of available exercises provided below. Do not invent any new exercise names.

      Allowed Exercise List:
      $exerciseListStr

      Return a JSON object:
      {
        "plan_name": "Professional Title (e.g., Elite Strength PPL)",
        "description": "Scientific explanation of why this plan works for the goal",
        "routines": [
          {
            "day_index": 1-7,
            "name": "Day Title (e.g., Heavy Push & Triceps)",
            "is_rest_day": boolean,
            "exercises": [
              {
                "name": "string",
                "sets": number,
                "reps": "string (e.g., '8-10' or '5x5')",
                "notes": "Pro coaching cue (e.g., 'Focus on the stretch at the bottom')"
              }
            ]
          }
        ]
      }
      Return ONLY raw JSON.
    ''';

    final keys = ApiKeys.geminiKeys;
    int formatErrors = 0;

    for (int keyIndex = 0; keyIndex < keys.length; keyIndex++) {
      final apiKey = keys[keyIndex];
      final url = Uri.parse('$_apiHost/$_apiVersion/models/$_currentModel:generateContent?key=$apiKey');
      
      int attempt = 0;
      const int maxAttempts = 3;

      print('AIService: Attempting generateWorkoutPlan with API key ${keyIndex + 1}/${keys.length}...');

      while (attempt < maxAttempts) {
        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [{"parts": [{"text": prompt}]}],
              "generationConfig": {
                "temperature": 0.7,
                "responseMimeType": "application/json",
              }
            }),
          ).timeout(const Duration(seconds: 45));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['candidates'] != null && data['candidates'].isNotEmpty) {
              final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
              final result = extractJson(text);
              if (result != null) {
                return result;
              }
            }
            formatErrors++;
            if (formatErrors > 5) {
              print('AIService: Too many JSON structure parsing errors. Aborting.');
              return null;
            }
            print('AIService: Invalid structure in candidate response. Retrying (attempt $formatErrors/5)...');
            await Future.delayed(const Duration(seconds: 3));
            continue;
          }

          attempt++;
          print('AIService Error: ${response.statusCode} (attempt $attempt/$maxAttempts with key ${keyIndex + 1})');
          if (attempt < maxAttempts) {
            print('AIService: Retrying in 5 seconds...');
            await Future.delayed(const Duration(seconds: 5));
          }
        } catch (e) {
          attempt++;
          print('AIService Exception: $e (attempt $attempt/$maxAttempts with key ${keyIndex + 1})');
          if (attempt < maxAttempts) {
            print('AIService: Retrying in 5 seconds...');
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      }
      print('AIService: API key ${keyIndex + 1} failed after $maxAttempts attempts. Switching to next key...');
    }

    print('AIService: All API keys failed. Returning professional fallback workout plan.');
    return fallbackWorkoutPlanRaw;
  }

  Map<String, dynamic>? extractJson(String text) {
    try {
      final decoded = jsonDecode(text.trim());
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is List && decoded.isNotEmpty && decoded[0] is Map) return {"routines": decoded};
    } catch (_) {
      try {
        final RegExp jsonRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
        final match = jsonRegex.firstMatch(text);
        if (match != null) {
          final decoded = jsonDecode(match.group(1)!);
          if (decoded is Map<String, dynamic>) return decoded;
        }
        final RegExp fallbackRegex = RegExp(r'(\{[\s\S]*\})');
        final fallbackMatch = fallbackRegex.firstMatch(text);
        if (fallbackMatch != null) {
          final decoded = jsonDecode(fallbackMatch.group(1)!);
          if (decoded is Map<String, dynamic>) return decoded;
        }
      } catch (_) {}
    }
    return null;
  }

  // High-fidelity meal analysis
  Future<Map<String, dynamic>?> analyzeMealImage(String base64Image) async {
    const prompt = '''
      Analyze the meal in this image. Provide a highly accurate nutritional breakdown per 100g of the food shown.
      Also estimate the total weight of the portion in the image in grams.

      Return a JSON object with these EXACT keys:
      {
        "food_name": "string",
        "calories_per_100g": number,
        "protein_per_100g": number,
        "carbs_per_100g": number,
        "fat_per_100g": number,
        "serving_grams": number
      }

      Return ONLY raw JSON. If the image does not contain identifiable food, return {"error": "not_a_meal"}.
    ''';

    final keys = ApiKeys.geminiKeys;

    for (int keyIndex = 0; keyIndex < keys.length; keyIndex++) {
      final apiKey = keys[keyIndex];
      final url = Uri.parse('$_apiHost/$_apiVersion/models/$_currentModel:generateContent?key=$apiKey');
      
      int attempt = 0;
      const int maxAttempts = 3;

      print('AIService: Attempting analyzeMealImage with API key ${keyIndex + 1}/${keys.length}...');

      while (attempt < maxAttempts) {
        try {
          final response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                    {
                      "inline_data": {
                        "mime_type": "image/jpeg",
                        "data": base64Image
                      }
                    }
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.2,
                "responseMimeType": "application/json"
              }
            }),
          ).timeout(const Duration(seconds: 45));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['candidates'] != null && data['candidates'].isNotEmpty) {
              final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
              final jsonMap = extractJson(text);
              if (jsonMap != null) {
                return {
                  "food_name": jsonMap['food_name'] ?? 'Analyzed Meal',
                  "calories_per_100g": _asDouble(jsonMap['calories_per_100g']),
                  "protein_per_100g": _asDouble(jsonMap['protein_per_100g']),
                  "carbs_per_100g": _asDouble(jsonMap['carbs_per_100g']),
                  "fat_per_100g": _asDouble(jsonMap['fat_per_100g']),
                  "serving_grams": _asDouble(jsonMap['serving_grams'] ?? 250),
                  "error": jsonMap['error'],
                };
              }
              return {"error": "parse_error", "message": "Could not extract JSON from AI response"};
            }
            return {"error": "empty_response", "message": "AI returned no candidates"};
          }
          
          attempt++;
          print('AIService analyzeMealImage: API error ${response.statusCode} (attempt $attempt/$maxAttempts with key ${keyIndex + 1})');
          if (attempt < maxAttempts) {
            await Future.delayed(const Duration(seconds: 5));
          }
        } catch (e) {
          attempt++;
          print('AIService analyzeMealImage: Exception $e (attempt $attempt/$maxAttempts with key ${keyIndex + 1})');
          if (attempt < maxAttempts) {
            await Future.delayed(const Duration(seconds: 5));
          }
        }
      }
      print('AIService: Key ${keyIndex + 1} failed for analyzeMealImage. Trying next key...');
    }

    return {
      "error": "all_keys_failed",
      "message": "Failed to analyze meal image after trying all API keys."
    };
  }

  static const Map<String, dynamic> fallbackWorkoutPlanRaw = {
    "plan_name": "Ultimate Strength & Conditioning Plan",
    "description": "A comprehensive weekly plan focusing on compound lifts, core strength, and muscle recovery.",
    "routines": [
      {
        "day_index": 1,
        "name": "Day 1: Upper Body Power Focus",
        "is_rest_day": false,
        "exercises": [
          {"name": "Barbell Bench Press", "sets": 4, "reps": "8-10", "notes": "Control the descent, explode up."},
          {"name": "Lat Pulldown", "sets": 4, "reps": "10-12", "notes": "Squeeze shoulder blades at the bottom."},
          {"name": "Dumbbell Shoulder Press", "sets": 3, "reps": "10-12", "notes": "Keep core tight, press overhead."},
          {"name": "Dumbbell Bicep Curl", "sets": 3, "reps": "12", "notes": "Squeeze biceps at the top."},
          {"name": "Triceps Pushdown (Cable)", "sets": 3, "reps": "12", "notes": "Keep elbows tucked to the sides."}
        ]
      },
      {
        "day_index": 2,
        "name": "Day 2: Lower Body Strength Focus",
        "is_rest_day": false,
        "exercises": [
          {"name": "Barbell Squat", "sets": 4, "reps": "8-10", "notes": "Squat to parallel, drive through heels."},
          {"name": "Seated Leg Curl", "sets": 3, "reps": "12", "notes": "Squeeze hamstrings at peak contraction."},
          {"name": "Dumbbell Goblet Squat", "sets": 3, "reps": "12", "notes": "Keep chest up, hold dumbbell close."},
          {"name": "Calf Raises (Standing)", "sets": 4, "reps": "15", "notes": "Hold stretch for 1 second at bottom."},
          {"name": "Plank", "sets": 3, "reps": "60 seconds", "notes": "Engage core, keep hips level."}
        ]
      },
      {
        "day_index": 3,
        "name": "Day 3: Rest & Active Recovery",
        "is_rest_day": true,
        "exercises": []
      },
      {
        "day_index": 4,
        "name": "Day 4: Push Day Conditioning",
        "is_rest_day": false,
        "exercises": [
          {"name": "Dumbbell Bench Press", "sets": 4, "reps": "10", "notes": "Control the movement on each rep."},
          {"name": "Military Press", "sets": 3, "reps": "8-10", "notes": "Avoid leaning back, press cleanly."},
          {"name": "Dumbbell Flyes", "sets": 3, "reps": "12", "notes": "Focus on the chest stretch."},
          {"name": "Lateral Raises (Dumbbell)", "sets": 4, "reps": "15", "notes": "Lead with elbows, raise to side."},
          {"name": "Bench Dips", "sets": 3, "reps": "12-15", "notes": "Keep back close to bench."}
        ]
      },
      {
        "day_index": 5,
        "name": "Day 5: Pull Day & Core",
        "is_rest_day": false,
        "exercises": [
          {"name": "Pullups", "sets": 4, "reps": "8-12", "notes": "Control the negative down phase."},
          {"name": "Barbell Row", "sets": 4, "reps": "8-10", "notes": "Keep spine neutral, pull to belly button."},
          {"name": "Hammer Curls", "sets": 3, "reps": "12", "notes": "Keep wrists neutral, palms face in."},
          {"name": "Russian Twist", "sets": 3, "reps": "20", "notes": "Rotate torso, touch floor on sides."},
          {"name": "Crunches", "sets": 3, "reps": "15", "notes": "Exhale, squeeze upper abs."}
        ]
      },
      {
        "day_index": 6,
        "name": "Day 6: Conditioning & Legs",
        "is_rest_day": false,
        "exercises": [
          {"name": "Walking Lunges (Bodyweight)", "sets": 3, "reps": "12 per leg", "notes": "Keep torso upright, step forward."},
          {"name": "Leg Extensions", "sets": 3, "reps": "15", "notes": "Hold extension for a split second."},
          {"name": "Hanging Leg Raise", "sets": 3, "reps": "10-12", "notes": "Lift legs using abdominal power."},
          {"name": "Bird-Dog", "sets": 3, "reps": "10 per side", "notes": "Reach hand and opposite foot straight."}
        ]
      },
      {
        "day_index": 7,
        "name": "Day 7: Complete Rest & Recovery",
        "is_rest_day": true,
        "exercises": []
      }
    ]
  };

  static const List<Map<String, String>> fallbackExercises = [
    // Chest
    {'name': 'Pushups', 'target': 'Chest', 'equipment': 'body weight'},
    {'name': 'Barbell Bench Press', 'target': 'Chest', 'equipment': 'barbell'},
    {'name': 'Dumbbell Bench Press', 'target': 'Chest', 'equipment': 'dumbbell'},
    {'name': 'Dumbbell Flyes', 'target': 'Chest', 'equipment': 'dumbbell'},
    {'name': 'Incline Barbell Bench Press', 'target': 'Chest', 'equipment': 'barbell'},
    {'name': 'Decline Barbell Bench Press', 'target': 'Chest', 'equipment': 'barbell'},
    {'name': 'Cable Chest Press', 'target': 'Chest', 'equipment': 'cable'},
    // Back
    {'name': 'Pullups', 'target': 'Back', 'equipment': 'body weight'},
    {'name': 'Chinups', 'target': 'Back', 'equipment': 'body weight'},
    {'name': 'Cable Rows (Seated)', 'target': 'Back', 'equipment': 'cable'},
    {'name': 'Barbell Row', 'target': 'Back', 'equipment': 'barbell'},
    {'name': 'One-Arm Dumbbell Row', 'target': 'Back', 'equipment': 'dumbbell'},
    {'name': 'Lat Pulldown', 'target': 'Back', 'equipment': 'cable'},
    {'name': 'Deadlift', 'target': 'Back', 'equipment': 'barbell'},
    // Legs
    {'name': 'Barbell Squat', 'target': 'Legs', 'equipment': 'barbell'},
    {'name': 'Dumbbell Goblet Squat', 'target': 'Legs', 'equipment': 'dumbbell'},
    {'name': 'Walking Lunges (Bodyweight)', 'target': 'Legs', 'equipment': 'body weight'},
    {'name': 'Dumbbell Lunges', 'target': 'Legs', 'equipment': 'dumbbell'},
    {'name': 'Calf Raises (Standing)', 'target': 'Legs', 'equipment': 'body weight'},
    {'name': 'Leg Press', 'target': 'Legs', 'equipment': 'machine'},
    {'name': 'Leg Extensions', 'target': 'Legs', 'equipment': 'machine'},
    {'name': 'Seated Leg Curl', 'target': 'Legs', 'equipment': 'machine'},
    // Shoulders
    {'name': 'Dumbbell Shoulder Press', 'target': 'Shoulders', 'equipment': 'dumbbell'},
    {'name': 'Military Press', 'target': 'Shoulders', 'equipment': 'barbell'},
    {'name': 'Lateral Raises (Dumbbell)', 'target': 'Shoulders', 'equipment': 'dumbbell'},
    {'name': 'Front Dumbbell Raise', 'target': 'Shoulders', 'equipment': 'dumbbell'},
    // Arms
    {'name': 'Dumbbell Bicep Curl', 'target': 'Arms', 'equipment': 'dumbbell'},
    {'name': 'Barbell Bicep Curl', 'target': 'Arms', 'equipment': 'barbell'},
    {'name': 'Hammer Curls', 'target': 'Arms', 'equipment': 'dumbbell'},
    {'name': 'Triceps Pushdown (Cable)', 'target': 'Arms', 'equipment': 'cable'},
    {'name': 'Dumbbell Tricep Extension', 'target': 'Arms', 'equipment': 'dumbbell'},
    {'name': 'Bench Dips', 'target': 'Arms', 'equipment': 'body weight'},
    // Core
    {'name': 'Crunches', 'target': 'Core', 'equipment': 'body weight'},
    {'name': 'Plank', 'target': 'Core', 'equipment': 'body weight'},
    {'name': 'Russian Twist', 'target': 'Core', 'equipment': 'body weight'},
    {'name': 'Hanging Leg Raise', 'target': 'Core', 'equipment': 'body weight'},
    {'name': 'Bird-Dog', 'target': 'Core', 'equipment': 'body weight'},
  ];
}
