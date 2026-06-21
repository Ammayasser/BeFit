// lib/features/profile/domain/entities/user_profile.dart

class UserProfileEntity {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String fitnessGoal;
  final String activityLevel;
  final String experienceLevel;
  final String workoutLocation;
  final int workoutDays;

  const UserProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.experienceLevel,
    required this.workoutLocation,
    required this.workoutDays,
  });

  UserProfileEntity copyWith({
    String? id,
    String? name,
    String? email,
    String? avatarUrl,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? fitnessGoal,
    String? activityLevel,
    String? experienceLevel,
    String? workoutLocation,
    int? workoutDays,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      workoutLocation: workoutLocation ?? this.workoutLocation,
      workoutDays: workoutDays ?? this.workoutDays,
    );
  }
}
