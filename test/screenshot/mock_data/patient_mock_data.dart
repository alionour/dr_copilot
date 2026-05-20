import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

/// Factory class for generating realistic mock patient data for screenshot tests.
/// No Firebase or service dependencies - creates data purely in memory.
class PatientMockData {
  /// Generates a list of mock patients with realistic data.
  static List<PatientModel> generateMockPatients({int count = 20}) {
    final patients = <PatientModel>[];
    final now = DateTime.now();

    // Sample data for realistic patient generation
    final maleNames = [
      'Ahmed Hassan',
      'Mohammed Ali',
      'Khaled Ibrahim',
      'Omar Mahmoud',
      'Youssef Ahmed',
      'Amr Saeed',
      'Hassan Mohamed',
      'Tarek Fouad',
    ];

    final femaleNames = [
      'Fatima Said',
      'Aisha Abdullah',
      'Maryam Hassan',
      'Nour El-Din',
      'Sara Ibrahim',
      'Huda Mahmoud',
      'Laila Ahmed',
      'Yasmin Ali',
    ];

    final addresses = [
      'Cairo, Egypt',
      'Alexandria, Egypt',
      'Giza, Egypt',
      'Aswan, Egypt',
      'Luxor, Egypt',
      'Mansoura, Egypt',
      'Port Said, Egypt',
      'Suez, Egypt',
    ];

    final occupations = [
      'Engineer',
      'Teacher',
      'Doctor',
      'Business Owner',
      'Student',
      'Accountant',
      'Lawyer',
      'Nurse',
    ];

    final doctors = [
      'Dr. Ahmed Hassan',
      'Dr. Nour Ibrahim',
      'Dr. Sarah Mohamed',
      'Dr. Khaled Ali',
    ];

    for (int i = 0; i < count; i++) {
      final isMale = i % 2 == 0;
      final name = isMale
          ? maleNames[i % maleNames.length]
          : femaleNames[i % femaleNames.length];

      final gender = isMale ? 'Male' : 'Female';

      // Distribute patients across different creation dates
      DateTime creationDate;
      if (i < 3) {
        // Today
        creationDate = now;
      } else if (i < 7) {
        // Yesterday
        creationDate = now.subtract(const Duration(days: 1));
      } else if (i < 12) {
        // 3 days ago
        creationDate = now.subtract(const Duration(days: 3));
      } else {
        // Last week
        creationDate = now.subtract(Duration(days: 7 + (i % 7)));
      }

      patients.add(
        PatientModel(
          id: 'patient_$i',
          name: name,
          age: 20 + (i * 3) % 60, // Ages between 20-80
          gender: gender,
          address: addresses[i % addresses.length],
          phone1: '+20 ${100 + i} ${200 + i} ${300 + i}',
          phone2:
              i % 3 == 0 ? '+20 ${150 + i} ${250 + i} ${350 + i}' : null,
          occupation: occupations[i % occupations.length],
          treatingDoctorId: doctors[i % doctors.length],
          ownerId: 'mock_owner_id',
          clinicId: 'mock_clinic_id',
          createdAt: Timestamp.fromDate(creationDate),
          updatedAt: Timestamp.fromDate(creationDate),
          createdBy: 'mock_user_id',
          updatedBy: 'mock_user_id',
        ),
      );
    }

    // Sort by createdAt descending (newest first)
    patients.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });

    return patients;
  }

  /// Creates a single patient with specific parameters.
  static PatientModel createPatient({
    required String id,
    required String name,
    int? age,
    String? gender,
    String? address,
    String? phone1,
    String? phone2,
    String? occupation,
    String? treatingDoctorId,
    DateTime? createdAt,
  }) {
    return PatientModel(
      id: id,
      name: name,
      age: age,
      gender: gender,
      address: address,
      phone1: phone1,
      phone2: phone2,
      occupation: occupation,
      treatingDoctorId: treatingDoctorId,
      ownerId: 'mock_owner_id',
      clinicId: 'mock_clinic_id',
      createdAt: createdAt != null ? Timestamp.fromDate(createdAt) : null,
      updatedAt: createdAt != null ? Timestamp.fromDate(createdAt) : null,
      createdBy: 'mock_user_id',
      updatedBy: 'mock_user_id',
    );
  }
}
