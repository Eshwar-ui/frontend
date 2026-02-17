import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_nav_screen.dart';
import 'package:quantum_dashboard/new_Screens/main_screen.dart';
import 'package:quantum_dashboard/providers/attendance_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/holiday_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/compoff_provider.dart';
import 'package:quantum_dashboard/providers/local_auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/providers/location_provider.dart';
import 'package:quantum_dashboard/providers/payslip_provider.dart';
import 'package:quantum_dashboard/providers/theme_provider.dart';
import 'package:quantum_dashboard/providers/notification_provider.dart';
import 'package:quantum_dashboard/providers/notification_settings_provider.dart';
import 'package:quantum_dashboard/services/app_update_service.dart';
import 'package:quantum_dashboard/services/local_notification_service.dart';
import 'package:quantum_dashboard/utils/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/network_troubleshoot_screen.dart';
import 'package:quantum_dashboard/screens/profile_screen.dart';
import 'screens/splashscreen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local notifications
  try {
    await LocalNotificationService().initialize();
    await LocalNotificationService().requestPermissions();
  } catch (e) {
    debugPrint('Error initializing local notifications: $e');
    // Continue app initialization even if notifications fail
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AppUpdateService _appUpdateService = AppUpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appUpdateService.checkForUpdateIfDue(force: true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appUpdateService.checkForUpdateIfDue();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
        ChangeNotifierProvider(create: (_) => CompoffProvider()),
        ChangeNotifierProvider(create: (_) => PayslipProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NotificationSettingsProvider()),
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
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(
                    (mediaQuery.textScaler.scale(1.0)).clamp(1.0, 1.3),
                  ),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
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
