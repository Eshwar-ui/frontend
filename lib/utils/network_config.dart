import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io' show Platform;

class NetworkConfig {
  static const String _defaultProductionUrl =
      'https://qw-backend-oymh.onrender.com';
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _configuredDevMachineIp = String.fromEnvironment(
    'API_DEV_MACHINE_IP',
    defaultValue: '192.168.1.34',
  );
  static const int _serverPort = int.fromEnvironment(
    'API_SERVER_PORT',
    defaultValue: 4444,
  );
  static const bool _useProductionBackend = bool.fromEnvironment(
    'USE_PRODUCTION_BACKEND',
    defaultValue: true,
  );

  // Whether the app is using production backend
  static bool get isUsingProduction => _useProductionBackend;
  static String get devMachineIp => _configuredDevMachineIp;
  static int get serverPort => _serverPort;

  // Whether to show development/debug UI elements
  // This should be false in production builds
  static bool get showDebugUI => kDebugMode && !_useProductionBackend;

  // Get the appropriate base URL based on configuration and platform
  static String get baseUrl {
    if (_configuredBaseUrl.trim().isNotEmpty) {
      return _normalizeUrl(_configuredBaseUrl);
    }

    // If using production backend, always return the production URL
    if (_useProductionBackend) {
      return _normalizeUrl(_defaultProductionUrl);
    }

    // Local development configuration
    if (kIsWeb) {
      // Web applications use localhost
      return 'http://localhost:$serverPort';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 (special alias to host loopback)
      // Physical Android devices need your development machine's IP address
      return 'http://$devMachineIp:$serverPort';
    } else if (Platform.isIOS) {
      // iOS simulator uses localhost
      // Physical iOS devices need your development machine's IP address
      return 'http://$devMachineIp:$serverPort';
    } else {
      // Default fallback
      return 'http://localhost:$serverPort';
    }
  }

  // Helper method to switch between production and development
  static String get currentEnvironment =>
      _useProductionBackend ? 'Production' : 'Development';

  static String _normalizeUrl(String value) =>
      value.trim().replaceAll(RegExp(r'/$'), '');
}
