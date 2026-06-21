// lib/core/utils/token_helper.dart

import '../services/token_service.dart';

/// Convenience mixin/helper to fetch the stored JWT token.
/// Used by screens that need to pass the token to providers.
///
/// Usage:
///   final token = await TokenHelper.getToken();
///   if (token == null) return; // not authenticated
class TokenHelper {
  TokenHelper._();

  /// Returns the stored JWT or null if the user is not authenticated.
  static Future<String?> getToken() => TokenService.instance.getToken();
}
