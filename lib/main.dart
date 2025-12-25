import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_nav_screen.dart';
import 'package:quantum_dashboard/new_Screens/main_screen.dart';
import 'package:quantum_dashboard/prctice.dart';
import 'package:quantum_dashboard/providers/attendance_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/local_auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/providers/location_provider.dart';
import 'package:quantum_dashboard/providers/payslip_provider.dart';
import 'package:quantum_dashboard/providers/theme_provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/utils/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/network_troubleshoot_screen.dart';
import 'package:quantum_dashboard/screens/profile_screen.dart';
import 'screens/splashscreen.dart';
import 'screens/change_password_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocalAuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => LeaveProvider()),
        ChangeNotifierProvider(create: (_) => PayslipProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        // Add other providers here
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Employee Management',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home:
                SplashScreen(), // Or LoginScreen() if you want to go there directly
            routes: {
              '/login': (context) => LoginScreen(),
              '/dashboard': (context) => NavScreen(),
              '/profile': (context) => ProfileScreen(),
              '/network_troubleshoot': (context) => NetworkTroubleshootScreen(),
              '/change_password': (context) => ChangePasswordScreen(),
              '/auth': (context) => Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (!authProvider.isLoggedIn) {
                    return LoginScreen();
                  }
                  if (authProvider.isAdmin) {
                    return AdminNavScreen();
                  }
                  return NavScreen();
                },
              ),
              // Add other routes
            },
          );
        },
      ),
    );
  }
}
