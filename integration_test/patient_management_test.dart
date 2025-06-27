import 'package:dr_copilot/main.dart' as app;
import 'package:dr_copilot/src/features/patients/presentation/pages/patients_page.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Patient Management Integration Tests', () {
    testWidgets('complete patient creation workflow',
        (WidgetTester tester) async {
      // Launch app and navigate to patients
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patients page
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientsPage), findsOneWidget);

      // Tap add patient button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.byType(AddPatientPage), findsOneWidget);

      // Fill in patient information
      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'John Doe');
      await tester.enterText(
          find.byKey(const Key('patient_email_field')), 'john.doe@example.com');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '+1234567890');

      // Select date of birth
      await tester.tap(find.byKey(const Key('date_of_birth_field')));
      await tester.pumpAndSettle();

      // Select a date from date picker
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Fill additional information
      await tester.enterText(find.byKey(const Key('patient_address_field')),
          '123 Main St, City, State');
      await tester.enterText(
          find.byKey(const Key('medical_history_field')), 'No known allergies');
      await tester.enterText(find.byKey(const Key('emergency_contact_field')),
          'Jane Doe - +0987654321');

      // Save patient
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should return to patients list
      expect(find.byType(PatientsPage), findsOneWidget);

      // Verify patient was added to list
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);
    });

    testWidgets('patient search and filtering', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patients
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Add multiple patients first (assuming they exist or are created)
      // Search for specific patient
      await tester.enterText(find.byKey(const Key('search_field')), 'John');
      await tester.pumpAndSettle();

      // Verify search results
      expect(find.text('John Doe'), findsOneWidget);

      // Clear search
      await tester.enterText(find.byKey(const Key('search_field')), '');
      await tester.pumpAndSettle();

      // Should show all patients again
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('patient details view and editing',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patients
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Tap on a patient to view details
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Verify we're on the patient details page by checking for patient info
      expect(find.text('Patient Details'), findsOneWidget);

      // Verify patient information is displayed
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john.doe@example.com'), findsOneWidget);
      expect(find.text('+1234567890'), findsOneWidget);

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Update patient information
      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'John Smith');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '+1987654321');

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify changes are reflected
      expect(find.text('John Smith'), findsOneWidget);
      expect(find.text('+1987654321'), findsOneWidget);
    });

    testWidgets('patient deletion workflow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patients
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Long press on patient to show context menu
      await tester.longPress(find.text('John Smith'));
      await tester.pumpAndSettle();

      // Tap delete option
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirm deletion
      expect(find.text('Delete Patient'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this patient?'),
          findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify patient is removed from list
      expect(find.text('John Smith'), findsNothing);
    });

    testWidgets('patient medical history management',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patients and select a patient
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Navigate to medical history tab
      await tester.tap(find.text('Medical History'));
      await tester.pumpAndSettle();

      // Add new medical record
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('condition_field')), 'Hypertension');
      await tester.enterText(
          find.byKey(const Key('diagnosis_date_field')), '2024-01-15');
      await tester.enterText(find.byKey(const Key('notes_field')),
          'Diagnosed during routine checkup');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify medical record is added
      expect(find.text('Hypertension'), findsOneWidget);
      expect(find.text('2024-01-15'), findsOneWidget);
    });

    testWidgets('patient appointment history', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patient details
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Navigate to appointments tab
      await tester.tap(find.text('Appointments'));
      await tester.pumpAndSettle();

      // Verify appointment history is displayed
      expect(find.text('Past Appointments'), findsOneWidget);
      expect(find.text('Upcoming Appointments'), findsOneWidget);

      // Schedule new appointment
      await tester.tap(find.text('Schedule Appointment'));
      await tester.pumpAndSettle();

      // Fill appointment details
      await tester.enterText(find.byKey(const Key('appointment_title_field')),
          'Follow-up Consultation');

      // Select date and time
      await tester.tap(find.byKey(const Key('appointment_date_field')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('25'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('appointment_time_field')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('10:00 AM'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Save appointment
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify appointment is scheduled
      expect(find.text('Follow-up Consultation'), findsOneWidget);
    });

    testWidgets('patient data export and sharing', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patient details
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Access more options menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Export patient data
      await tester.tap(find.text('Export Data'));
      await tester.pumpAndSettle();

      // Select export format
      await tester.tap(find.text('PDF'));
      await tester.pumpAndSettle();

      // Confirm export
      await tester.tap(find.text('Export'));
      await tester.pumpAndSettle();

      // Verify export success message
      expect(find.text('Patient data exported successfully'), findsOneWidget);
    });

    testWidgets('patient bulk operations', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patients
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Enter selection mode
      await tester.longPress(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Select multiple patients
      await tester.tap(find.text('Jane Smith'));
      await tester.tap(find.text('Bob Johnson'));
      await tester.pumpAndSettle();

      // Perform bulk action
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bulk Export'));
      await tester.pumpAndSettle();

      // Confirm bulk operation
      await tester.tap(find.text('Export Selected'));
      await tester.pumpAndSettle();

      // Verify bulk operation success
      expect(find.text('3 patients exported successfully'), findsOneWidget);
    });

    testWidgets('patient data validation and error handling',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to add patient
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Try to save without required fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation errors
      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Phone is required'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'Test Patient');
      await tester.enterText(
          find.byKey(const Key('patient_email_field')), 'invalid-email');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '123');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify validation errors for invalid data
      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(find.text('Please enter a valid phone number'), findsOneWidget);
    });

    testWidgets('patient offline data handling', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to patients
      await tester.tap(find.text('Patients'));
      await tester.pumpAndSettle();

      // Simulate offline mode
      // Add patient while offline
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('patient_name_field')), 'Offline Patient');
      await tester.enterText(
          find.byKey(const Key('patient_phone_field')), '+1555000000');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show offline indicator
      expect(find.text('Saved offline - will sync when connected'),
          findsOneWidget);

      // Verify patient is in local storage
      expect(find.text('Offline Patient'), findsOneWidget);
      expect(
          find.byIcon(Icons.sync_problem), findsOneWidget); // Offline indicator
    });
  });
}
