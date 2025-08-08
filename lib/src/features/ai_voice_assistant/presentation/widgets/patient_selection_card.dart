import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:flutter/material.dart';

class PatientSelectionCard extends StatelessWidget {
  final List<PatientModel> patients;
  final Function(PatientModel) onPatientSelected;

  const PatientSelectionCard({
    super.key,
    required this.patients,
    required this.onPatientSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Multiple patients found. Please select one:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return ListTile(
                    title: Text(patient.name),
                    onTap: () {
                      onPatientSelected(patient);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
