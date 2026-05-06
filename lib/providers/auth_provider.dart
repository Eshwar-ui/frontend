import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';
import '../utils/server_error_exception.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  Employee? _user;
  bool _isLoading = false;
  String? _error;

  Employee? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  String _mapLoginErrorMessage(dynamic error) {
    final rawMessage = error is ServerErrorException
        ? error.message
        : (error?.toString() ?? '');
    final message = rawMessage.toLowerCase();
    final statusCode = error is ServerErrorException ? error.statusCode : null;

    if (statusCode == 400 ||
        statusCode == 401 ||
        message.contains('invalid email') ||
        message.contains('invalid password') ||
        message.contains('invalid credentials') ||
        message.contains('email address or password')) {
      return 'Invalid email or password.';
    }

    if (message.contains('organization')) {
      return rawMessage
          .replaceFirst('ServerErrorException: ', '')
          .replaceFirst(RegExp(r'\s*\(Status:\s*\d+\)\s*$'), '')
          .trim();
    }

    if (message.contains('timeout') ||
        message.contains('socket') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('failed host lookup')) {
      return 'Unable to connect right now. Please check your internet connection and try again.';
    }

    if (statusCode == 403 ||
        message.contains('403') ||
        message.contains('forbidden') ||
        message.contains('access denied')) {
      return 'Your account does not have permission to sign in on this app.';
    }

    if ((statusCode != null && statusCode >= 500) ||
        message.contains('500') ||
        message.contains('502') ||
        message.contains('503') ||
        message.contains('server')) {
      return 'Server is temporarily unavailable. Please try again in a few minutes.';
    }

    return 'Login failed. Please try again.';
  }

  Future<bool> login(
    String organizationName,
    String email,
    String password,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('AuthProvider: Attempting login', {'email': email});
      final result = await _authService.login(
        organizationName,
        email,
        password,
      );

      if (result['success']) {
        final user = result['user'] as Employee;

        _user = user;
        _isLoading = false;
        AppLogger.info('AuthProvider: Login successful', {
          'fullName': _user?.fullName,
          'employeeId': _user?.employeeId,
          'role': _user?.role,
        });
        notifyListeners();
        return true;
      } else {
        _error = _mapLoginErrorMessage(result['message']);
        _isLoading = false;
        AppLogger.warning('AuthProvider: Login failed', {'error': _error});
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = _mapLoginErrorMessage(e);
      _isLoading = false;
      AppLogger.error('AuthProvider: Login exception', e, stackTrace);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      AppLogger.info('AuthProvider: Logging out user');
      await _authService.logout();
      _user = null;
      _error = null;
      notifyListeners();
      AppLogger.info('AuthProvider: Logout successful');
    } catch (e, stackTrace) {
      AppLogger.error('AuthProvider: Logout error', e, stackTrace);
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String employeeId,
    String newPassword,
    String confirmPassword,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('AuthProvider: Attempting password change', {
        'employeeId': employeeId,
      });
      final result = await _authService.changePassword(
        employeeId,
        newPassword,
        confirmPassword,
      );
      _isLoading = false;
      AppLogger.info('AuthProvider: Password change result', result);
      notifyListeners();
      return result;
    } catch (e, stackTrace) {
      _error = e.toString();
      _isLoading = false;
      AppLogger.error('AuthProvider: Password change error', e, stackTrace);
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> adminResetPassword(
    String employeeId,
    String newPassword,
    String confirmPassword,
  ) async {
    if (!isAdmin) {
      return {
        'success': false,
        'message': 'Only administrators can reset employee passwords.',
      };
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('AuthProvider: Attempting admin password reset', {
        'employeeId': employeeId,
      });
      final result = await _authService.adminResetPassword(
        employeeId,
        newPassword,
        confirmPassword,
      );
      _isLoading = false;
      AppLogger.info('AuthProvider: Admin password reset result', {
        'employeeId': employeeId,
        'success': result['success'] == true,
      });
      notifyListeners();
      return result;
    } catch (e, stackTrace) {
      _error = e.toString();
      _isLoading = false;
      AppLogger.error(
        'AuthProvider: Admin password reset error',
        e,
        stackTrace,
      );
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set user (useful for initializing from stored data)
  void setUser(Employee user) {
    _user = user;
    AppLogger.debug('AuthProvider: User set', {
      'fullName': user.fullName,
      'employeeId': user.employeeId,
    });
    notifyListeners();
  }

  // Get current user info
  Employee? getCurrentUser() {
    return _user;
  }

  // Check if user has admin role
  bool get isAdmin => _user?.role?.toLowerCase() == 'admin';

  bool get isHr => _user?.role?.toLowerCase() == 'hr';

  bool get isAdminOrHr => isAdmin || isHr;

  // Check if user has employee role
  bool get isEmployee => _user != null && !isAdmin && !isHr;

  // Check if user has admin privileges
  bool get hasAdminPrivileges => isAdmin;

  // Debug method to print current state
  void debugPrintState() {
    AppLogger.debug('AuthProvider State', {
      'user': _user?.fullName ?? 'None',
      'role': _user?.role ?? 'None',
      'employeeId': _user?.employeeId ?? 'None',
      'isLoading': _isLoading,
      'error': _error,
      'isLoggedIn': isLoggedIn,
    });
  }
}
