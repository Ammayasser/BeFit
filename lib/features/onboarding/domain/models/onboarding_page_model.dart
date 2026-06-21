import 'package:flutter/material.dart';

class OnboardingPageModel {
  final String title;
  final String description;
  final String imagePath;
  final String backgroundImage;
  final String tagLabel;
  final List<String> features;

  /// True for real photographs (BoxFit.cover full-bleed).
  /// False for flat illustrations (BoxFit.contain on dark bg with float).
  final bool isPhoto;

  /// Controls which part of the photo is shown when BoxFit.cover crops it.
  /// Defaults to Alignment.center.
  /// Use Alignment.topCenter if the subject is in the upper half,
  /// Alignment(x, y) for fine-tuned horizontal/vertical bias.
  final Alignment imageAlignment;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.imagePath,
    this.backgroundImage = '',
    this.tagLabel = '',
    this.features = const [],
    this.isPhoto = false,
    this.imageAlignment = Alignment.center,
  });
}

class OnboardingData {
  static const List<OnboardingPageModel> pages = [
    OnboardingPageModel(
      title: 'TRACK YOUR\nEVERY MOVE',
      description:
          'Real-time stats, calorie logs and sleep analysis — your complete performance dashboard, always with you.',
      imagePath: 'assets/images/onboarding/Fitness tracker-amico.jpg',
      tagLabel: 'PERFORMANCE',
      features: ['📊 Live Stats', '🔥 Calorie Log', '💤 Sleep Tracker'],
      isPhoto: true,
      // Priority: Absolute top to show HUD data
      imageAlignment: Alignment(0.0, -1.0),
    ),
    OnboardingPageModel(
      title: 'SMASH YOUR\nFITNESS GOALS',
      description:
          'Personalized workout plans and nutrition guidance that adapt to your progress and lifestyle.',
      imagePath: 'assets/images/onboarding/goals.jpg',
      tagLabel: 'RESULTS DRIVEN',
      features: ['🏋️ Custom Plans', '🥗 Nutrition AI', '⚡ Daily Targets'],
      isPhoto: true,
      // Priority: Runner on the left + his head at the absolute top
      imageAlignment: Alignment(-0.7, -1.0),
    ),
    OnboardingPageModel(
      title: 'YOUR AI\nPERSONAL COACH',
      description:
          'Get smart coaching, form analysis and adaptive plans that evolve as you get stronger every day.',
      imagePath: 'assets/images/onboarding/ai-coach-bike.jpg',
      tagLabel: 'AI POWERED',
      features: ['🤖 Smart Analysis', '📈 Progress IQ', '🎯 Adaptive Plans'],
      isPhoto: true,
      imageAlignment: Alignment.topCenter,
    ),
  ];
}
