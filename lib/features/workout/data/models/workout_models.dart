import 'dart:convert';
import '../../core/exercise_media.dart';
import 'workout_routine.dart' show SetType, SetTypeLabel;

class ProTip {
  final String type;
  final String title;
  final String description;

  ProTip({
    required this.type,
    required this.title,
    required this.description,
  });

  factory ProTip.fromJson(Map<String, dynamic> json) {
    String desc = '';
    if (json['description'] is List) {
      desc = (json['description'] as List).join(' ');
    } else {
      desc = json['description']?.toString() ?? '';
    }
    return ProTip(
      type: json['type']?.toString() ?? 'performance_tip',
      title: json['title']?.toString() ?? 'Pro Tip',
      description: desc,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'title': title,
    'description': description,
  };
}

// ExerciseLibraryItem — maps to exercises_library SQLite table + Exercise API
class ExerciseLibraryItem {
  final String id;
  final String name;
  final String? bodyPart;
  final String? target;           // primary muscle
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String? equipment;
  final String? difficulty;       // "beginner" | "intermediate" | "advanced"
  final String? category;         // "strength" | "cardio" etc.
  final String? mechanic;         // "compound" | "isolation"
  final String? forceType;        // "push" | "pull"
  final double? met;              // metabolic equivalent — used for calorie calc
  final double? caloriesPerMin;
  final String? description;
  final List<String> instructions;
  final String? gifUrl;           // fallback / primary image
  final List<String> images;      // all images for animation

  // Fitbod specific additions
  final String? videoUrl;
  final String? videoUrlMobile;
  final List<ProTip> proTips;
  final bool? isBodyweight;
  final String? author;
  final int? popularityRank;
  final int? efficacyRank;

  ExerciseLibraryItem({
    required this.id,
    required this.name,
    this.bodyPart,
    this.target,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.equipment,
    this.difficulty,
    this.category,
    this.mechanic,
    this.forceType,
    this.met,
    this.caloriesPerMin,
    this.description,
    required this.instructions,
    this.gifUrl,
    required this.images,
    this.videoUrl,
    this.videoUrlMobile,
    required this.proTips,
    this.isBodyweight,
    this.author,
    this.popularityRank,
    this.efficacyRank,
  });

  String get primaryEquipment => normalizePrimaryEquipment(equipment);

  static String normalizePrimaryEquipment(String? equipment) {
    if (equipment == null || equipment.isEmpty) return 'Body Weight';
    final e = equipment.toLowerCase();
    if (e.contains('barbell') || e.contains('ez bar') || e.contains('trap bar')) return 'Barbell';
    if (e.contains('dumbbell')) return 'Dumbbell';
    if (e.contains('cable') || e.contains('pulley') || e.contains('pulldown')) return 'Cable';
    if (e.contains('kettlebell')) return 'Kettlebell';
    if (e.contains('machine') || e.contains('smith') || e.contains('hack squat')) return 'Machine';
    if (e.contains('band')) return 'Bands';
    if (e.contains('bench') && !e.contains('press')) return 'Bench';
    if (e.contains('trx')) return 'TRX';
    if (e.contains('medicine ball')) return 'Medicine Ball';
    return 'Other';
  }

  static const Map<String, double> muscleMetEstimates = {
    'chest': 5.0, 'back': 5.0, 'shoulders': 4.5,
    'biceps': 3.5, 'triceps': 3.5, 'quadriceps': 6.0,
    'hamstrings': 5.5, 'glutes': 5.5, 'calves': 4.0,
    'forearms': 3.0, 'abs': 4.0, 'obliques': 4.0,
    'abductors': 3.5, 'adductors': 3.5,
    'trapezius': 4.5, 'neck': 3.0, 'lower-back': 5.0,
  };

  static double estimateMet(List<String> primaryMuscles, String? mechanic) {
    if (primaryMuscles.isEmpty) return 4.0;
    double maxMet = 0.0;
    for (final m in primaryMuscles) {
      final clean = m.toLowerCase().trim();
      final val = muscleMetEstimates[clean] ?? 4.0;
      if (val > maxMet) maxMet = val;
    }
    if (mechanic == 'compound') {
      return maxMet * 1.2;
    }
    return maxMet;
  }

