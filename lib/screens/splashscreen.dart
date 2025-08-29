// Splash Screen (iPhone 16 Pro Max - 4)
import 'package:flutter/material.dart';
import 'package:quantum_dashboard/utils/constants.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/auth');
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Image.asset(AppAssets.quantumLogo, height: 100)),
    );
  }
}
