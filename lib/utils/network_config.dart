import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class NetworkConfig {
  // Production backend URL (deployed on Render)
  static const String _productionUrl = 'https://quantum-dashboard-backend.onrender.com';
  
  // Development settings (for local development)
  static const String _devMachineIp = '10.0.2.2'; // Android emulator default
  static const int _serverPort = 5000;
  
  // Set to true to use production backend, false for local development
  static const bool _useProductionBackend = true;

  // Whether the app is using production backend
  static bool get isUsingProduction => _useProductionBackend;

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
  static String get currentEnvironment => _useProductionBackend ? 'Production' : 'Development';
}
