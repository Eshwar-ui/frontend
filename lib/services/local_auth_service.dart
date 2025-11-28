import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LocalAuthService {
  // ignore: prefer_const_constructors
  final LocalAuthentication _localAuth = LocalAuthentication();
  // ignore: prefer_const_constructors
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _deviceLockEnabledKey = 'device_lock_enabled';

  // Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric availability: $e');
      return false;
    }
  }

  // Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: $e');
      return [];
    }
  }

  // Authenticate with native system authentication (biometrics or device credentials)
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device PIN/password fallback
          useErrorDialogs: true,
        ),
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error authenticating with biometrics: $e');
      return false;
    }
  }

  // Enable/Disable device lock
  Future<void> setDeviceLockEnabled(bool enabled) async {
    await _secureStorage.write(
      key: _deviceLockEnabledKey,
      value: enabled.toString(),
    );
  }

  // Check if device lock is enabled
  Future<bool> isDeviceLockEnabled() async {
    final value = await _secureStorage.read(key: _deviceLockEnabledKey);
    return value == 'true';
  }

  // Clear all authentication data
  Future<void> clearAllAuthData() async {
    await _secureStorage.deleteAll();
  }
}
