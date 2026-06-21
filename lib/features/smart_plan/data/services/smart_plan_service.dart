import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/services/ai_service.dart';
import '../../../../core/constants/api_keys.dart';
import '../../../../features/setup/presentation/providers/setup_provider.dart';
import '../../../../features/workout/data/repositories/exercise_repository.dart';
import '../../../../features/workout/data/services/workout_api_service.dart';
import '../../data/models/smart_meal_plan.dart';
import '../../data/models/smart_workout_plan.dart';

class SmartPlanService {
  static const String _nutritionApiBase =
      'https://nutrition-production-d7d2.up.railway.app';
  static const String _geminiHost =
      'https://generativelanguage.googleapis.com';
  static const String _geminiVersion = 'v1beta';
  static const String _geminiModel = 'gemini-2.5-flash';

  static const Map<String, dynamic> fallbackWorkoutPlanRaw = {
    "plan_name": "Ultimate Strength & Conditioning Plan",
    "description": "A comprehensive weekly plan focusing on compound lifts, core strength, and muscle recovery.",
    "days": [
      {
        "dayIndex": 1,
        "name": "Day 1: Upper Body Power Focus",
        "isRestDay": false,
        "exercises": [
          {"name": "Barbell Bench Press", "sets": 4, "reps": "8-10", "muscleGroup": "Chest", "notes": "Control the descent, explode up."},
          {"name": "Lat Pulldown", "sets": 4, "reps": "10-12", "muscleGroup": "Back", "notes": "Squeeze shoulder blades at the bottom."},
          {"name": "Dumbbell Shoulder Press", "sets": 3, "reps": "10-12", "muscleGroup": "Shoulders", "notes": "Keep core tight, press overhead."},
          {"name": "Dumbbell Bicep Curl", "sets": 3, "reps": "12", "muscleGroup": "Arms", "notes": "Squeeze biceps at the top."},
          {"name": "Triceps Pushdown (Cable)", "sets": 3, "reps": "12", "muscleGroup": "Arms", "notes": "Keep elbows tucked to the sides."}
        ]
      },
      {
        "dayIndex": 2,
        "name": "Day 2: Lower Body Strength Focus",
        "isRestDay": false,
        "exercises": [
          {"name": "Barbell Squat", "sets": 4, "reps": "8-10", "muscleGroup": "Legs", "notes": "Squat to parallel, drive through heels."},
          {"name": "Seated Leg Curl", "sets": 3, "reps": "12", "muscleGroup": "Legs", "notes": "Squeeze hamstrings at peak contraction."},
          {"name": "Dumbbell Goblet Squat", "sets": 3, "reps": "12", "muscleGroup": "Legs", "notes": "Keep chest up, hold dumbbell close."},
          {"name": "Calf Raises (Standing)", "sets": 4, "reps": "15", "muscleGroup": "Legs", "notes": "Hold stretch for 1 second at bottom."},
          {"name": "Plank", "sets": 3, "reps": "60 seconds", "muscleGroup": "Core", "notes": "Engage core, keep hips level."}
        ]
      },
      {
        "dayIndex": 3,
        "name": "Day 3: Rest & Active Recovery",
        "isRestDay": true,
        "exercises": []
      },
      {
        "dayIndex": 4,
        "name": "Day 4: Push Day Conditioning",
        "isRestDay": false,
        "exercises": [
          {"name": "Dumbbell Bench Press", "sets": 4, "reps": "10", "muscleGroup": "Chest", "notes": "Control the movement on each rep."},
          {"name": "Military Press", "sets": 3, "reps": "8-10", "muscleGroup": "Shoulders", "notes": "Avoid leaning back, press cleanly."},
          {"name": "Dumbbell Flyes", "sets": 3, "reps": "12", "muscleGroup": "Chest", "notes": "Focus on the chest stretch."},
          {"name": "Lateral Raises (Dumbbell)", "sets": 4, "reps": "15", "muscleGroup": "Shoulders", "notes": "Lead with elbows, raise to side."},
          {"name": "Bench Dips", "sets": 3, "reps": "12-15", "muscleGroup": "Arms", "notes": "Keep back close to bench."}
        ]
      },
      {
        "dayIndex": 5,
        "name": "Day 5: Pull Day & Core",
        "isRestDay": false,
        "exercises": [
          {"name": "Pullups", "sets": 4, "reps": "8-12", "muscleGroup": "Back", "notes": "Control the negative down phase."},
          {"name": "Barbell Row", "sets": 4, "reps": "8-10", "muscleGroup": "Back", "notes": "Keep spine neutral, pull to belly button."},
          {"name": "Hammer Curls", "sets": 3, "reps": "12", "muscleGroup": "Arms", "notes": "Keep wrists neutral, palms face in."},
          {"name": "Russian Twist", "sets": 3, "reps": "20", "muscleGroup": "Core", "notes": "Rotate torso, touch floor on sides."},
          {"name": "Crunches", "sets": 3, "reps": "15", "muscleGroup": "Core", "notes": "Exhale, squeeze upper abs."}
        ]
      },
      {
        "dayIndex": 6,
        "name": "Day 6: Conditioning & Legs",
        "isRestDay": false,
        "exercises": [
          {"name": "Walking Lunges (Bodyweight)", "sets": 3, "reps": "12 per leg", "muscleGroup": "Legs", "notes": "Keep torso upright, step forward."},
          {"name": "Leg Extensions", "sets": 3, "reps": "15", "muscleGroup": "Legs", "notes": "Hold extension for a split second."},
          {"name": "Hanging Leg Raise", "sets": 3, "reps": "10-12", "muscleGroup": "Core", "notes": "Lift legs using abdominal power."},
          {"name": "Bird-Dog", "sets": 3, "reps": "10 per side", "muscleGroup": "Core", "notes": "Reach hand and opposite foot straight."}
        ]
      },
      {
        "dayIndex": 7,
        "name": "Day 7: Complete Rest & Recovery",
        "isRestDay": true,
        "exercises": []
      }
    ]
  };