  factory ExerciseLibraryItem.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    List<ProTip> parseProTips(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map((e) {
          if (e is Map<String, dynamic>) return ProTip.fromJson(e);
          if (e is String) {
            try {
              final decoded = jsonDecode(e);
              if (decoded is Map<String, dynamic>) return ProTip.fromJson(decoded);
            } catch (_) {}
          }
          return ProTip(type: 'performance_tip', title: 'Pro Tip', description: e.toString());
        }).toList();
      }
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) {
            return decoded.map((e) => ProTip.fromJson(e as Map<String, dynamic>)).toList();
          }
        } catch (_) {}
      }
      return [];
    }

    final primaryMuscles = parseList(json['primaryMuscles'] ?? json['primary_muscles']);
    final primaryMuscle = primaryMuscles.isNotEmpty ? primaryMuscles.first : null;

    // Map primary muscle to body part for UI grouping
    String? mapMuscleToBodyPart(String? muscle) {
      if (muscle == null) return null;
      final m = muscle.toLowerCase().trim();
      if (m == 'chest') return 'Chest';
      if (['lats', 'middle back', 'lower back', 'traps', 'back'].contains(m)) return 'Back';
      if (['biceps', 'triceps', 'forearms'].contains(m)) return 'Upper Arms';
      if (['quadriceps', 'hamstrings', 'glutes'].contains(m)) return 'Upper Legs';
      if (m == 'calves') return 'Lower Legs';
      if (m == 'shoulders') return 'Shoulders';
      if (['abdominals', 'obliques', 'abs'].contains(m)) return 'Waist';
      if (m == 'cardio') return 'Cardio';
      return m[0].toUpperCase() + m.substring(1);
    }

    String? bodyPart = json['bodyPart']?.toString() ?? json['body_part']?.toString();
    if (bodyPart == null || bodyPart.isEmpty) {
      bodyPart = mapMuscleToBodyPart(primaryMuscle);
    }

    final allImages = parseExerciseImagesFromJson(json);

    // Calculate MET if missing
    double? metVal = json['met'] != null ? double.tryParse(json['met'].toString()) : null;
    metVal ??= estimateMet(primaryMuscles, (json['mechanic'] ?? json['mechanic'])?.toString());

    return ExerciseLibraryItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bodyPart: bodyPart ?? 'Other',
      target: primaryMuscle != null ? primaryMuscle[0].toUpperCase() + primaryMuscle.substring(1) : '',
      primaryMuscles: primaryMuscles,
      secondaryMuscles: parseList(json['secondaryMuscles'] ?? json['secondary_muscles']),
      equipment: (json['equipment'] ?? json['equipment'])?.toString() ?? '',
      difficulty: (json['level'] ?? json['difficulty'])?.toString() ?? '',
      category: (json['category'] ?? json['category'])?.toString() ?? '',
      mechanic: (json['mechanic'] ?? json['mechanic'])?.toString() ?? '',
      forceType: (json['force'] ?? json['force_type'])?.toString() ?? '',
      met: metVal,
      caloriesPerMin: (json['caloriesPerMinute'] ?? json['calories_per_min']) != null 
          ? double.tryParse((json['caloriesPerMinute'] ?? json['calories_per_min']).toString()) 
          : null,
      description: json['description']?.toString(),
      instructions: parseList(json['instructions']),
      gifUrl: allImages.isNotEmpty ? allImages.first : null,
      images: allImages,
      videoUrl: json['videoUrl']?.toString() ?? json['video_url']?.toString(),
      videoUrlMobile: json['videoUrlMobile']?.toString() ?? json['video_url_mobile']?.toString(),
      proTips: parseProTips(json['proTips'] ?? json['pro_tips']),
      isBodyweight: json['isBodyweight'] == true || json['is_bodyweight'] == 1 || json['isBodyweight'] == 1,
      author: json['author']?.toString(),
      popularityRank: json['popularityRank'] != null ? int.tryParse(json['popularityRank'].toString()) : (json['popularity_rank'] != null ? int.tryParse(json['popularity_rank'].toString()) : null),
      efficacyRank: json['efficacyRank'] != null ? int.tryParse(json['efficacyRank'].toString()) : (json['efficacy_rank'] != null ? int.tryParse(json['efficacy_rank'].toString()) : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'body_part': bodyPart,
      'target': target,
      'primary_muscles': jsonEncode(primaryMuscles),
      'secondary_muscles': jsonEncode(secondaryMuscles),
      'equipment': equipment,
      'primary_equipment': primaryEquipment,
      'difficulty': difficulty,
      'category': category,
      'mechanic': mechanic,
      'force_type': forceType,
      'met': met,
      'calories_per_min': caloriesPerMin,
      'description': description,
      'instructions': jsonEncode(instructions),
      'gif_url': gifUrl,
      'images': jsonEncode(images),
      'video_url': videoUrl,
      'video_url_mobile': videoUrlMobile,
      'pro_tips': jsonEncode(proTips),
      'is_bodyweight': (isBodyweight == true) ? 1 : 0,
      'author': author,
      'popularity_rank': popularityRank,
      'efficacy_rank': efficacyRank,
    };
  }
}

