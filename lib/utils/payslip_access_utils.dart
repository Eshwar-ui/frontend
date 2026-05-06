import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/services/attendance_settings_service.dart';

String _normalizeEmail(String? email) {
  return (email ?? '').trim().toLowerCase();
}

bool canManageAdminPayslips(
  Employee? user,
  AttendanceSettings settings,
) {
  final userEmail = _normalizeEmail(user?.email);
  if (user == null || user.role?.trim().toLowerCase() != 'admin') {
    return false;
  }

  return userEmail.isNotEmpty &&
      settings.payslipAdminEmails.contains(userEmail);
}

bool canManageAdminOffers(
  Employee? user,
  AttendanceSettings settings,
) {
  final userEmail = _normalizeEmail(user?.email);
  if (user == null || user.role?.trim().toLowerCase() != 'admin') {
    return false;
  }

  return userEmail.isNotEmpty &&
      settings.offerAdminEmails.contains(userEmail);
}
