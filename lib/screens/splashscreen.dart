// Splash Screen (iPhone 16 Pro Max - 4)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/utils/constants.dart';
import 'package:quantum_dashboard/providers/local_auth_provider.dart';
// Using native system authentication instead of a custom lock screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Delay navigation to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          _checkDeviceLockAndNavigate();
        }
      });
    });
  }

  Future<void> _checkDeviceLockAndNavigate() async {
    try {
      final authProvider = Provider.of<LocalAuthProvider>(
        context,
        listen: false,
      );

      // Check if device lock is enabled
      // Ensure we load the latest persisted state before deciding
      await authProvider.checkDeviceLockStatus();
      final isDeviceLockEnabled = authProvider.isDeviceLockEnabled;

      if (isDeviceLockEnabled) {
        // Trigger native system authentication (biometrics or device credentials)
        final success = await authProvider.authenticateWithBiometrics();
        if (success && mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
        // If not successful, remain on splash
      } else {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/auth');
        }
      }
    } catch (e) {
      print('Error checking device lock: $e');
      // Fallback: try normal navigation
      if (mounted) {
        try {
          Navigator.pushReplacementNamed(context, '/auth');
        } catch (e2) {
          print('Error in fallback navigation: $e2');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(child: Image.asset(AppAssets.quantumLogo, height: 100)),
    );
  }
}
