import 'package:dr_copilot/main.dart' as app;
import 'package:dr_copilot/src/core/app/app.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/patients_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dr Copilot App Integration Tests', () {
    testWidgets('app should launch and show login page', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Verify the app launches successfully
      expect(find.byType(App), findsOneWidget);
      
      // Should show login page initially (if not authenticated)
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('complete authentication flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify we're on login page
      expect(find.byType(LoginPage), findsOneWidget);

      // Tap Google Sign In button
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Note: In a real integration test, you would need to handle
      // actual Google authentication or mock it appropriately
      // For now, we'll test the UI flow

      // Verify loading state appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('navigation between main sections', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Assuming user is authenticated and on home page
      // This test would need authentication setup

      // Navigate to Patients section
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientsPage), findsOneWidget);

      // Navigate to Financials section
      await tester.tap(find.text('Financials'));
      await tester.pumpAndSettle();

      // Navigate back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('patient management flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Patients page
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Tap Add Patient button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill in patient form
      await tester.enterText(find.byKey(const Key('patient_name_field')), 'John Doe');
      await tester.enterText(find.byKey(const Key('patient_email_field')), 'john@example.com');
      await tester.enterText(find.byKey(const Key('patient_phone_field')), '+1234567890');

      // Save patient
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify patient was added to list
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('appointment scheduling flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Calendar/Appointments
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // Add new appointment
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill appointment details
      await tester.enterText(find.byKey(const Key('appointment_title_field')), 'Patient Consultation');
      
      // Select date and time
      await tester.tap(find.byKey(const Key('date_picker_button')));
      await tester.pumpAndSettle();
      
      // Select today's date
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Save appointment
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify appointment appears in calendar
      expect(find.text('Patient Consultation'), findsOneWidget);
    });

    testWidgets('financial tracking flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Financials
      await tester.tap(find.text('Financials'));
      await tester.pumpAndSettle();

      // Navigate to Transactions
      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      // Add new transaction
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill transaction details
      await tester.enterText(find.byKey(const Key('transaction_amount_field')), '150.00');
      await tester.enterText(find.byKey(const Key('transaction_description_field')), 'Consultation Fee');

      // Select transaction type
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      // Save transaction
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify transaction appears in list
      expect(find.text('Consultation Fee'), findsOneWidget);
      expect(find.text('\$150.00'), findsOneWidget);
    });

    testWidgets('copilot chat interaction', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Copilot Chat
      await tester.tap(find.text('Copilot'));
      await tester.pumpAndSettle();

      // Enter a message
      await tester.enterText(
        find.byKey(const Key('chat_input_field')), 
        'What are the symptoms of diabetes?'
      );

      // Send message
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      // Verify message appears in chat
      expect(find.text('What are the symptoms of diabetes?'), findsOneWidget);

      // Wait for AI response (with timeout)
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify response appears
      expect(find.byType(Text), findsAtLeastNWidgets(2)); // User message + AI response
    });

    testWidgets('settings and preferences', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Toggle dark mode
      await tester.tap(find.byKey(const Key('dark_mode_switch')));
      await tester.pumpAndSettle();

      // Verify theme changed
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNot(equals(Colors.white)));

      // Change language
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      // Verify language changed (RTL layout)
      expect(find.text('الإعدادات'), findsOneWidget);
    });

    testWidgets('search functionality across features', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test patient search
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search_field')), 'John');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('John Doe'), findsOneWidget);

      // Test transaction search
      await tester.tap(find.text('Financials'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Transactions'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('search_field')), 'Consultation');
      await tester.pumpAndSettle();

      expect(find.text('Consultation Fee'), findsOneWidget);
    });

    testWidgets('offline functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Simulate offline mode
      // This would require network mocking in a real test

      // Navigate to Patients (should work offline with cached data)
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Verify cached patients are still visible
      expect(find.byType(PatientsPage), findsOneWidget);

      // Try to add new patient (should queue for sync)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('patient_name_field')), 'Offline Patient');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show offline indicator or sync pending message
      expect(find.text('Sync pending'), findsOneWidget);
    });

    testWidgets('data persistence across app restarts', (WidgetTester tester) async {
      // First app session
      app.main();
      await tester.pumpAndSettle();

      // Add some data
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('patient_name_field')), 'Persistent Patient');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Restart app (simulate app restart)
      await tester.binding.reassembleApplication();
      await tester.pumpAndSettle();

      // Verify data persists
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      expect(find.text('Persistent Patient'), findsOneWidget);
    });
  });
}
