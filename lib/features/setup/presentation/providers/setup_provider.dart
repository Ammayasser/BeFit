// lib/features/setup/presentation/providers/setup_provider.dart

import 'package:flutter/foundation.dart';

enum SetupStep {
  gender,
  age,
  height,
  weight,
  goal,
  activity,
  experience,
  location,
  workoutDays,
  createAccount,
}

class SetupProvider extends ChangeNotifier {
  bool _disposed = false;
  SetupStep _currentStep = SetupStep.gender;
  final Map<SetupStep, dynamic> _answers = {};
  bool _isLoading = false;
  String? _errorMessage;

  SetupStep get currentStep => _currentStep;
  Map<SetupStep, dynamic> get answers => Map.unmodifiable(_answers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentStepIndex => SetupStep.values.indexOf(_currentStep);
  int get totalSteps => SetupStep.values.length;
  double get progress => (currentStepIndex + 1) / totalSteps;

  // Getters for each answer
  String? get gender => _answers[SetupStep.gender];
  int? get age => _answers[SetupStep.age];
  double? get height => _answers[SetupStep.height];
  double? get weight => _answers[SetupStep.weight];
  String? get goal => _answers[SetupStep.goal];
  String? get activity => _answers[SetupStep.activity];
  String? get experience => _answers[SetupStep.experience];
  String? get location => _answers[SetupStep.location];
  List<int>? get workoutDays => _answers[SetupStep.workoutDays];

  bool get canGoNext => _hasValidAnswerForCurrentStep();
  bool get canGoPrevious => currentStepIndex > 0;
  bool get canFinish => currentStepIndex == totalSteps - 1 && canGoNext;

  void setAnswer(SetupStep step, dynamic answer) {
    _answers[step] = answer;
    _errorMessage = null;
    _notify();
  }

  void nextStep() {
    if (!canGoNext) {
      _errorMessage = 'Please complete this step before continuing';
      _notify();
      return;
    }

    if (currentStepIndex < totalSteps - 1) {
      _currentStep = SetupStep.values[currentStepIndex + 1];
      _errorMessage = null;
      _notify();
    }
  }

  String get currentRoutePath {
    switch (_currentStep) {
      case SetupStep.gender:
        return '/setup';
      case SetupStep.age:
        return '/setup/age';
      case SetupStep.height:
        return '/setup/height';
      case SetupStep.weight:
        return '/setup/weight';
      case SetupStep.goal:
        return '/setup/goal';
      case SetupStep.activity:
        return '/setup/activity';
      case SetupStep.experience:
        return '/setup/experience';
      case SetupStep.location:
        return '/setup/location';
      case SetupStep.workoutDays:
        return '/setup/workout-days';
      case SetupStep.createAccount:
        return '/create-account';
    }
  }

  void previousStep() {
    if (canGoPrevious) {
      _currentStep = SetupStep.values[currentStepIndex - 1];
      _errorMessage = null;
      _notify();
    }
  }

  void goToStep(SetupStep step) {
    _currentStep = step;
    _errorMessage = null;
    _notify();
  }

  bool _hasValidAnswerForCurrentStep() {
    switch (_currentStep) {
      case SetupStep.gender:
        return gender != null && gender!.isNotEmpty;
      case SetupStep.age:
        return age != null && age! >= 13 && age! <= 120;
      case SetupStep.height:
        return height != null && height! >= 100 && height! <= 250;
      case SetupStep.weight:
        return weight != null && weight! >= 30 && weight! <= 300;
      case SetupStep.goal:
        return goal != null && goal!.isNotEmpty;
      case SetupStep.activity:
        return activity != null && activity!.isNotEmpty;
      case SetupStep.experience:
        return experience != null && experience!.isNotEmpty;
      case SetupStep.location:
        return location != null && location!.isNotEmpty;
      case SetupStep.workoutDays:
        return workoutDays != null && workoutDays!.isNotEmpty;
      case SetupStep.createAccount:
        return true;
    }
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  void reset() {
    _currentStep = SetupStep.gender;
    _answers.clear();
    _errorMessage = null;
    _isLoading = false;
    _notify();
  }

  /// Builds the complete registration body with exact backend field names and
  /// types. The caller (screen) should merge `name`, `email`, `password` into
  /// the returned map before passing it to [AuthProvider.register].
  Map<String, dynamic> getRegistrationBody() {
    return {
      'age': age ?? 0,
      'gender': _mapGender(gender),
      'height': height ?? 0.0,
      'weight': weight ?? 0.0,
      'fitnessGoal': _mapFitnessGoal(goal),
      'activityLevel': _mapActivityLevel(activity),
      'experienceLevel': _mapExperienceLevel(experience),
      'workoutLocation': _mapWorkoutLocation(location),
      'workoutDays': workoutDays?.first ?? 4,
    };
  }

  /// Backward-compat alias; prefer [getRegistrationBody].
  Map<String, dynamic> getSetupData() => getRegistrationBody();

  // ── Mapping helpers ────────────────────────────────────────────────────────

  String _mapGender(String? value) {
    switch (value?.toLowerCase()) {
      case 'female':
        return 'Female';
      default:
        return 'Male';
    }
  }

  String _mapFitnessGoal(String? value) {
    switch (value) {
      case 'lose_weight':
        return 'LoseWeight';
      case 'build_muscle':
        return 'BuildMuscle';
      case 'stay_fit':
        return 'StayFit';
      case 'improve_endurance':
        return 'Endurance';
      default:
        return 'BuildMuscle';
    }
  }

  /// Maps the string stored by [ActivityLevelScreen] → backend int 1-5.
  int _mapActivityLevel(String? value) {
    const map = {
      'sedentary': 1,
      'lightly_active': 2,
      'moderately_active': 3,
      'very_active': 4,
      'extra_active': 5,
    };
    return map[value] ?? 1;
  }

  /// Maps the string stored by [ExperienceSelectionScreen] → backend int 1-5.
  int _mapExperienceLevel(String? value) {
    const map = {
      'beginner': 1,
      'novice': 2,
      'intermediate': 3,
      'advanced': 4,
      'expert': 5,
    };
    return map[value] ?? 1;
  }

  /// Maps the string stored by [WorkoutLocationScreen] → backend int 1-4.
  int _mapWorkoutLocation(String? value) {
    const map = {'home': 1, 'gym': 2, 'outdoor': 3, 'anywhere': 4};
    return map[value] ?? 1;
  }

  Future<bool> completeSetup() async {
    if (!_hasValidAnswerForCurrentStep()) {
      _errorMessage = 'Please complete all steps';
      _notify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _notify();

    try {
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      _notify();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save setup. Please try again.';
      _isLoading = false;
      _notify();
      return false;
    }
  }

  // ── Lifecycle guard ───────────────────────────────────────────────────────

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// ✓ Enhanced: Added _disposed guard and _notify() wrapper to all notifyListeners calls
