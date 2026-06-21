// lib/features/auth/data/services/auth_service.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';

/// Handles raw HTTP communication with the BeFit authentication API.
///
/// Design rules:
/// - Every request carries `Content-Type: application/json`.
/// - Every request has a 10-second timeout.
/// - Token persistence is NOT done here — the Provider owns that concern.
/// - Return type is always `Map<String, dynamic>` shaped as:
///   `{ 'success': bool, 'data': ..., 'message': String? }`.
class AuthService {
  static const Duration _timeout = Duration(seconds: 10);

  // ── register ──────────────────────────────────────────────────────────────

  /// Registers a new user.
  ///
  /// [body] must contain the exact backend field names:
  /// name, email, password, age, gender, height, weight,
  /// fitnessGoal, activityLevel, experienceLevel, workoutLocation, workoutDays.
  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.register),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'data': {
            'token': data['token'],
            'name':  data['name'],
            'email': data['email'],
          },
        };
      }

      if (response.statusCode == 400) {
        return {
          'success': false,
          'message': _extractErrorMessage(
            response.body,
            fallback: 'Registration failed. Please check your details.',
          ),
        };
      }

      return {
        'success': false,
        'message': 'Our servers are having a bit of trouble. Please try again in a moment.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Check your connection.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network settings.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Unexpected error. Please try again.',
      };
    }
  }

  // ── login ─────────────────────────────────────────────────────────────────

  /// Authenticates an existing user and returns a token on success.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'success': true,
          'data': {
            'token': data['token'],
            'name':  data['name'],
            'email': data['email'],
          },
        };
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Incorrect email or password.',
        };
      }

      if (response.statusCode == 400) {
        return {
          'success': false,
          'message': _extractErrorMessage(
            response.body,
            fallback: 'Login failed. Please check your details.',
          ),
        };
      }

      return {
        'success': false,
        'message': 'Our servers are having a bit of trouble. Please try again in a moment.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Check your connection.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network settings.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Unexpected error. Please try again.',
      };
    }
  }

  // ── getMe ─────────────────────────────────────────────────────────────────

  /// Fetches the authenticated user's full profile.
  Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConstants.me),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {'success': true, 'data': data};
      }

      if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please log in again.',
          'code': 401,
        };
      }

      return {
        'success': false,
        'message': 'Our servers are having a bit of trouble. Please try again in a moment.',
      };
    } on TimeoutException {
      return {
        'success': false,
        'message': 'Request timed out. Check your connection.',
      };
    } on SocketException {
      return {
        'success': false,
        'message': 'No internet connection. Please check your network settings.',
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Unexpected error. Please try again.',
      };
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /// Attempts to extract a human-readable message from the backend error body.
  String _extractErrorMessage(String body, {required String fallback}) {
    // Handle plain-text responses (e.g. "Email already in use.")
    final trimmed = body.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      return trimmed.isNotEmpty ? trimmed : fallback;
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        // ASP.NET validation errors shape: { "errors": { "field": ["msg"] } }
        // Check this FIRST — the "title" key contains a generic summary
        // like "One or more validation errors occurred" which is useless.
        final errors = decoded['errors'];
        if (errors is Map) {
          final allMessages = <String>[];
          for (final entry in errors.entries) {
            final v = entry.value;
            if (v is List && v.isNotEmpty) {
              allMessages.addAll(v.map((e) => e.toString()));
            } else if (v is String && v.isNotEmpty) {
              allMessages.add(v);
            }
          }
          if (allMessages.isNotEmpty) return allMessages.join('; ');
        }
        // Try common keys the backend might use
        for (final key in ['message', 'error', 'detail']) {
          final value = decoded[key];
          if (value is String && value.isNotEmpty) return value;
        }
      }
    } catch (_) {}
    return fallback;
  }
}