  final AIService _aiService = AIService();

  // ── Meal Plan ─────────────────────────────────────────────────

  Future<SmartMealPlan?> generateMealPlan(
    SetupProvider setup, {
    void Function(String status)? onStatusUpdate,
  }) async {
    final gender = setup.gender?.toLowerCase() == 'female' ? 'F' : 'M';
    final age = setup.age ?? 25;
    // API expects weight in kg (max exclusive 100) — clamp safely
    final weightKg = (setup.weight ?? 70.0).clamp(12.1, 99.9);
    // API expects height in metres (0.86 – 2.0) — setup stores cm
    final heightM = ((setup.height ?? 170.0) / 100.0).clamp(0.87, 1.99);

    final activityLevel = _mapActivityLevel(setup.activity);
    final goal = _mapGoal(setup.goal);

    final requestBody = {
      'age': age,
      'gender': gender,
      'weight': weightKg,
      'height': heightM,
      'activity_level': activityLevel,
      'goal': goal,
    };

    int retries = 0;
    int networkExceptions = 0;

    while (true) {
      try {
        debugPrint('SmartPlanService: Calling nutrition API with $requestBody (attempt ${retries + 1})');

        final response = await http
            .post(
              Uri.parse('$_nutritionApiBase/generate-plan'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          debugPrint('SmartPlanService: Nutrition API success');
          return SmartMealPlan.fromApiResponse(json);
        }

        final isTransient = response.statusCode == 429 ||
            response.statusCode == 503 ||
            response.statusCode == 504 ||
            response.statusCode == 502;

        if (isTransient) {
          retries++;
          final delay = (retries * 5).clamp(5, 30);
          onStatusUpdate?.call('Crafting your nutrition plan...');
          debugPrint('SmartPlanService: Nutrition API transient error ${response.statusCode}. Retrying in $delay seconds (attempt $retries)...');
          await Future.delayed(Duration(seconds: delay));
          continue;
        }

        debugPrint(
            'SmartPlanService: Nutrition API fatal error ${response.statusCode}: ${response.body}');
        return null;
      } catch (e) {
        networkExceptions++;
        if (networkExceptions > 30) {
          debugPrint('SmartPlanService: Nutrition API too many network exceptions. Aborting.');
          return null;
        }
        final delay = (networkExceptions * 5).clamp(5, 30);
        onStatusUpdate?.call('Crafting your nutrition plan...');
        debugPrint('SmartPlanService: Nutrition API exception: $e. Retrying in $delay seconds (attempt $networkExceptions/30)...');
        await Future.delayed(Duration(seconds: delay));
        continue;
      }
    }
  }

  // ── Workout Plan ──────────────────────────────────────────────

  Future<List<SmartWorkoutDay>?> generateWorkoutPlan(
    SetupProvider setup, {
    void Function(String status)? onStatusUpdate,
  }) async {
    return generateWorkoutPlanWithConfig(
      goal: _mapWorkoutGoal(setup.goal),
      experience: _mapExperience(setup.experience),
      location: _mapLocation(setup.location),
      daysPerWeek: setup.workoutDays?.first ?? 4,
      durationMinutes: 45, // Default for setup
      onStatusUpdate: onStatusUpdate,
    );
  }

  Future<List<SmartWorkoutDay>?> generateWorkoutPlanWithConfig({
    required String goal,
    required String experience,
    required String location,
    required int daysPerWeek,
    required int durationMinutes,
    void Function(String status)? onStatusUpdate,
  }) async {
    try {
      // 1. Fetch available exercises from SQLite based on constraints
      final repo = ExerciseRepository();
      List<Map<String, String>> availableExs = [];
      try {
        availableExs = await repo.getAvailableExercisesForAI(location);
      } catch (e) {
        debugPrint('SmartPlanService: generateWorkoutPlan query error: $e');
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
        
        availableExs = AIService.fallbackExercises.where((e) {
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
You are an elite personal trainer. Generate a professional 7-day workout plan.

User Profile:
- Fitness Goal: $goal
- Experience Level: $experience
- Workout Location: $location
- Training Days Per Week: $daysPerWeek days
- Session Duration: $durationMinutes minutes

CRITICAL RULE:
You MUST choose exercises ONLY from the list of available exercises provided below. Do not invent any new exercise names. Every exercise in your generated plan MUST match exactly one of the names from the list.

Allowed Exercise List:
$exerciseListStr

Rules:
1. Exactly 7 days (dayIndex 1=Monday to 7=Sunday)
2. Only $daysPerWeek days should be workout days; rest are rest days
3. Use real, well-known exercise names from the Allowed Exercise List above
4. For each exercise provide specific muscle group
5. Sets: 3-5, Reps: "8-12" or "12-15" format
6. Name each workout day descriptively (e.g., "Upper Body Push", "Leg Day", "Rest & Recovery")

Return ONLY valid JSON matching this exact structure:
{
  "plan_name": "string",
  "description": "string",
  "days": [
    {
      "dayIndex": 1,
      "name": "string",
      "isRestDay": false,
      "exercises": [
        {
          "name": "string",
          "sets": 3,
          "reps": "10-12",
          "muscleGroup": "string",
          "notes": "string or null"
        }
      ]
    }
  ]
}
''';

      final keys = ApiKeys.geminiKeys;
      int formatErrors = 0;

      for (int keyIndex = 0; keyIndex < keys.length; keyIndex++) {
        final apiKey = keys[keyIndex];
        final url = Uri.parse(
            '$_geminiHost/$_geminiVersion/models/$_geminiModel:generateContent?key=$apiKey');
        
        int attempt = 0;
        const int maxAttempts = 3;

        debugPrint(
            'SmartPlanService: Attempting generateWorkoutPlan with API key ${keyIndex + 1}/${keys.length}...');

        while (attempt < maxAttempts) {
          try {
            final response = await http
                .post(
                  url,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'contents': [
                      {
                        'parts': [
                          {'text': prompt}
                        ]
                      }
                    ],
                    'generationConfig': {
                      'temperature': 0.7,
                      'responseMimeType': 'application/json',
                    }
                  }),
                )
                .timeout(const Duration(seconds: 45));

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body) as Map<String, dynamic>;

              if (data.containsKey('error')) {
                final errorCode = data['error']?['code'];
                final errorMsg = data['error']?['message'] ?? 'unknown';
                attempt++;
                debugPrint(
                    'SmartPlanService: Gemini error $errorCode in response body: $errorMsg (attempt $attempt/$maxAttempts with key ${keyIndex + 1}).');
                if (attempt < maxAttempts) {
                  onStatusUpdate?.call('Crafting your workout plan...');
                  await Future.delayed(const Duration(seconds: 5));
                }
                continue;
              }

              final candidates = data['candidates'];
              if (candidates != null && (candidates as List).isNotEmpty) {
                final text =
                    candidates[0]['content']['parts'][0]['text'] as String;
                final planJson = _aiService.extractJson(text);
                if (planJson != null) {
                  return await _processDays(planJson);
                }
              }
              
              formatErrors++;
              if (formatErrors > 5) {
                debugPrint('SmartPlanService: Too many JSON structure parsing errors. Aborting.');
                return null;
              }
              onStatusUpdate?.call('Crafting your workout plan...');
              debugPrint('SmartPlanService: Invalid structure in candidate response. Retrying (attempt $formatErrors/5)...');
              await Future.delayed(const Duration(seconds: 3));
              continue;
            }

            final isTransient = response.statusCode == 429 ||
                response.statusCode == 502 ||
                response.statusCode == 503 ||
                response.statusCode == 504;

            if (!isTransient) {
              debugPrint(
                  'SmartPlanService: Gemini API fatal error ${response.statusCode} with key ${keyIndex + 1}. Skipping key.');
              break;
            }

            attempt++;
            debugPrint(
                'SmartPlanService: Gemini API transient error ${response.statusCode} (attempt $attempt/$maxAttempts with key ${keyIndex + 1})');
            if (attempt < maxAttempts) {
              onStatusUpdate?.call('Crafting your workout plan...');
              await Future.delayed(const Duration(seconds: 5));
            }
          } catch (e) {
            attempt++;
            debugPrint(
                'SmartPlanService: Exception in generateWorkoutPlan: $e (attempt $attempt/$maxAttempts with key ${keyIndex + 1})');
            if (attempt < maxAttempts) {
              onStatusUpdate?.call('Crafting your workout plan...');
              await Future.delayed(const Duration(seconds: 5));
            }
          }
        }
        debugPrint(
            'SmartPlanService: API key ${keyIndex + 1} failed after $maxAttempts attempts. Switching to next key...');
      }

      debugPrint('SmartPlanService: All API keys failed. Using fallback workout plan.');
      return await _processDays(fallbackWorkoutPlanRaw);
    } catch (e) {
      debugPrint('SmartPlanService: generateWorkoutPlan exception: $e');
    }
    return null;
  }

  Future<List<SmartWorkoutDay>> fallbackParsedDays() async {
    return _processDays(fallbackWorkoutPlanRaw);
  }

  Future<List<SmartWorkoutDay>> _processDays(
      Map<String, dynamic> planJson) async {
    final rawDays = planJson['days'];
    if (rawDays is! List) return [];

    final List<SmartWorkoutDay> result = [];

    for (final dayRaw in rawDays) {
      if (dayRaw is! Map<String, dynamic>) continue;

      final isRest = dayRaw['isRestDay'] == true;
      final rawExercises = dayRaw['exercises'];
      final List<SmartWorkoutExercise> exercises = [];

      if (!isRest && rawExercises is List) {
        for (final ex in rawExercises) {
          if (ex is! Map<String, dynamic>) continue;

          final aiName = ex['name']?.toString() ?? 'Exercise';
          // Try to find local match for GIF
          final localMatch = await _aiService.findLocalMatch(aiName);

          exercises.add(SmartWorkoutExercise(
            name: localMatch?.name ?? aiName,
            sets: (ex['sets'] is int)
                ? ex['sets'] as int
                : int.tryParse(ex['sets']?.toString() ?? '3') ?? 3,
            reps: ex['reps']?.toString() ?? '10',
            notes: ex['notes']?.toString(),
            muscleGroup: localMatch?.target ?? ex['muscleGroup']?.toString(),
            gifUrl: localMatch?.gifUrl,
            exerciseId: localMatch?.id,
            videoUrl: localMatch?.videoUrl,
          ));
        }
      }

      result.add(SmartWorkoutDay(
        dayIndex: (dayRaw['dayIndex'] is int)
            ? dayRaw['dayIndex'] as int
            : int.tryParse(dayRaw['dayIndex']?.toString() ?? '1') ?? 1,
        name: dayRaw['name']?.toString() ?? 'Day',
        isRestDay: isRest,
        exercises: exercises,
      ));
    }

    // Sort by dayIndex to guarantee correct order
    result.sort((a, b) => a.dayIndex.compareTo(b.dayIndex));
    return result;
  }

  // ── Mapping Helpers ───────────────────────────────────────────

  String _mapActivityLevel(String? activity) {
    switch (activity) {
      case 'sedentary':
        return 'Sedentary';
      case 'lightly_active':
      case 'moderately_active':
        return 'Active';
      case 'very_active':
      case 'extra_active':
        return 'Very Active';
      default:
        return 'Active';
    }
  }

  String _mapGoal(String? goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Lose Weight';
      case 'build_muscle':
        return 'Gain Weight';
      case 'stay_fit':
        return 'Maintain Weight';
      case 'improve_endurance':
        return 'Maintain Weight';
      default:
        return 'Maintain Weight';
    }
  }

  String _mapWorkoutGoal(String? goal) {
    switch (goal) {
      case 'lose_weight':
        return 'Fat Loss';
      case 'build_muscle':
        return 'Muscle Building';
      case 'stay_fit':
        return 'General Fitness';
      case 'improve_endurance':
        return 'Endurance & Cardio';
      default:
        return 'General Fitness';
    }
  }

  String _mapExperience(String? exp) {
    switch (exp) {
      case 'beginner':
        return 'Beginner';
      case 'novice':
        return 'Novice';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      case 'expert':
        return 'Expert';
      default:
        return 'Beginner';
    }
  }

  String _mapLocation(String? loc) {
    switch (loc) {
      case 'home':
        return 'Home (no equipment)';
      case 'gym':
        return 'Commercial Gym (full equipment)';
      case 'outdoor':
        return 'Outdoors (bodyweight/minimal equipment)';
      case 'anywhere':
        return 'Flexible (any environment)';
      default:
        return 'Commercial Gym';
    }
  }
}
