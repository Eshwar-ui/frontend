import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';

class ApiService {
  // Get the base URL from NetworkConfig
  static String get baseUrl => NetworkConfig.baseUrl;

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Store token
  Future<void> storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Remove token
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Get headers with authorization
  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  dynamic handleResponse(http.Response response) {
    print('API Response Status: ${response.statusCode}');
    print('API Response Body: ${response.body}');
    print('API Response Headers: ${response.headers}');

    try {
      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        final errorMessage = data is Map
            ? data['message'] ?? 'Error: HTTP ${response.statusCode}'
            : 'Error: HTTP ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is FormatException) {
        print('Failed to parse response body as JSON: ${response.body}');
        throw Exception(
          'Invalid response format. Server returned: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}',
        );
      }
      rethrow;
    }
  }
}
