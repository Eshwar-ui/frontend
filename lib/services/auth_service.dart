import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'employee_service.dart';
import '../utils/app_logger.dart';

class AuthService extends ApiService {
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final headers = await getHeaders();
      final requestBody = json.encode({'email': email, 'password': password});

      final response = await sendRequest(
        http.post(
          Uri.parse('${ApiService.baseUrl}/auth/login'),
          headers: headers,
          body: requestBody,
        ),
      );

      final data = handleResponse(response);

      AppLogger.info('AuthService: Login response received', {
        'hasToken': data['token'] != null,
        'empType': data['empType'],
      });

      if (data['token'] != null) {
        await storeToken(data['token']);
        AppLogger.info('AuthService: Token stored successfully');
        // Verify token was stored
        final storedToken = await getToken();
        AppLogger.debug('AuthService: Token verification', {
          'stored': storedToken != null && storedToken.isNotEmpty,
        });
        try {
          // Fetch complete employee data using the individual employee API
          final payload = data['payload'];
          final employeeId =
              payload is Map ? payload['employeeId']?.toString() : null;
          if (employeeId == null || employeeId.isEmpty) {
            throw Exception(
              'Login succeeded but user payload is missing employee ID.',
            );
          }
          final employeeService = EmployeeService();
          final user = await employeeService.getEmployee(employeeId);
          AppLogger.info('AuthService: Successfully fetched Employee object', {
            'fullName': user.fullName,
            'employeeId': employeeId,
          });
          return {
            'success': true,
            'user': user,
            'token': data['token'],
            'empType': data['empType'],
          };
        } catch (e, stackTrace) {
          AppLogger.error(
            'AuthService: Error fetching Employee data',
            e,
            stackTrace,
          );
          throw Exception('Failed to fetch user data: $e');
        }
      }

      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    } catch (e) {
      rethrow;
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
    String employeeId,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await sendRequest(
        http.put(
          Uri.parse('${ApiService.baseUrl}/api/changepassword/$employeeId'),
          headers: await getHeaders(),
          body: json.encode({
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          }),
        ),
      );

      final data = handleResponse(response);
      AppLogger.info('AuthService: Password changed successfully');
      return {'success': true, 'message': data.toString()};
    } catch (e, stackTrace) {
      AppLogger.error('AuthService: Error changing password', e, stackTrace);
      return {'success': false, 'message': e.toString()};
    }
  }

  // Admin reset employee password
  Future<Map<String, dynamic>> adminResetPassword(
    String employeeId,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      final response = await sendRequest(
        http.put(
          Uri.parse('${ApiService.baseUrl}/api/changepassword/$employeeId'),
          headers: await getHeaders(),
          body: json.encode({
            'newPassword': newPassword,
            'confirmPassword': confirmPassword,
          }),
        ),
      );

      final data = handleResponse(response);
      AppLogger.info('AuthService: Admin reset password successful', {
        'employeeId': employeeId,
      });
      return {'success': true, 'message': data.toString()};
    } catch (e, stackTrace) {
      AppLogger.error(
        'AuthService: Error resetting employee password',
        e,
        stackTrace,
      );
      return {'success': false, 'message': e.toString()};
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
