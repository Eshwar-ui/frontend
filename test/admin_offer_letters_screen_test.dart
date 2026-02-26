import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:quantum_dashboard/admin_screens/admin_offer_letters_screen.dart';
import 'package:quantum_dashboard/models/user_model.dart';
import 'package:quantum_dashboard/providers/auth_provider.dart';

void main() {
  group('AdminOfferLettersScreen - Offer Letter Send', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
      authProvider.setUser(
        Employee(
          id: 'test-id',
          employeeId: 'QWIT-1001',
          firstName: 'Admin',
          lastName: 'User',
          email: 'admin@test.com',
          mobile: '1234567890',
          dateOfBirth: DateTime(1990, 1, 1),
          joiningDate: DateTime(2020, 1, 1),
          password: '',
          profileImage: '',
          role: 'admin',
        ),
      );
    });

    testWidgets('shows Offer ID required when Send Offer Email tapped without ID',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const AdminOfferLettersScreen(),
          ),
        ),
      );

      // Pump to render; avoid pumpAndSettle (getOfferLetters may hang on network)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find and tap Send Offer Email button (section title + button both have this text; button is last)
      final sendButton = find.text('Send Offer Email').last;
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pump();

      // Should show validation error in snackbar
      expect(find.text('Offer ID is required.'), findsOneWidget);
    });

    testWidgets('Send Offer Email section and Offer ID field are present',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: authProvider,
            child: const AdminOfferLettersScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Send Offer Email'), findsWidgets);
      expect(find.byType(TextField), findsWidgets);
    });
  });
}
