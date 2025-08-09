import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/widgets/patient_selection_card.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('PatientSelectionCard displays patients and calls callback',
      (WidgetTester tester) async {
    final patients = [
      const PatientModel(id: '1', name: 'John Doe'),
      const PatientModel(id: '2', name: 'Jane Doe'),
    ];
    PatientModel? selectedPatient;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PatientSelectionCard(
            patients: patients,
            onPatientSelected: (patient) {
              selectedPatient = patient;
            },
          ),
        ),
      ),
    );

    expect(find.text('Multiple patients found. Please select one:'),
        findsOneWidget);
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('Jane Doe'), findsOneWidget);

    await tester.tap(find.text('John Doe'));
    await tester.pump();

    expect(selectedPatient, isNotNull);
    expect(selectedPatient!.id, '1');
  });
}
