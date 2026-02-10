import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/screens/generate_payslip_screen.dart';

void main() {
  testWidgets('requires employee and basic salary', (tester) async {
    final employees = [
      Employee(
        id: '1',
        employeeId: 'QWIT-1001',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        mobile: '9999999999',
        dateOfBirth: DateTime(1990, 1, 1),
        joiningDate: DateTime(2020, 1, 1),
        password: 'secret',
        profileImage: '',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(home: GeneratePayslipScreen(employees: employees)),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Generate Payslip'));
    await tester.pumpAndSettle();

    expect(find.text('Please select an employee'), findsOneWidget);
    expect(find.text('Please enter basic salary'), findsOneWidget);
  });
}
