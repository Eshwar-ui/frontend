import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/employee_provider.dart';
import 'package:quantum_dashboard/providers/leave_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load initial data for stats
      Provider.of<EmployeeProvider>(context, listen: false).getAllEmployees();
      Provider.of<LeaveProvider>(context, listen: false).getAllLeaves();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildStatsGrid(),
            _buildManagementSection(),
            SizedBox(height: 120), // Extra padding for nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final firstName = user?.firstName ?? 'Admin';

    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello $firstName',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Admin Dashboard Overview',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () {
              Provider.of<NavigationProvider>(
                context,
                listen: false,
              ).setCurrentPage(NavigationPage.Profile);
            },
            child: CircleAvatar(
              radius: 25,
              backgroundColor: colorScheme.primary,
              child: Text(
                firstName.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Consumer2<EmployeeProvider, LeaveProvider>(
      builder: (context, employeeProvider, leaveProvider, child) {
        final employeeCount = employeeProvider.employees.length;
        final pendingLeaves = leaveProvider.leaves
            .where((leave) => leave.status.toLowerCase() == 'pending')
            .length;

        // Mock data for other stats
        final presentCount = 0; // Need attendance provider for this
        final absentCount = 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Employees',
                      employeeCount.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending Leaves',
                      pendingLeaves.toString(),
                      Icons.assignment_late,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Add more rows as needed
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navigationProvider = Provider.of<NavigationProvider>(
      context,
      listen: false,
    );

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Management',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: [
              _buildManagementCard(
                'Holidays',
                Icons.celebration,
                Colors.purple,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminHolidays,
                  );
                },
              ),
              _buildManagementCard(
                'Departments',
                Icons.business,
                Colors.blue,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminDepartments,
                  );
                },
              ),
              _buildManagementCard(
                'Leave Types',
                Icons.event_busy,
                Colors.orange,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminLeaveTypes,
                  );
                },
              ),
              _buildManagementCard(
                'Payslips',
                Icons.receipt_long,
                Colors.green,
                () {
                  navigationProvider.setCurrentPage(
                    NavigationPage.AdminPayslips,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    String title,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
