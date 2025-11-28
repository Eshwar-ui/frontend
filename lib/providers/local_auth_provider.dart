import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import '../services/local_auth_service.dart';

class LocalAuthProvider with ChangeNotifier {
  final LocalAuthService _authService = LocalAuthService();

  bool _isDeviceLockEnabled = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isAuthenticated = false;

  bool get isDeviceLockEnabled => _isDeviceLockEnabled;
  bool get isBiometricAvailable => _isBiometricAvailable;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  bool get isAuthenticated => _isAuthenticated;

  LocalAuthProvider() {
    _init();
  }

  Future<void> _init() async {
    await checkDeviceLockStatus();
    await checkBiometricAvailability();
  }

  // Check if device lock is enabled
  Future<void> checkDeviceLockStatus() async {
    _isDeviceLockEnabled = await _authService.isDeviceLockEnabled();
    notifyListeners();
  }

  // Check biometric availability
  Future<void> checkBiometricAvailability() async {
    _isBiometricAvailable = await _authService.isBiometricAvailable();
    _availableBiometrics = await _authService.getAvailableBiometrics();
    notifyListeners();
  }

  // Set device lock flag (uses native system authentication)
  Future<void> setDeviceLockEnabled(bool enabled) async {
    try {
      await _authService.setDeviceLockEnabled(enabled);
      _isDeviceLockEnabled = enabled;
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting device lock: $e');
    }
  }

  // Disable device lock
  Future<void> disableDeviceLock() async {
    try {
      await _authService.setDeviceLockEnabled(false);
      _isDeviceLockEnabled = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error disabling device lock: $e');
    }
  }

  // Authenticate with native system authentication
  Future<bool> authenticateWithBiometrics() async {
    try {
      final authenticated = await _authService.authenticateWithBiometrics();
      if (authenticated) {
        _isAuthenticated = true;
        notifyListeners();
      }
      return authenticated;
    } catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  // Reset authentication state (e.g., when app goes to background)
  void resetAuthState() {
    _isAuthenticated = false;
    notifyListeners();
  }

  // Get biometric icon name
  String getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return 'Iris';
    }
    return 'Biometric';
  }
}
