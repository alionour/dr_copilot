import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:flutter/material.dart';

class PatientsPage extends StatelessWidget {
  const PatientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with the actual number of patients
        itemBuilder: (context, index) {
          return PatientListItem(
            name: 'Patient ${index + 1}', // Replace with actual patient data
            details:
                'Details for patient ${index + 1}', // Replace with actual patient data
            onTap: () {
              // Handle patient tap
            },
          );
        },
      ),
    );
  }
}
