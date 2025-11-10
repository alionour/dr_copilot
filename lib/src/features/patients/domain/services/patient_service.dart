import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientService {
  final List<PatientModel> _patients = []; // In-memory storage for mock data

  // For generating unique IDs
  int _nextId = 1;

  // Add some mock patients for testing
  PatientService() {
    _patients.add(PatientModel(
      id: 'patient_1',
      name: 'Alice Smith',
      age: 30,
      gender: 'Female',
      address: '123 Main St',
      ownerId: 'owner_1',
      clinicId: 'clinic_1',
      phoneNumber: '111-222-3333',
      createdAt: Timestamp.now(),
    ));
    _patients.add(PatientModel(
      id: 'patient_2',
      name: 'Bob Johnson',
      age: 45,
      gender: 'Male',
      address: '456 Oak Ave',
      ownerId: 'owner_1',
      clinicId: 'clinic_1',
      phoneNumber: '444-555-6666',
      createdAt: Timestamp.now(),
    ));
  }

  Future<PatientModel> createPatient(PatientModel newPatient) async {
    final patientWithId = newPatient.copyWith(id: 'patient_${_nextId++}');
    _patients.add(patientWithId);
    return patientWithId;
  }

  Future<PatientModel?> getPatient(String patientId) async {
    return _patients.firstWhereOrNull((p) => p.id == patientId);
  }

  Future<List<PatientModel>> getAllPatients() async {
    return _patients;
  }

  Future<PatientModel?> updatePatient(PatientModel updatedPatient) async {
    final index = _patients.indexWhere((p) => p.id == updatedPatient.id);
    if (index != -1) {
      _patients[index] = updatedPatient;
      return updatedPatient;
    }
    return null;
  }

  Future<void> deletePatient(String patientId) async {
    _patients.removeWhere((p) => p.id == patientId);
  }
}
