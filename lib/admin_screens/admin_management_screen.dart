import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/screens/admin_holidays_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_departments_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_leave_types_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_payslips_screen.dart';

class AdminManagementScreen extends StatelessWidget {
  const AdminManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = Provider.of<NavigationProvider>(context);
    final currentPage = navigationProvider.currentPage;

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
        currentScreen = _buildManagementMenu(context);
    }

    return currentScreen;
  }

  Widget _buildManagementMenu(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigationProvider = Provider.of<NavigationProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Management',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Management',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Manage holidays, departments, leave types, and payslips',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              SizedBox(height: 24),
              _buildManagementCard(
                context,
                'Holidays',
                'Add and manage company holidays',
                Icons.celebration,
                Colors.purple,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminHolidays,
                  );
                },
              ),
              SizedBox(height: 16),
              _buildManagementCard(
                context,
                'Departments',
                'Add and manage departments and designations',
                Icons.business,
                Colors.blue,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminDepartments,
                  );
                },
              ),
              SizedBox(height: 16),
              _buildManagementCard(
                context,
                'Leave Types',
                'Add and manage leave types',
                Icons.event_busy,
                Colors.orange,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminLeaveTypes,
                  );
                },
              ),
              SizedBox(height: 16),
              _buildManagementCard(
                context,
                'Payslips',
                'Generate and manage employee payslips',
                Icons.receipt_long,
                Colors.green,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminPayslips,
                  );
                },
              ),
              SizedBox(height: 120), // Extra padding for nav bar
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurface.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
