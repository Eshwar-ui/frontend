import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_dashboard_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_departments_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_leave_types_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_payslips_screen.dart';
import 'package:quantum_dashboard/screens/admin_employees_screen.dart';
import 'package:quantum_dashboard/screens/admin_holidays_screen.dart';
import 'package:quantum_dashboard/screens/admin_leave_requests_screen.dart';
import 'package:quantum_dashboard/new_Screens/new_profile_page.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';

class AdminNavScreen extends StatefulWidget {
  const AdminNavScreen({super.key});

  @override
  State<AdminNavScreen> createState() => _AdminNavScreenState();
}

class _AdminNavScreenState extends State<AdminNavScreen> {
  static const Map<NavigationPage, int> _pageMap = {
    NavigationPage.Dashboard: 0, // Using Dashboard for Admin Dashboard
    NavigationPage.AdminEmployees: 1,
    NavigationPage.AdminLeaveRequests: 2,
    NavigationPage.Profile: 3,
    NavigationPage.AdminHolidays: 0, // Show in dashboard area
    NavigationPage.AdminDepartments: 0, // Show in dashboard area
    NavigationPage.AdminLeaveTypes: 0, // Show in dashboard area
    NavigationPage.AdminPayslips: 0, // Show in dashboard area
  };

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      _buildCurrentScreen(),
      AdminEmployeesScreen(), // We will need to update this to match the theme
      AdminLeaveRequestsScreen(), // We will need to update this to match the theme
      NewProfilePage(),
    ];
  }

  Widget _buildCurrentScreen() {
    final navigationProvider = Provider.of<NavigationProvider>(
      context,
      listen: false,
    );
    final currentPage = navigationProvider.currentPage;

    switch (currentPage) {
      case NavigationPage.AdminHolidays:
        return AdminHolidaysScreen();
      case NavigationPage.AdminDepartments:
        return AdminDepartmentsScreen();
      case NavigationPage.AdminLeaveTypes:
        return AdminLeaveTypesScreen();
      case NavigationPage.AdminPayslips:
        return AdminPayslipsScreen();
      default:
        return AdminDashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final currentPage = navigationProvider.currentPage;

    // Default to index 0 if the current page is not in the map (e.g. employee pages)
    int _selectedIndex = _pageMap[currentPage] ?? 0;

    // Safety check: if _selectedIndex is out of bounds (shouldn't happen with correct map), default to 0
    if (_selectedIndex >= _widgetOptions.length) {
      _selectedIndex = 0;
    }

    debugPrint("Building AdminNavScreen with selectedIndex: $_selectedIndex");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with bottom padding to prevent overlap with nav bar
            Consumer<NavigationProvider>(
              builder: (context, navProvider, child) {
                // Rebuild the screen based on current page
                final currentPage = navProvider.currentPage;
                Widget currentScreen;

                switch (currentPage) {
                  case NavigationPage.AdminHolidays:
                    currentScreen = AdminHolidaysScreen();
                    break;
                  case NavigationPage.AdminDepartments:
                    currentScreen = AdminDepartmentsScreen();
                    break;
                  case NavigationPage.AdminLeaveTypes:
                    currentScreen = AdminLeaveTypesScreen();
                    break;
                  case NavigationPage.AdminPayslips:
                    currentScreen = AdminPayslipsScreen();
                    break;
                  default:
                    currentScreen = _widgetOptions[_selectedIndex];
                }

                return currentScreen;
              },
            ),

            // Floating Navigation Bar with absolute positioning
            Builder(
              builder: (context) {
                final mediaQuery = MediaQuery.of(context);
                final screenWidth = mediaQuery.size.width;
                final screenHeight = mediaQuery.size.height;

                // Use relative sizes
                final double navBarHeight = (screenHeight * 0.100).clamp(
                  60,
                  90,
                ); // min 60, max 90
                final double navBarHorizontalPadding = (screenWidth * 0.05)
                    .clamp(10, 30);
                final double navBarBottom = (screenHeight * 0.025).clamp(8, 24);
                final double navBarLeftRight = (screenWidth * 0.04).clamp(
                  8,
                  32,
                );

                return Positioned(
                  left: navBarLeftRight,
                  right: navBarLeftRight,
                  bottom: navBarBottom,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 1, sigmaY: 1),
                      child: Container(
                        height: navBarHeight,
                        padding: EdgeInsets.symmetric(
                          horizontal: navBarHorizontalPadding,
                          vertical:
                              navBarHeight * 0.08, // about 8% of navBar height
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    Colors.white.withOpacity(0.15),
                                    Colors.white.withOpacity(0.05),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.8),
                                    Colors.white.withOpacity(0.6),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.25)
                                : Colors.white.withOpacity(0.9),
                            width: 1.5,
                          ),
                          boxShadow: [
                            // Outer shadow for depth
                            BoxShadow(
                              blurRadius: 30,
                              spreadRadius: -5,
                              color: isDark
                                  ? Colors.black.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.15),
                              offset: Offset(0, 8),
                            ),
                            // Inner highlight for glass effect
                            BoxShadow(
                              blurRadius: 10,
                              spreadRadius: -2,
                              color: Colors.white.withOpacity(0.3),
                              offset: Offset(0, -2),
                            ),
                            // Soft glow
                            BoxShadow(
                              blurRadius: 20,
                              color: isDark
                                  ? Colors.black.withOpacity(0.2)
                                  : Colors.black.withOpacity(0.08),
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildNavItem(
                              Icons.dashboard,
                              'Dashboard',
                              0,
                              context,
                            ),
                            _buildNavItem(
                              Icons.people,
                              'Employees',
                              1,
                              context,
                            ),
                            _buildNavItem(
                              Icons.assignment,
                              'Requests',
                              2,
                              context,
                            ),
                            _buildNavItem(Icons.person, 'Profile', 3, context),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final currentPage = navigationProvider.currentPage;

    // Check if the current page maps to this index
    final isSelected = (_pageMap[currentPage] ?? 0) == index;

    return GestureDetector(
      onTap: () {
        // Find the NavigationPage key that corresponds to this index
        final newPage = _pageMap.entries
            .firstWhere(
              (element) => element.value == index,
              orElse: () => MapEntry(NavigationPage.Dashboard, 0),
            )
            .key;

        navigationProvider.setCurrentPage(newPage);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : (isDark ? colorScheme.surface : Colors.white),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? colorScheme.onSurface.withOpacity(0.7)
                        : Colors.grey[600]),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