// SessionExercise — one exercise inside an active workout session
class SessionExercise {
  final String id;
  final String name;
  final String? muscleGroup;
  final String? gifUrl;
  final int targetSets;
  final String targetReps;     // e.g. "8-10"
  final double? targetWeight;
  final double? met;
  List<LoggedSet> loggedSets;
  bool isSkipped;

  SessionExercise({
    required this.id,
    required this.name,
    this.muscleGroup,
    this.gifUrl,
    required this.targetSets,
    required this.targetReps,
    this.targetWeight,
    this.met,
    required this.loggedSets,
    this.isSkipped = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      'gifUrl': gifUrl,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
      'met': met,
      'loggedSets': loggedSets.map((e) => e.toJson()).toList(),
      'isSkipped': isSkipped,
    };
  }

  factory SessionExercise.fromJson(Map<String, dynamic> json) {
    return SessionExercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      muscleGroup: json['muscleGroup']?.toString(),
      gifUrl: normalizeExerciseMediaUrl(json['gifUrl']?.toString()),
      targetSets: json['targetSets'] as int? ?? 0,
      targetReps: json['targetReps']?.toString() ?? '',
      targetWeight: json['targetWeight'] != null ? double.tryParse(json['targetWeight'].toString()) : null,
      met: json['met'] != null ? double.tryParse(json['met'].toString()) : null,
      loggedSets: (json['loggedSets'] as List? ?? [])
          .map((e) => LoggedSet.fromJson(e as Map<String, dynamic>))
          .toList(),
      isSkipped: json['isSkipped'] as bool? ?? false,
    );
  }
}

// LoggedSet — one completed set
class LoggedSet {
  int setNumber;
  double weightKg;
  int reps;
  final DateTime loggedAt;
  bool isEdited;
  bool isCompleted;
  SetType setType;

  LoggedSet({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.loggedAt,
    this.isEdited = false,
    this.isCompleted = false,
    this.setType = SetType.normal,
  });

  Map<String, dynamic> toJson() {
    return {
      'setNumber': setNumber,
      'weightKg': weightKg,
      'reps': reps,
      'loggedAt': loggedAt.toIso8601String(),
      'isEdited': isEdited,
      'isCompleted': isCompleted,
      'setType': setType.toJson(),
    };
  }

  factory LoggedSet.fromJson(Map<String, dynamic> json) {
    return LoggedSet(
      setNumber: json['setNumber'] as int? ?? 1,
      weightKg: double.tryParse(json['weightKg'].toString()) ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      loggedAt: json['loggedAt'] != null ? DateTime.parse(json['loggedAt'].toString()) : DateTime.now(),
      isEdited: json['isEdited'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      setType: SetTypeLabel.fromJson(json['setType']?.toString()),
    );
  }
}

// WorkoutSession — entire active session state
class WorkoutSession {
  final String sessionId;
  final String userId;
  final String workoutName;
  final DateTime startedAt;
  DateTime? finishedAt;
  final List<SessionExercise> exercises;
  int currentExerciseIndex;
  String? sessionNote;
  int? moodRating;   // 1-5

  WorkoutSession({
    required this.sessionId,
    required this.userId,
    required this.workoutName,
    required this.startedAt,
    this.finishedAt,
    required this.exercises,
    this.currentExerciseIndex = 0,
    this.sessionNote,
    this.moodRating,
  });

  // computed:
  int get totalSets     => exercises.expand((e) => e.loggedSets).where((s) => s.isCompleted).length;
  int get totalReps     => exercises.expand((e) => e.loggedSets).where((s) => s.isCompleted).fold(0, (s, l) => s + l.reps);
  double get totalVolume => exercises.expand((e) => e.loggedSets).where((s) => s.isCompleted).fold(0, (s, l) => s + l.weightKg * l.reps);
  Duration get duration  => (finishedAt ?? DateTime.now()).difference(startedAt);

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'workoutName': workoutName,
      'startedAt': startedAt.toIso8601String(),
      'finishedAt': finishedAt?.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'currentExerciseIndex': currentExerciseIndex,
      'sessionNote': sessionNote,
      'moodRating': moodRating,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      sessionId: json['sessionId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      workoutName: json['workoutName']?.toString() ?? '',
      startedAt: json['startedAt'] != null ? DateTime.parse(json['startedAt'].toString()) : DateTime.now(),
      finishedAt: json['finishedAt'] != null ? DateTime.parse(json['finishedAt'].toString()) : null,
      exercises: (json['exercises'] as List? ?? [])
          .map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentExerciseIndex: json['currentExerciseIndex'] as int? ?? 0,
      sessionNote: json['sessionNote']?.toString(),
      moodRating: json['moodRating'] as int?,
    );
  }
}
