import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

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
      print('AuthProvider: Attempting login for $email');
      final result = await _authService.login(email, password);
      
      if (result['success']) {
        _user = result['user'];
        _isLoading = false;
        print('AuthProvider: Login successful for ${_user?.fullName}');
        notifyListeners();
        return true;
      } else {
        _error = result['message'] ?? 'Login failed';
        _isLoading = false;
        print('AuthProvider: Login failed - $_error');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('AuthProvider: Login exception - $_error');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      print('AuthProvider: Logging out user');
      await _authService.logout();
      _user = null;
      _error = null;
      notifyListeners();
      print('AuthProvider: Logout successful');
    } catch (e) {
      print('AuthProvider: Logout error - $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String newPassword, {
    String? currentPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('AuthProvider: Attempting password change');
      final result = await _authService.changePassword(newPassword, currentPassword: currentPassword);
      _isLoading = false;
      print('AuthProvider: Password change result - $result');
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('AuthProvider: Password change error - $_error');
      notifyListeners();
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set user (useful for initializing from stored data)
  void setUser(Employee user) {
    _user = user;
    print('AuthProvider: User set to ${user.fullName}');
    notifyListeners();
  }

  // Get current user info
  Employee? getCurrentUser() {
    return _user;
  }

  // Check if user has admin role (including HR)
  bool get isAdmin => _user?.role == 'admin' || _user?.role == 'hr';

  // Check if user has HR role  
  bool get isHR => _user?.role == 'hr';

  // Check if user has employee role
  bool get isEmployee => _user?.role == 'employee';

  // Check if user has admin privileges (admin or HR)
  bool get hasAdminPrivileges => isAdmin;

  // Debug method to print current state
  void debugPrintState() {
    print('AuthProvider State:');
    print('  User: ${_user?.fullName ?? 'None'}');
    print('  Role: ${_user?.role ?? 'None'}');
    print('  IsLoading: $_isLoading');
    print('  Error: $_error');
    print('  IsLoggedIn: $isLoggedIn');
  }
}
