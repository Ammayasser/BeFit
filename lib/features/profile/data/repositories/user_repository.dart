// lib/features/profile/data/repositories/user_repository.dart

import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_user_repository.dart';
import '../services/user_service.dart';

class UserRepository implements IUserRepository {
  final UserService _service;

  UserRepository(this._service);

  @override
  Future<UserProfileEntity?> getUserProfile() async {
    final result = await _service.getProfile();
    if (result['success'] == true) {
      return _mapToEntity(result['data']);
    }
    return null;
  }

  @override
  Future<void> updateUserProfile(UserProfileEntity profile) async {
    final body = _mapFromEntity(profile);
    final result = await _service.updateProfile(body);
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to update profile');
    }
  }

  @override
  Future<String?> uploadAvatar(String filePath) async {
    final result = await _service.uploadAvatar(filePath);
    if (result['success'] != true) {
      throw Exception(result['message'] ?? 'Failed to upload avatar');
    }
    return result['avatarUrl'] as String?;
  }

  UserProfileEntity _mapToEntity(Map<String, dynamic> json) {
    return UserProfileEntity(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Male',
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['currentWeight'] as num?)?.toDouble() ?? (json['weight'] as num?)?.toDouble() ?? 0.0,
      fitnessGoal: json['fitnessGoal'] ?? 'BuildMuscle',
      activityLevel: _mapActivityLevel(json['activityLevel']),
      experienceLevel: _mapExperienceLevel(json['experienceLevel']),
      workoutLocation: _mapWorkoutLocation(json['workoutLocation']),
      workoutDays: json['workoutDays'] ?? 4,
    );
  }

  Map<String, dynamic> _mapFromEntity(UserProfileEntity entity) {
    return {
      'name': entity.name,
      'age': entity.age,
      'gender': entity.gender,
      'height': entity.height,
      'weight': entity.weight,
      'fitnessGoal': entity.fitnessGoal,
      'activityLevel': _unmapActivityLevel(entity.activityLevel),
      'experienceLevel': _unmapExperienceLevel(entity.experienceLevel),
      'workoutLocation': _unmapWorkoutLocation(entity.workoutLocation),
      'workoutDays': entity.workoutDays,
    };
  }

  String _mapActivityLevel(dynamic value) {
    if (value is int) {
      const map = {
        1: 'sedentary',
        2: 'lightly_active',
        3: 'moderately_active',
        4: 'very_active',
        5: 'extra_active',
      };
      return map[value] ?? 'moderately_active';
    }
    if (value is String) {
      final valLower = value.toLowerCase().replaceAll('_', '');
      if (valLower == 'sedentary') return 'sedentary';
      if (valLower == 'lightlyactive') return 'lightly_active';
      if (valLower == 'moderatelyactive') return 'moderately_active';
      if (valLower == 'veryactive') return 'very_active';
      if (valLower == 'extraactive') return 'extra_active';
    }
    return value?.toString() ?? 'moderately_active';
  }

  int _unmapActivityLevel(String level) {
    const map = {
      'sedentary': 1,
      'lightly_active': 2,
      'moderately_active': 3,
      'very_active': 4,
      'extra_active': 5,
    };
    return map[level] ?? 3;
  }

  String _mapExperienceLevel(dynamic value) {
    if (value is int) {
      const map = {
        1: 'beginner',
        2: 'novice',
        3: 'intermediate',
        4: 'advanced',
        5: 'expert',
      };
      return map[value] ?? 'intermediate';
    }
    if (value is String) {
      final valLower = value.toLowerCase();
      if (valLower == 'beginner') return 'beginner';
      if (valLower == 'novice') return 'novice';
      if (valLower == 'intermediate') return 'intermediate';
      if (valLower == 'advanced') return 'advanced';
      if (valLower == 'expert') return 'expert';
    }
    return value?.toString() ?? 'intermediate';
  }

  int _unmapExperienceLevel(String level) {
    const map = {
      'beginner': 1,
      'novice': 2,
      'intermediate': 3,
      'advanced': 4,
      'expert': 5,
    };
    return map[level] ?? 3;
  }

  String _mapWorkoutLocation(dynamic value) {
    if (value is int) {
      const map = {
        1: 'home',
        2: 'gym',
        3: 'outdoor',
        4: 'anywhere',
      };
      return map[value] ?? 'gym';
    }
    if (value is String) {
      final valLower = value.toLowerCase().trim();
      if (valLower == 'home') return 'home';
      if (valLower == 'gym') return 'gym';
      if (valLower == 'outdoor' || valLower == 'outdoors') return 'outdoor';
      if (valLower == 'anywhere') return 'anywhere';
    }
    return value?.toString() ?? 'gym';
  }

  int _unmapWorkoutLocation(String location) {
    const map = {
      'home': 1,
      'gym': 2,
      'outdoor': 3,
      'anywhere': 4,
    };
    return map[location] ?? 2;
  }
}
