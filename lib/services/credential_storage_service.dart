import 'package:shared_preferences/shared_preferences.dart';

class CredentialStorageService {
  static const String _emailKey = 'saved_email';
  static const String _passwordKey = 'saved_password';
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginKey = 'last_login';

  // Save credentials
  static Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      await prefs.setString(_emailKey, email);
      await prefs.setString(_passwordKey, password);
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
    } else {
      await clearCredentials();
    }
  }

  // Load saved credentials
  static Future<Map<String, dynamic>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    final lastLogin = prefs.getString(_lastLoginKey);
    
    if (email != null && password != null && rememberMe) {
      return {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
        'lastLogin': lastLogin != null ? DateTime.parse(lastLogin) : null,
      };
    }
    
    return null;
  }

  // Check if credentials exist
  static Future<bool> hasSavedCredentials() async {
    final credentials = await getSavedCredentials();
    return credentials != null;
  }

  // Clear saved credentials
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_passwordKey);
    await prefs.remove(_rememberMeKey);
    await prefs.remove(_lastLoginKey);
  }

  // Get last login time
  static Future<DateTime?> getLastLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLogin = prefs.getString(_lastLoginKey);
    return lastLogin != null ? DateTime.parse(lastLogin) : null;
  }

  // Check if credentials are recent (within 30 days)
  static Future<bool> areCredentialsRecent() async {
    final lastLogin = await getLastLoginTime();
    if (lastLogin == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(lastLogin).inDays;
    return difference <= 30; // Credentials are valid for 30 days
  }
}
