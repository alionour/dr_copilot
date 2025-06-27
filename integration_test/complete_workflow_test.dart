import 'package:dr_copilot/main.dart' as app;
import 'package:dr_copilot/src/core/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Complete Workflow Integration Tests', () {
    testWidgets(
        'complete doctor workflow: login -> patient -> session -> billing',
        (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Authentication
      AppLogger.testStep('Step 1: Authenticating...');
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 2: Navigate to Patients and Add New Patient
      AppLogger.testStep('Step 2: Adding new patient...');
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Fill patient information
      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'Alice Johnson');
      await tester.enterText(find.byKey(const Key('patient_email_field')),
          'alice.johnson@example.com');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '+1555123456');
      await tester.enterText(find.byKey(const Key('patient_address_field')),
          '456 Oak St, Springfield');
      await tester.enterText(find.byKey(const Key('medical_history_field')),
          'Diabetes Type 2, Hypertension');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify patient was created
      expect(find.text('Alice Johnson'), findsOneWidget);

      // Step 3: Schedule Appointment for Patient
      AppLogger.testStep('Step 3: Scheduling appointment...');
      await tester.tap(find.text('Alice Johnson'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule Appointment'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('appointment_title_field')),
          'Diabetes Follow-up');
      await tester.enterText(find.byKey(const Key('appointment_notes_field')),
          'Check blood sugar levels and medication adjustment');

      // Select appointment date
      await tester.tap(find.byKey(const Key('appointment_date_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Select appointment time
      await tester.tap(find.byKey(const Key('appointment_time_field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2:00 PM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Step 4: Conduct Session and Add Notes
      AppLogger.testStep('Step 4: Conducting session...');
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Diabetes Follow-up'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();

      // Add session notes
      await tester.enterText(
          find.byKey(const Key('session_notes_field')),
          'Patient reports improved energy levels. Blood sugar readings have been stable. '
          'Continuing current medication regimen. Recommended dietary adjustments discussed.');

      // Add vital signs
      await tester.enterText(
          find.byKey(const Key('blood_pressure_field')), '130/85');
      await tester.enterText(find.byKey(const Key('heart_rate_field')), '72');
      await tester.enterText(find.byKey(const Key('weight_field')), '165');

      // Complete session
      await tester.tap(find.text('Complete Session'));
      await tester.pumpAndSettle();

      // Step 5: Generate Invoice and Record Payment
      AppLogger.testStep('Step 5: Processing billing...');
      await tester.tap(find.text('Generate Invoice'));
      await tester.pumpAndSettle();

      // Set consultation fee
      await tester.enterText(
          find.byKey(const Key('consultation_fee_field')), '150.00');
      await tester.enterText(find.byKey(const Key('invoice_notes_field')),
          'Diabetes follow-up consultation');

      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      // Record payment
      await tester.tap(find.text('Record Payment'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cash'));
      await tester.enterText(
          find.byKey(const Key('payment_amount_field')), '150.00');

      await tester.tap(find.text('Record'));
      await tester.pumpAndSettle();

      // Step 6: Use AI Copilot for Medical Advice
      AppLogger.testStep('Step 6: Consulting AI Copilot...');
      await tester.tap(find.text('Copilot'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('chat_input_field')),
          'What are the latest guidelines for diabetes management in patients with hypertension?');

      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify AI response appears
      expect(find.byType(Text),
          findsAtLeastNWidgets(2)); // User message + AI response

      // Step 7: Review Financial Summary
      AppLogger.testStep('Step 7: Reviewing financials...');
      await tester.tap(find.text('Financials'));
      await tester.pumpAndSettle();

      // Verify transaction appears
      expect(find.text('\$150.00'), findsOneWidget);
      expect(find.text('Diabetes follow-up consultation'), findsOneWidget);

      // Check daily summary
      await tester.tap(find.text('Daily Summary'));
      await tester.pumpAndSettle();

      // Verify daily earnings
      expect(find.text('Today\'s Earnings'), findsOneWidget);
      expect(find.text('\$150.00'), findsAtLeastNWidgets(1));

      // Step 8: Export Patient Report
      AppLogger.testStep('Step 8: Exporting patient report...');
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice Johnson'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Report'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PDF'));
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Verify export success
      expect(find.text('Report exported successfully'), findsOneWidget);

      AppLogger.testResult('Complete workflow test passed!');
    });

    testWidgets('multi-patient day workflow with scheduling conflicts',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Add multiple patients
      final patients = ['Bob Smith', 'Carol Davis', 'David Wilson'];

      for (final patientName in patients) {
        await tester.tap(find.text('Patients'));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.add));
        await tester.pumpAndSettle();

        await tester.enterText(
            find.byKey(const Key('patient_name_field')), patientName);
        await tester.enterText(find.byKey(const Key('patient_phone_field')),
            '+1555${patients.indexOf(patientName) + 1}00000');

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
      }

      // Schedule overlapping appointments
      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();

      // Try to schedule two appointments at the same time
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('appointment_title_field')),
          'Bob Smith Consultation');
      await tester.tap(find.text('10:00 AM'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Try to schedule another at the same time
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('appointment_title_field')),
          'Carol Davis Consultation');
      await tester.tap(find.text('10:00 AM'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show conflict warning
      expect(find.text('Time slot conflict'), findsOneWidget);
      expect(find.text('Another appointment is scheduled at this time'),
          findsOneWidget);

      // Resolve conflict by choosing different time
      await tester.tap(find.text('Choose Different Time'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('11:00 AM'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify both appointments are scheduled
      expect(find.text('Bob Smith Consultation'), findsOneWidget);
      expect(find.text('Carol Davis Consultation'), findsOneWidget);
    });

    testWidgets('emergency patient workflow with priority handling',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Add emergency patient
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'Emergency Patient');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '+1555911911');

      // Mark as emergency
      await tester.tap(find.byKey(const Key('emergency_checkbox')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Emergency patient should appear at top of list
      final patientList = find.byType(ListTile);
      final firstPatient = tester.widget<ListTile>(patientList.first);
      expect(firstPatient.title.toString(), contains('Emergency Patient'));

      // Quick session start
      await tester.tap(find.text('Emergency Patient'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Session'));
      await tester.pumpAndSettle();

      // Emergency session form
      await tester.enterText(find.byKey(const Key('emergency_notes_field')),
          'Chest pain, shortness of breath');
      await tester.enterText(find.byKey(const Key('vital_signs_field')),
          'BP: 180/110, HR: 120, O2: 95%');

      await tester.tap(find.text('Save Emergency Session'));
      await tester.pumpAndSettle();

      // Verify emergency session is recorded
      expect(find.text('Emergency session recorded'), findsOneWidget);
    });

    testWidgets('data synchronization and offline recovery workflow',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Create data while online
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'Online Patient');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '+1555online');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Simulate going offline
      // Add patient while offline
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'Offline Patient');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '+1555offline');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show offline indicator
      expect(find.text('Saved offline'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsOneWidget);

      // Simulate coming back online
      await tester.tap(find.byIcon(Icons.sync));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show sync success
      expect(find.text('Data synchronized'), findsOneWidget);
      expect(find.byIcon(Icons.sync_problem), findsNothing);
    });
  });
}
