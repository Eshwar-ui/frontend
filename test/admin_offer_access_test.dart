import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_offer_letters_screen.dart';
import 'package:quantum_dashboard/admin_screens/admin_offer_template_screen.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';
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
    payslipAdminEmails: const [],
    offerAdminEmails: emails,
  );
}

void main() {
  group('Admin offer access', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
      authProvider.setUser(buildAdminUser(email: 'admin@quantumworks.in'));
    });

    Widget buildTestApp(Widget child) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: MaterialApp(home: child),
      );
    }

    testWidgets('blocks direct access to admin offer letters screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          AdminOfferLettersScreen(
            offerAccessFuture: Future.value(
              buildSettings(['finance@quantumworks.in']),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Offer access denied'), findsOneWidget);
      expect(
        find.text('Your account is not allowed to manage offer letters.'),
        findsOneWidget,
      );
    });

    testWidgets('blocks direct access to admin offer template screen', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          AdminOfferTemplateScreen(
            offerAccessFuture: Future.value(
              buildSettings(['finance@quantumworks.in']),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Offer access denied'), findsOneWidget);
      expect(
        find.text('Your account is not allowed to manage offer letters.'),
        findsOneWidget,
      );
    });
  });
}
