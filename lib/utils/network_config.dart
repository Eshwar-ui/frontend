import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:io' show Platform;

class NetworkConfig {
  // Production backend URL (deployed on Render)
  // Try the subdomain approach first
  static const String _productionUrl = 'https://qw-backend-oymh.onrender.com';
  // 'https://vns-quantum-dashboard.onrender.com';
  // Alternative options:

  // static const String _productionUrl = 'https://quantum-dashboard-backend.onrender.com';

  // Development settings (for local development)
  static const String _devMachineIp =
      '192.168.1.36'; // Android emulator default
  // static const String _devMachineIp = '10.0.2.2';
  static const int _serverPort = 4444; // Backend runs on port 4444

  // Set to true to use production backend, false for local development
  static const bool _useProductionBackend = true;

  // Whether the app is using production backend
  static bool get isUsingProduction => _useProductionBackend;

  // Whether to show development/debug UI elements
  // This should be false in production builds
  static bool get showDebugUI => kDebugMode && !_useProductionBackend;

  // Get the appropriate base URL based on configuration and platform
  static String get baseUrl {
    // If using production backend, always return the production URL
    if (_useProductionBackend) {
      return _productionUrl;
    }

    // Local development configuration
    if (kIsWeb) {
      // Web applications use localhost
      return 'http://localhost:$_serverPort';
    } else if (Platform.isAndroid) {
      // Android emulator uses 10.0.2.2 (special alias to host loopback)
      // Physical Android devices need your development machine's IP address
      return 'http://$_devMachineIp:$_serverPort';
    } else if (Platform.isIOS) {
      // iOS simulator uses localhost
      // Physical iOS devices need your development machine's IP address
      return 'http://$_devMachineIp:$_serverPort';
    } else {
      // Default fallback
      return 'http://localhost:$_serverPort';
    }
  }

  // Helper method to switch between production and development
  static String get currentEnvironment =>
      _useProductionBackend ? 'Production' : 'Development';
}
