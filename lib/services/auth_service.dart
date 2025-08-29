import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'api_service.dart';

class AuthService extends ApiService {
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final headers = await getHeaders();
      final requestBody = json.encode({'email': email, 'password': password});
      
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/auth/login'),
        headers: headers,
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please check your internet connection and try again.');
        },
      );
      
      final data = handleResponse(response);

      if (data['success']) {
        await storeToken(data['token']);
        return {
          'success': true,
          'user': Employee.fromJson(data['user']),
          'token': data['token'],
        };
      }
      
      return data;
    } catch (e) {
      rethrow;
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/api/auth/change-password'),
        headers: await getHeaders(),
        body: json.encode({
          'newPassword': newPassword,
        }),
      );

      final data = handleResponse(response);
      return {
        'success': true,
        'message': data['message'] ?? 'Password changed successfully',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Logout
  Future<void> logout() async {
    await removeToken();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
