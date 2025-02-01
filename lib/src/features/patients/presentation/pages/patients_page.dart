import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';

class PatientsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patients'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with the actual number of patients
        itemBuilder: (context, index) {
          return PatientListItem(
            name: 'Patient ${index + 1}', // Replace with actual patient data
            details: 'Details for patient ${index + 1}', // Replace with actual patient data
            onTap: () {
              // Handle patient tap
            },
          );
        },
      ),
    );
  }
}
