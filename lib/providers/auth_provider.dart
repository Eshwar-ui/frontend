import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_logger.dart';

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

    // // Bypass login for admin
    // if (email == 'admin@quantumworks.in') {
    //   _user = Employee(
    //     id: 'mock_admin_id',
    //     employeeId: 'QWIT-1001',
    //     firstName: 'Admin',
    //     lastName: 'User',
    //     email: email,
    //     mobile: '0000000000',
    //     dateOfBirth: DateTime.now(),
    //     joiningDate: DateTime.now(),
    //     password: 'password',
    //     profileImage: '',
    //     role: 'Admin',
    //     department: 'IT',
    //     designation: 'Administrator',
    //   );
    //   _isLoading = false;
    //   print('AuthProvider: Admin login bypass successful');
    //   notifyListeners();
    //   return true;
    // }

    try {
      AppLogger.info('AuthProvider: Attempting login', {'email': email});
      final result = await _authService.login(email, password);

      if (result['success']) {
        _user = result['user'];
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

  // Check if user has admin role (QWIT-1001 is admin)
  bool get isAdmin => _user?.employeeId == 'QWIT-1001';

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
