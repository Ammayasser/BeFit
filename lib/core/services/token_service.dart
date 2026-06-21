// lib/core/services/token_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that owns the lifecycle of the JWT and the onboarding flag.
/// All operations are try/caught — callers never receive an exception.
class TokenService {
  TokenService._();
  static final TokenService instance = TokenService._();

  // ── Keys ─────────────────────────────────────────────────────────────────
  static const String _tokenKey      = 'auth_token';
  static const String _userIdKey     = 'auth_user_id';
  static const String _onboardingKey = 'has_seen_onboarding';

  // ── JWT ───────────────────────────────────────────────────────────────────

  /// Persists the JWT received from the server.
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (_) {}
  }

  /// Persists the user ID.
  Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
    } catch (_) {}
  }

  /// Returns the stored user ID.
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (_) {
      return null;
    }
  }

  /// Removes the user ID from storage.
  Future<void> deleteUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    } catch (_) {}
  }

  /// Returns the stored JWT, or `null` if none is saved.
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Removes the JWT from storage (used on logout).
  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } catch (_) {}
  }

  /// Returns `true` if a non-empty token exists in storage.
  Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ── Onboarding flag ───────────────────────────────────────────────────────

  /// Marks that the user has seen the onboarding screens.
  Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {}
  }

  /// Returns `true` if the user has already seen the onboarding screens.
  Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Aliases kept for backward compatibility ────────────────────────────────
  Future<void> clearToken() => deleteToken();
  Future<bool> hasCompletedOnboarding() => hasSeenOnboarding();
  Future<void> clearOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingKey);
    } catch (_) {}
  }

  /// Wipes all persisted auth data (JWT + onboarding flag).
  Future<void> clearAll() async {
    await deleteToken();
    await clearOnboarding();
  }
}
