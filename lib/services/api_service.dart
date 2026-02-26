import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/network_config.dart';
import '../utils/server_error_exception.dart';
import '../utils/app_logger.dart';

class ApiService {
  // Get the base URL from NetworkConfig
  static String get baseUrl => NetworkConfig.baseUrl;
  static const Duration _defaultTimeout = Duration(seconds: 30);

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
    final hasToken = token != null && token.isNotEmpty;
    AppLogger.debug('ApiService: Getting headers', {
      'hasToken': hasToken,
      if (hasToken) 'tokenLength': token.length,
    });
    return {
      'Content-Type': 'application/json',
      if (hasToken) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response
  dynamic handleResponse(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final isHtmlResponse =
        contentType.contains('text/html') ||
        response.body.trimLeft().startsWith('<!DOCTYPE html') ||
        response.body.trimLeft().startsWith('<html');

    AppLogger.debug('API Response received', {
      'statusCode': response.statusCode,
      'url': response.request?.url.toString(),
    });
    AppLogger.trace(
      'API Response Body',
      response.body.length > 1000
          ? '${response.body.substring(0, 1000)}... [truncated]'
          : response.body,
    );
    AppLogger.trace('API Response Headers', response.headers);

    // Handle empty body responses
    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return <String, dynamic>{};
      }
      final errorMessage = getDefaultErrorMessage(response.statusCode);
      AppLogger.error(
        'API returned ${response.statusCode} error: $errorMessage',
        null,
      );
      throw ServerErrorException(errorMessage, statusCode: response.statusCode);
    }

    // Check for error status codes
    if (response.statusCode >= 400) {
      String errorMessage = 'An error occurred';

      if (isHtmlResponse) {
        errorMessage = getDefaultErrorMessage(response.statusCode);
        AppLogger.error(
          'API returned ${response.statusCode} HTML error page',
          null,
        );
        throw ServerErrorException(errorMessage, statusCode: response.statusCode);
      }

      // Try to parse error message from response
      try {
        final errorData = json.decode(response.body);

        // Check for 'error' field first (our standardized format)
        if (errorData is Map) {
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          }
        } else if (errorData is String) {
          errorMessage = errorData;
        }
      } catch (e) {
        // If response is not JSON, use the body as string
        errorMessage = response.body.isNotEmpty
            ? response.body
            : getDefaultErrorMessage(response.statusCode);
      }

      AppLogger.error(
        'API returned ${response.statusCode} error: $errorMessage',
        null,
      );
      throw ServerErrorException(errorMessage, statusCode: response.statusCode);
    }

    try {
      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        String errorMessage = 'An error occurred';
        if (data is Map) {
          errorMessage =
              data['error'] ??
              data['message'] ??
              'Error: HTTP ${response.statusCode}';
        } else {
          errorMessage = 'Error: HTTP ${response.statusCode}';
        }
        throw ServerErrorException(
          errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Don't wrap ServerErrorException
      if (e is ServerErrorException) {
        rethrow;
      }
      if (e is FormatException) {
        AppLogger.error('Failed to parse response body as JSON', {
          'responseBody': response.body.length > 200
              ? response.body.substring(0, 200) + '...'
              : response.body,
        });
        throw Exception(
          'Invalid response format. Server returned: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}',
        );
      }
      rethrow;
    }
  }

  Future<http.Response> sendRequest(
    Future<http.Response> request, {
    Duration timeout = _defaultTimeout,
  }) async {
    try {
      return await request.timeout(
        timeout,
        onTimeout: () => throw Exception(
          'Connection timeout. Please check your internet connection and try again.',
        ),
      );
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } on TimeoutException {
      throw Exception(
        'Connection timeout. Please check your internet connection and try again.',
      );
    }
  }

  // Helper function to get default error message based on status code
  static String getDefaultErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input and try again.';
      case 401:
        return 'Authentication required. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'A conflict occurred. The resource may already exist.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
