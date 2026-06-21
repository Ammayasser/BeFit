// lib/features/profile/presentation/providers/user_provider.dart

import 'package:flutter/foundation.dart';
import '../../domain/entities/user_profile.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository = UserRepository(UserService());

  UserProfileEntity? _profile;
  bool _isLoading = false;
  String? _error;

  UserProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasProfile => _profile != null;
  String get displayName => _profile?.name ?? 'User';
  String get email => _profile?.email ?? '';

  // Direct getters for compatibility with other features
  int get age => _profile?.age ?? 0;
  double get height => _profile?.height ?? 0.0;
  double get weight => _profile?.weight ?? 0.0;
  String get gender => _profile?.gender ?? 'Male';
  String get fitnessGoal => _profile?.fitnessGoal ?? 'BuildMuscle';
  String get activityLevel => _profile?.activityLevel ?? 'moderately_active';
  String get experienceLevel => _profile?.experienceLevel ?? 'intermediate';
  String get workoutLocation => _profile?.workoutLocation ?? 'gym';
  int get workoutDays => _profile?.workoutDays ?? 4;

  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _profile = await _repository.getUserProfile();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(UserProfileEntity newProfile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateUserProfile(newProfile);
      _profile = newProfile;
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvatar(String filePath) async {
    _isLoading = true;
    _error = null;

    // 1. Update locally first for immediate preview
    if (_profile != null) {
      _profile = _profile!.copyWith(avatarUrl: filePath);
      notifyListeners();
    }

    try {
      // 2. Perform upload
      final newUrl = await _repository.uploadAvatar(filePath);
      
      // 3. Update with final remote URL
      if (newUrl != null && _profile != null) {
        _profile = _profile!.copyWith(avatarUrl: newUrl);
      } else {
        await loadProfile();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Populates the profile locally immediately after registration.
  void hydrateFromRegistration({
    required String name,
    required String email,
    required Map<String, dynamic> setupBody,
  }) {
    _profile = UserProfileEntity(
      id: 'temp', // Will be replaced on next load
      name: name,
      email: email,
      age: setupBody['age'] ?? 0,
      gender: setupBody['gender'] ?? 'Male',
      height: (setupBody['height'] as num?)?.toDouble() ?? 0.0,
      weight: (setupBody['weight'] as num?)?.toDouble() ?? 0.0,
      fitnessGoal: setupBody['fitnessGoal'] ?? 'BuildMuscle',
      activityLevel: _mapIntToActivity(setupBody['activityLevel']),
      experienceLevel: _mapIntToExperience(setupBody['experienceLevel']),
      workoutLocation: _mapIntToLocation(setupBody['workoutLocation']),
      workoutDays: setupBody['workoutDays'] ?? 4,
    );
    notifyListeners();
  }

  String _mapIntToActivity(dynamic val) {
    const map = {
      1: 'sedentary',
      2: 'lightly_active',
      3: 'moderately_active',
      4: 'very_active',
      5: 'extra_active',
    };
    return map[val] ?? 'moderately_active';
  }

  String _mapIntToExperience(dynamic val) {
    const map = {
      1: 'beginner',
      2: 'novice',
      3: 'intermediate',
      4: 'advanced',
      5: 'expert',
    };
    return map[val] ?? 'intermediate';
  }

  String _mapIntToLocation(dynamic val) {
    const map = {
      1: 'home',
      2: 'gym',
      3: 'outdoor',
      4: 'anywhere',
    };
    return map[val] ?? 'gym';
  }
}
