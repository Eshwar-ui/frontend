import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'network_config.dart';

class ConnectivityChecker {
  // Check if the device can connect to the backend server
  static Future<bool> canConnectToBackend() async {
    try {
      // Skip check on web platform
      if (kIsWeb) return true;
      
      // Test our backend connectivity
      final url = Uri.parse(NetworkConfig.baseUrl);
      
      // Use reasonable timeout for production
      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () => http.Response('Timeout', 408),
      );
      
      // Accept any valid HTTP response (not just 200)
      return response.statusCode < 500 && response.statusCode != 408;
    } catch (e) {
      return false;
    }
  }
  
  // Get diagnostic information about the network configuration
  static Future<Map<String, dynamic>> getDiagnosticInfo() async {
    final Map<String, dynamic> info = {
      'baseUrl': NetworkConfig.baseUrl,
      'isWeb': kIsWeb,
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'canConnectToBackend': await canConnectToBackend(),
    };
    
    return info;
  }
  
  // Print diagnostic information to the console
  static Future<void> printDiagnosticInfo() async {
    final info = await getDiagnosticInfo();
    print('===== NETWORK DIAGNOSTIC INFO =====');
    info.forEach((key, value) {
      print('$key: $value');
    });
    print('===================================');
  }
}