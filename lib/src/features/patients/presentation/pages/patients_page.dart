import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:flutter/material.dart';

/// A page that displays a list of patients and allows searching through them.
class PatientsPage extends StatefulWidget {
  const PatientsPage({super.key});

  @override
  _PatientsPageState createState() => _PatientsPageState();
}

class _PatientsPageState extends State<PatientsPage> {
  final List<String> patients = [
    'أحمد', 'محمد', 'علي', 'يوسف', 'إبراهيم', 'خالد', 'سعيد', 'عبدالله', 'حسن', 'عمر'
  ]; // Example list of Arabic names

  String query = '';

  @override
  Widget build(BuildContext context) {
    final filteredPatients = patients.where((patient) => _normalize(patient).contains(_normalize(query))).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Patients',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onChanged: (newQuery) {
                setState(() {
                  query = newQuery;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPatients.length,
              itemBuilder: (context, index) {
                return PatientListItem(
                  name: filteredPatients[index], // Use filtered patient names
                  details: 'Details for ${filteredPatients[index]}', // Replace with actual patient data
                  onTap: () {
                    // Handle patient tap
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Normalizes Arabic text for better search matching.
  String _normalize(String input) {
    return input
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و');
  }
}
