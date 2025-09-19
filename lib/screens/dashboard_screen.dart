import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/screens/admin_employees_screen.dart';
import 'package:quantum_dashboard/screens/admin_leave_requests_screen.dart';
import 'package:quantum_dashboard/screens/admin_holidays_screen.dart';
import 'package:quantum_dashboard/screens/attendance_screen.dart';
import 'package:quantum_dashboard/screens/change_password_screen.dart';
import 'package:quantum_dashboard/screens/dashboard_content.dart';
import 'package:quantum_dashboard/screens/holidays_screen.dart';
import 'package:quantum_dashboard/screens/leaves_screen.dart';
import 'package:quantum_dashboard/screens/payslips_screen.dart';
// import 'package:quantum_dashboard/screens/all_employees_screen.dart';
import 'package:quantum_dashboard/widgets/appBar.dart';
import 'package:quantum_dashboard/widgets/app_drawer.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(),
      drawer: AppDrawer(),
      body: Consumer<NavigationProvider>(
        builder: (context, navigationProvider, child) {
          return _buildPage(navigationProvider.currentPage);
        },
      ),
    );
  }

  Widget _buildPage(NavigationPage page) {
    switch (page) {
      case NavigationPage.Dashboard:
        return DashboardContent();
      case NavigationPage.Leaves:
        return LeavesScreen();
      case NavigationPage.Attendance:
        return AttendanceScreen();
      case NavigationPage.Payslips:
        return PayslipsScreen();
      case NavigationPage.Holidays:
        return HolidaysScreen();
      case NavigationPage.ChangePassword:
        return ChangePasswordScreen();
      // case NavigationPage.AllEmployees:
      //   return AllEmployeesScreen();
      case NavigationPage.AdminEmployees:
        return AdminEmployeesScreen();
      case NavigationPage.AdminLeaveRequests:
        return AdminLeaveRequestsScreen();
      case NavigationPage.AdminHolidays:
        return AdminHolidaysScreen();
      default:
        return DashboardContent();
    }
  }
}
