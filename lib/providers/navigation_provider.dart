import 'package:flutter/material.dart';

enum NavigationPage {
  Dashboard,
  Leaves,
  Attendance,
  Payslips,
  Holidays,
  CompoffWallet,
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
  AdminLocations,
  AdminCompoff,
}

class NavigationProvider with ChangeNotifier {
  NavigationPage _currentPage = NavigationPage.Dashboard;
  String? _pendingAdminEmployeeStatusFilter;

  static const Set<String> _validEmployeeStatuses = {
    'active',
    'inactive',
    'hold',
    'terminated',
  };

  NavigationPage get currentPage => _currentPage;
  String? get pendingAdminEmployeeStatusFilter =>
      _pendingAdminEmployeeStatusFilter;

  void setCurrentPage(NavigationPage page) {
    _currentPage = page;
    debugPrint("Setting current page to: $page");
    notifyListeners();
  }

  void setPendingAdminEmployeeStatusFilter(String status) {
    final normalized = status.trim().toLowerCase();
    if (!_validEmployeeStatuses.contains(normalized)) {
      return;
    }

    _pendingAdminEmployeeStatusFilter = normalized;
    notifyListeners();
  }

  String? consumePendingAdminEmployeeStatusFilter() {
    final pending = _pendingAdminEmployeeStatusFilter;
    _pendingAdminEmployeeStatusFilter = null;
    return pending;
  }
}
