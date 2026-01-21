import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';
import '../utils/allowed_users.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  Employee? _user;
  bool _isLoading = false;
  String? _error;

  Employee? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AppLogger.info('AuthProvider: Attempting login', {'email': email});
      final result = await _authService.login(email, password);

      if (result['success']) {
        final user = result['user'] as Employee;

        // Detect if user is an admin
        bool userIsAdmin =
            user.employeeId == 'QWIT-1001' ||
            (user.role?.toLowerCase() == 'admin');

        // 1. Check strict email allowlist or mobile access
        // Admins and specifically allowed emails OR users with mobile access enabled are allowed
        final emailLower = user.email.toLowerCase();
        final isAllowedEmail = AllowedUsers.emails.any(
          (e) => e.toLowerCase() == emailLower,
        );

        if (!userIsAdmin &&
            !isAllowedEmail &&
            user.mobileAccessEnabled != true) {
          _error =
              'Unauthorized Access: Your account is not on the authorized users list and mobile access is not enabled. Please contact your administrator.';
          _isLoading = false;
          AppLogger.warning(
            'AuthProvider: Access denied (not in allowlist and no mobile access)',
            {'email': user.email, 'employeeId': user.employeeId},
          );
          notifyListeners();
          return false;
        }

        // 2. Check for mobile access if on mobile platform (redundant but kept for specific error message)
        if (!userIsAdmin &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          if (user.mobileAccessEnabled != true) {
            _error =
                'Mobile Access Unauthorized: Your account does not have mobile access enabled. Please contact your administrator.';
            _isLoading = false;
            AppLogger.warning('AuthProvider: Mobile access denied', {
              'employeeId': user.employeeId,
            });
            notifyListeners();
            return false;
          }
        }

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
        _error = result['message'] ?? 'Login failed';
        _isLoading = false;
        AppLogger.warning('AuthProvider: Login failed', {'error': _error});
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      _error = e.toString();
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
  bool get isAdmin =>
      _user?.employeeId == 'QWIT-1001' || _user?.role?.toLowerCase() == 'admin';

  // Check if user has employee role
  bool get isEmployee => _user?.employeeId != 'QWIT-1001';

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
