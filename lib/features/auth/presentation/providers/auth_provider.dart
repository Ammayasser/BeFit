// lib/features/auth/presentation/providers/auth_provider.dart

import 'package:flutter/foundation.dart';

import '../../data/services/auth_service.dart';
import '../../../../core/services/token_service.dart';
import '../../../../core/utils/jwt_helper.dart';

// ── Status enum ───────────────────────────────────────────────────────────────

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Manages the authentication lifecycle of the BeFit application.
///
/// Rules:
/// - Token persistence is owned here (via [TokenService]).
/// - [AuthService] only does HTTP — it never touches shared_preferences.
/// - [notifyListeners] is guarded by [_disposed] to prevent post-dispose calls.
/// - The constructor boots [checkAuthStatus] via `Future.microtask` so the
///   widget tree is already built before the first state change.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _disposed = false;

  // ── State ─────────────────────────────────────────────────────────────────
  AuthStatus _status = AuthStatus.initial;
  String?    _errorMessage;
  String?    _userId;
  String?    _userName;
  String?    _userEmail;
  bool       _hasSeenOnboarding = false;

  final List<Future<void> Function()> _logoutCallbacks = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  AuthStatus get status           => _status;
  String?    get errorMessage     => _errorMessage;
  String?    get userId           => _userId;
  String?    get userName         => _userName;
  String?    get userEmail        => _userEmail;
  bool       get isAuthenticated  => _status == AuthStatus.authenticated;
  bool       get hasSeenOnboarding => _hasSeenOnboarding;

  void registerLogoutCallback(Future<void> Function() callback) {
    _logoutCallbacks.add(callback);
  }

  // ── Constructor ───────────────────────────────────────────────────────────
  AuthProvider() {
    Future.microtask(() => checkAuthStatus());
  }

  // ── Lifecycle guard ───────────────────────────────────────────────────────
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  // ── checkAuthStatus ───────────────────────────────────────────────────────

  /// Checks whether a valid token exists in storage.
  /// Called once at startup from the constructor.
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    _notify();

    try {
      // Parallelize I/O operations for faster startup.
      final results = await Future.wait([
        TokenService.instance.hasSeenOnboarding(),
        TokenService.instance.hasToken(),
        TokenService.instance.getUserId(),
      ]);
      _hasSeenOnboarding = (results[0] as bool);
      final hasToken = (results[1] as bool);
      _userId = (results[2] as String?);
      
      _status = hasToken ? AuthStatus.authenticated : AuthStatus.unauthenticated;
      
      if (hasToken) {
        final token = await TokenService.instance.getToken();
        if (token != null) {
          final extractedId = JwtHelper.extractUserId(token);
          if (extractedId != null) {
            _userId = extractedId;
            // Re-save in case it was only in JWT before
            await TokenService.instance.saveUserId(_userId!);
          }
        }
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }

    _notify();
  }

  // ── register ──────────────────────────────────────────────────────────────

  /// Registers a new user.
  ///
  /// [setupData] is the complete Map built by [SetupProvider.getRegistrationBody].
  /// It must contain the exact backend field names.
  Future<void> register(Map<String, dynamic> setupData) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _notify();

    final result = await _authService.register(setupData);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await TokenService.instance.saveToken(token);
      _userId = JwtHelper.extractUserId(token) ?? data['id']?.toString() ?? data['email'] as String?;
      if (_userId != null) {
        await TokenService.instance.saveUserId(_userId!);
      }
      _userName  = data['name']  as String?;
      _userEmail = data['email'] as String?;
      _status    = AuthStatus.authenticated;
    } else {
      _errorMessage = result['message'] as String? ??
          'Registration failed. Please try again.';
      _status = AuthStatus.error;
    }

    _notify();
  }

  // ── login ─────────────────────────────────────────────────────────────────

  /// Authenticates an existing user.
  Future<void> login(String email, String password) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _notify();

    final result = await _authService.login(email, password);

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      await TokenService.instance.saveToken(token);
      _userId = JwtHelper.extractUserId(token) ?? data['id']?.toString() ?? data['email'] as String?;
      if (_userId != null) {
        await TokenService.instance.saveUserId(_userId!);
      }
      _userName  = data['name']  as String?;
      _userEmail = data['email'] as String?;
      _status    = AuthStatus.authenticated;
    } else {
      _errorMessage = result['message'] as String? ??
          'Login failed. Please try again.';
      _status = AuthStatus.error;
    }

    _notify();
  }

  // ── logout ────────────────────────────────────────────────────────────────

  /// Clears the token and resets all user state.
  Future<void> logout() async {
    for (final cb in _logoutCallbacks) {
      await cb();
    }
    await TokenService.instance.deleteToken();
    await TokenService.instance.deleteUserId();
    await TokenService.instance.clearOnboarding();
    _hasSeenOnboarding = false;
    _userId       = null;
    _userName     = null;
    _userEmail    = null;
    _errorMessage = null;
    _status       = AuthStatus.unauthenticated;
    _notify();
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Clears any displayed error, e.g. when the user starts editing a field.
  void clearError() {
    _errorMessage = null;
    _notify();
  }

  /// Marks onboarding as seen in both this provider and [TokenService].
  /// Called by the OnboardingScreen so the router redirect stays in sync.
  Future<void> markOnboardingSeen() async {
    _hasSeenOnboarding = true;
    await TokenService.instance.setOnboardingCompleted();
    _notify();
  }

  /// Forces a UI rebuild without changing state — used by the router listener.
  void forceNavigationUpdate() => _notify();
}
// ✓ Enhanced: Added hasSeenOnboarding getter, microtask auth check, _disposed guard
