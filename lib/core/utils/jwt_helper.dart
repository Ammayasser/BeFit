import 'dart:convert';

class JwtHelper {
  static String? extractUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = json.decode(decoded) as Map<String, dynamic>;
      // Try common JWT claims for user ID
      return (map['sub'] ?? map['userId'] ?? map['id'] ?? map['nameid'])?.toString();
    } catch (_) {
      return null;
    }
  }
}
