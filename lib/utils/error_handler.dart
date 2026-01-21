import 'package:flutter/material.dart';
import 'package:quantum_dashboard/utils/server_error_exception.dart';
import 'package:quantum_dashboard/utils/snackbar_utils.dart';

/// Error categories
enum ErrorCategory {
  validation,
  network,
  server,
  notFound,
  permission,
  authentication,
  unknown,
}

/// Centralized error handler for transforming and displaying user-friendly error messages
class ErrorHandler {

  /// Extract user-friendly error message from various error types
  static String getErrorMessage(dynamic error) {
    if (error == null) {
      return "An unexpected error occurred. Please try again.";
    }

    // Handle ServerErrorException
    if (error is ServerErrorException) {
      return _extractMessageFromServerError(error.message);
    }

    // Handle String errors
    if (error is String) {
      return _extractMessageFromString(error);
    }

    // Handle Exception
    if (error is Exception) {
      final message = error.toString();
      return _extractMessageFromString(message);
    }

    // Fallback
    return "Something went wrong. Please try again.";
  }

  /// Extract message from server error response
  static String _extractMessageFromServerError(String errorMessage) {
    // Remove common prefixes
    String message = errorMessage;
    
    // Remove "Exception: " prefix if present
    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }
    
    // Remove "ServerErrorException: " prefix if present
    if (message.startsWith('ServerErrorException: ')) {
      message = message.substring('ServerErrorException: '.length);
    }
    
    // Remove status code suffix if present
    final statusMatch = RegExp(r'\s*\(Status:\s*\d+\)').firstMatch(message);
    if (statusMatch != null) {
      message = message.substring(0, statusMatch.start).trim();
    }
    
    return message.isNotEmpty ? message : "An error occurred. Please try again.";
  }

  /// Extract message from string error
  static String _extractMessageFromString(String error) {
    // Remove common prefixes
    String message = error;
    
    if (message.startsWith('Exception: ')) {
      message = message.substring('Exception: '.length);
    }
    
    // Handle generic error messages
    final genericPatterns = [
      RegExp(r'^Error:\s*HTTP\s*\d+', caseSensitive: false),
      RegExp(r'^Bad Request\s*\(400\)', caseSensitive: false),
      RegExp(r'^Internal Server Error\s*\(500\)', caseSensitive: false),
    ];
    
    for (var pattern in genericPatterns) {
      if (pattern.hasMatch(message)) {
        return "Unable to process your request. Please try again later.";
      }
    }
    
    return message.isNotEmpty ? message : "Something went wrong. Please try again.";
  }

  /// Categorize error for appropriate handling
  static ErrorCategory categorizeError(dynamic error) {
    final message = getErrorMessage(error).toLowerCase();
    
    if (error is ServerErrorException) {
      final statusCode = error.statusCode;
      if (statusCode == 401) return ErrorCategory.authentication;
      if (statusCode == 403) return ErrorCategory.permission;
      if (statusCode == 404) return ErrorCategory.notFound;
      if (statusCode == 400 || statusCode == 422) return ErrorCategory.validation;
      if (statusCode >= 500) return ErrorCategory.server;
    }
    
    // Check message content
    if (message.contains('network') || 
        message.contains('connection') || 
        message.contains('timeout') ||
        message.contains('internet')) {
      return ErrorCategory.network;
    }
    
    if (message.contains('not found') || message.contains('does not exist')) {
      return ErrorCategory.notFound;
    }
    
    if (message.contains('required') || 
        message.contains('invalid') || 
        message.contains('missing')) {
      return ErrorCategory.validation;
    }
    
    if (message.contains('unauthorized') || 
        message.contains('authentication') || 
        message.contains('login')) {
      return ErrorCategory.authentication;
    }
    
    if (message.contains('permission') || 
        message.contains('forbidden') || 
        message.contains('access denied')) {
      return ErrorCategory.permission;
    }
    
    return ErrorCategory.unknown;
  }

  /// Show error with appropriate UI based on category
  static void showError(
    BuildContext context, {
    required dynamic error,
    VoidCallback? onRetry,
    String? customMessage,
  }) {
    final message = customMessage ?? getErrorMessage(error);
    
    switch (categorizeError(error)) {
      case ErrorCategory.network:
        SnackbarUtils.showError(
          context,
          "Network Error: $message\nPlease check your internet connection and try again.",
        );
        break;
        
      case ErrorCategory.validation:
        SnackbarUtils.showError(context, message);
        break;
        
      case ErrorCategory.authentication:
        SnackbarUtils.showError(
          context,
          "Authentication Error: $message\nPlease log in again.",
        );
        break;
        
      case ErrorCategory.permission:
        SnackbarUtils.showError(
          context,
          "Access Denied: $message\nPlease contact your administrator if you believe this is an error.",
        );
        break;
        
      case ErrorCategory.notFound:
        SnackbarUtils.showError(context, message);
        break;
        
      case ErrorCategory.server:
        SnackbarUtils.showError(
          context,
          "Server Error: $message\nPlease try again later or contact support if the problem persists.",
        );
        break;
        
      default:
        SnackbarUtils.showError(context, message);
    }
  }

  /// Show error with retry option
  static void showErrorWithRetry(
    BuildContext context, {
    required dynamic error,
    required VoidCallback onRetry,
    String? customMessage,
  }) {
    final message = customMessage ?? getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: EdgeInsets.all(16),
        elevation: 6,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }
}

