// lib/features/progress/data/models/weight_log.dart

class WeightLog {
  final String id;
  final String userId;
  final double weightKg;
  final double? bodyFatPercentage;
  final double? muscleMassKg;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final double? neckCm;
  final String? notes;
  final DateTime loggedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WeightLog({
    required this.id,
    required this.userId,
    required this.weightKg,
    this.bodyFatPercentage,
    this.muscleMassKg,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.neckCm,
    this.notes,
    required this.loggedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WeightLog.fromJson(Map<String, dynamic> json) =>
      WeightLog.fromMap(json);

  Map<String, dynamic> toJson() => toMap();

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      weightKg: (map['weight_kg'] as num).toDouble(),
      bodyFatPercentage: map['body_fat_percentage'] != null
          ? (map['body_fat_percentage'] as num).toDouble()
          : null,
      muscleMassKg: map['muscle_mass_kg'] != null
          ? (map['muscle_mass_kg'] as num).toDouble()
          : null,
      waistCm: map['waist_cm'] != null
          ? (map['waist_cm'] as num).toDouble()
          : null,
      chestCm: map['chest_cm'] != null
          ? (map['chest_cm'] as num).toDouble()
          : null,
      hipsCm: map['hips_cm'] != null
          ? (map['hips_cm'] as num).toDouble()
          : null,
      neckCm: map['neck_cm'] != null
          ? (map['neck_cm'] as num).toDouble()
          : null,
      notes: map['notes'] as String?,
      loggedAt: DateTime.parse(map['logged_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'weight_kg': weightKg,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass_kg': muscleMassKg,
      'waist_cm': waistCm,
      'chest_cm': chestCm,
      'hips_cm': hipsCm,
      'neck_cm': neckCm,
      'notes': notes,
      'logged_at': loggedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WeightLog copyWith({
    String? id,
    String? userId,
    double? weightKg,
    double? bodyFatPercentage,
    double? muscleMassKg,
    double? waistCm,
    double? chestCm,
    double? hipsCm,
    double? neckCm,
    String? notes,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeightLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weightKg: weightKg ?? this.weightKg,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      waistCm: waistCm ?? this.waistCm,
      chestCm: chestCm ?? this.chestCm,
      hipsCm: hipsCm ?? this.hipsCm,
      neckCm: neckCm ?? this.neckCm,
      notes: notes ?? this.notes,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
