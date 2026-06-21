// lib/core/router/navigation_provider.dart

import 'package:flutter/foundation.dart';

/// Manages the currently selected tab in the bottom navigation bar.
class NavigationProvider extends ChangeNotifier {
  bool _disposed = false;
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      _notify();
    }
  }

  void resetToHome() {
    _currentIndex = 0;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
// ✓ Enhanced: Added _disposed guard and _notify() wrapper
