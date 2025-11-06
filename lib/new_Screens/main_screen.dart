import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:quantum_dashboard/new_Screens/new_calender_screen.dart';
import 'package:quantum_dashboard/new_Screens/new_dashboard.dart';
import 'package:quantum_dashboard/new_Screens/new_profile_page.dart';
import 'package:quantum_dashboard/new_Screens/new_search_screen.dart';

class NavScreen extends StatefulWidget {
  const NavScreen({super.key});

  @override
  State<NavScreen> createState() => _NavScreenState();
}

class _NavScreenState extends State<NavScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    new_dashboard(),
    new_calender_screen(),
    new_search_screen(),
    NewProfilePage(),
  ];

  Widget _buildNavItem(IconData icon, String label, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
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
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.1),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content with bottom padding to prevent overlap with nav bar
            _widgetOptions[_selectedIndex],
            // Floating Navigation Bar with absolute positioning
            Builder(
              builder: (context) {
                final mediaQuery = MediaQuery.of(context);
                final screenWidth = mediaQuery.size.width;
                final screenHeight = mediaQuery.size.height;

                // Use relative sizes
                final double navBarHeight = (screenHeight * 0.100).clamp(60, 90); // min 60, max 90
                final double navBarHorizontalPadding = (screenWidth * 0.05).clamp(10, 30);
                final double navBarBottom = (screenHeight * 0.025).clamp(8, 24);
                final double navBarLeftRight = (screenWidth * 0.04).clamp(8, 32);

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
                          vertical: navBarHeight * 0.08, // about 8% of navBar height
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
                            _buildNavItem(Icons.dashboard, 'Dashboard', 0),
                            _buildNavItem(Icons.calendar_month, 'Calendar', 1),
                            _buildNavItem(Icons.search, 'Search', 2),
                            _buildNavItem(Icons.person, 'Profile', 3),
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
}
