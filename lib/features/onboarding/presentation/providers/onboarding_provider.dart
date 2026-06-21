// lib/features/onboarding/presentation/providers/onboarding_provider.dart

import 'package:flutter/material.dart';

/// Manages onboarding page state (current page, direction).
class OnboardingProvider extends ChangeNotifier {
  bool _disposed = false;
  int _currentPage = 0;
  final PageController pageController = PageController();

  int get currentPage => _currentPage;
  int get totalPages => 3;

  void onPageChanged(int index) {
    _currentPage = index;
    _notify();
  }

  void next() {
    if (_currentPage < totalPages - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void previous() {
    if (_currentPage > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    pageController.dispose();
    super.dispose();
  }
}
