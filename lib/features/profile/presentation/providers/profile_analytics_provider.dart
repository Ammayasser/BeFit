// lib/features/profile/presentation/providers/profile_analytics_provider.dart

import 'package:flutter/foundation.dart';

class ProfileAnalyticsProvider extends ChangeNotifier {
  // ignore: unused_field
  String? _userId;

  void initForUser(String userId) {
    _userId = userId;
    // Load analytics data if any
    notifyListeners();
  }

  void resetForLogout() {
    _userId = null;
    notifyListeners();
  }

  // Add more analytics related methods here (e.g., workout stats, nutrition stats)
}
