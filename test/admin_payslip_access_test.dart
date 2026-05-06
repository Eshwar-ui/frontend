import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_management_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_payslips_screen.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
import 'package:quantum_dashboard/providers/navigation_provider.dart';
import 'package:quantum_dashboard/services/attendance_settings_service.dart';

Employee buildAdminUser({required String email}) {
  return Employee(
    id: 'test-id',
    employeeId: 'QWIT-1001',
    firstName: 'Admin',
    lastName: 'User',
    email: email,
    mobile: '1234567890',
    dateOfBirth: DateTime(1990, 1, 1),
    joiningDate: DateTime(2020, 1, 1),
    password: '',
    profileImage: '',
    role: 'admin',
  );
}

AttendanceSettings buildSettings(List<String> emails) {
  return AttendanceSettings(
    locationPunchInEnabled: true,
    attendanceTimezone: 'Asia/Kolkata',
    defaultShiftStartTime: '09:30',
    defaultShiftEndTime: '18:30',
    punchInGraceMinutes: 15,
    punchOutGraceMinutes: 15,
    payslipAdminEmails: emails,
    offerAdminEmails: const [],
  );
}

void main() {
  group('Admin payslip access', () {
    late AuthProvider authProvider;
    late NavigationProvider navigationProvider;

    setUp(() {
      authProvider = AuthProvider();
      authProvider.setUser(buildAdminUser(email: 'admin@quantumworks.in'));
      navigationProvider = NavigationProvider();
    });

    Widget buildTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<NavigationProvider>.value(
            value: navigationProvider,
          ),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('shows payslips management card for allowlisted admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          AdminManagementScreen(
            payslipAccessFuture: Future.value(
              buildSettings(['admin@quantumworks.in']),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Payslips'), findsOneWidget);
      expect(find.text('Generate and manage employee payslips'), findsOneWidget);
    });

    testWidgets('hides payslips management card for unauthorized admin', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          AdminManagementScreen(
            payslipAccessFuture: Future.value(
              buildSettings(['finance@quantumworks.in']),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Payslips'), findsNothing);
      expect(find.text('Generate and manage employee payslips'), findsNothing);
    });

    testWidgets('blocks direct access to admin payslips screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          AdminPayslipsScreen(
            payslipAccessFuture: Future.value(
              buildSettings(['finance@quantumworks.in']),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Payslip access denied'), findsOneWidget);
      expect(
        find.text('Your account is not allowed to manage admin payslips.'),
        findsOneWidget,
      );
    });
  });
}
