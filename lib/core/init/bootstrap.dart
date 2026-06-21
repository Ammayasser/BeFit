import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Bootstrap {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _runMigrations();
  }

  static Future<void> _runMigrations() async {
    // One-time migration: clear stale onboarding flag so the full
    // Splash → Onboarding flow can be tested without uninstalling.
    final prefs = await SharedPreferences.getInstance();
    final migrationDone = prefs.getBool('_migration_v3_done') ?? false;
    if (!migrationDone) {
      await prefs.remove('has_seen_onboarding');
      await prefs.setBool('_migration_v3_done', true);
    }
  }
}
