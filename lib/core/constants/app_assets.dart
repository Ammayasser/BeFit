// lib/core/constants/app_assets.dart

/// Centralized asset path constants. No other file should contain
/// raw asset path strings.
class AppAssets {
  AppAssets._();

  // ── Images ──────────────────────────────────────────────────────────────────
  static const String male   = 'assets/images/male.png';
  static const String female = 'assets/images/female.png';

  // ── Onboarding ──────────────────────────────────────────────────────────────
  static const String onboarding1 = 'assets/images/onboarding/Fitness tracker-amico.png';
  static const String onboarding2 = 'assets/images/onboarding/Fitness tracker-bro.png';
  static const String onboarding3 = 'assets/images/onboarding/Game analytics-bro.png';
  static const String createAccountBg = 'assets/images/onboarding/create-account.jpg';

  // ── Fitness Goals ───────────────────────────────────────────────────────────
  static const String goalLoseWeight       = 'assets/images/fitness_goal/lose-weight.png';
  static const String goalBuildMuscle      = 'assets/images/fitness_goal/build-muscle.png';
  static const String goalGetFit           = 'assets/images/fitness_goal/get-fit.png';
  static const String goalImproveEndurance = 'assets/images/fitness_goal/improve-endurance.png';

  // ── Activity Level ──────────────────────────────────────────────────────────
  static const String actSedentary       = 'assets/images/activity-level/sedentary.png';
  static const String actLightlyActive   = 'assets/images/activity-level/lightly-active.png';
  static const String actModeratelyActive = 'assets/images/activity-level/moderatly-active.png';
  static const String actVeryActive      = 'assets/images/activity-level/very-active.png';
  static const String actExtraActive     = 'assets/images/activity-level/extra-active.png';

  // ── Experience ──────────────────────────────────────────────────────────────
  // (add paths here when experience images are added)

  // ── Location ────────────────────────────────────────────────────────────────
  // (add paths here when location images are added)
}
// ✓ Enhanced: Centralized all asset path strings into a single constants file
