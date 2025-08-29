import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/utils/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/network_troubleshoot_screen.dart';
import 'package:quantum_dashboard/screens/profile_screen.dart';
import 'screens/splashscreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        // Add other providers here
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Employee Management',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: SplashScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/dashboard': (context) => MainScreen(),
          '/profile': (context) => ProfileScreen(),
          '/network_troubleshoot': (context) => NetworkTroubleshootScreen(),
          '/auth': (context) => Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return authProvider.isLoggedIn ? MainScreen() : LoginScreen();
            },
          ),
          // Add other routes
        },
      ),
    );
  }
}
