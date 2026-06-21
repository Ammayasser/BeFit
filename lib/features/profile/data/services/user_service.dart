// lib/features/profile/data/services/user_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/token_service.dart';

class UserService {
  static const Duration _timeout = Duration(seconds: 10);
  static const String _avatarKey = 'user_avatar_url_override';

  Future<Map<String, dynamic>> getProfile() async {
    final token = await TokenService.instance.getToken();
    if (token == null) {
      return {'success': false, 'message': 'No token found'};
    }

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
        
        // PERSISTENCE FIX: Inject locally saved avatar URL if it exists
        final prefs = await SharedPreferences.getInstance();
        final localAvatar = prefs.getString(_avatarKey);
        if (localAvatar != null) {
          data['avatarUrl'] = localAvatar;
        }

        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': 'Failed to load profile (${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final token = await TokenService.instance.getToken();
    if (token == null) {
      return {'success': false, 'message': 'No token found'};
    }

    try {
      final response = await http
          .put(
            Uri.parse(ApiConstants.me),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        // Some APIs return the updated object, some return 204 No Content
        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return {'success': true, 'data': data};
        }
        return {'success': true};
      }

      return {
        'success': false,
        'message': 'Failed to update profile (${response.statusCode})',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    // Mocking avatar upload for now. 
    // We save the local filePath to SharedPreferences so it persists across restarts.
    await Future.delayed(const Duration(seconds: 1));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_avatarKey, filePath);

    return {'success': true, 'avatarUrl': filePath};
  }
}
