import 'package:flutter/material.dart';

enum NavigationPage {
  Dashboard,
  Leaves,
  Attendance,
  Payslips,
  Holidays,
  ChangePassword,
  Profile,
  // AllEmployees,
  AdminEmployees,
  AdminLeaveRequests,
  AdminHolidays,
  AdminDepartments,
  AdminLeaveTypes,
  AdminPayslips,
  AdminMobileAccess,
  AdminCompanyLocations,
  AdminEmployeeLocations,
  AdminAttendance,
}

class NavigationProvider with ChangeNotifier {
  NavigationPage _currentPage = NavigationPage.Dashboard;

  NavigationPage get currentPage => _currentPage;

  void setCurrentPage(NavigationPage page) {
    _currentPage = page;
    debugPrint("Setting current page to: $page");
    notifyListeners();
  }
}
