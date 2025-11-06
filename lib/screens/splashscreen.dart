// Splash Screen (iPhone 16 Pro Max - 4)
import 'package:flutter/material.dart';
import 'package:quantum_dashboard/utils/constants.dart';

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
          try {
            Navigator.pushReplacementNamed(context, '/auth');
          } catch (e) {
            print('Error navigating from splash screen: $e');
            // Fallback: try again after a short delay
            Future.delayed(Duration(milliseconds: 500), () {
              if (mounted) {
                try {
                  Navigator.pushReplacementNamed(context, '/auth');
                } catch (e2) {
                  print('Error in fallback navigation: $e2');
                }
              }
            });
          }
        }
      });
    });
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
