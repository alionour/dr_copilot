import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

/// An abstract class that defines the API for patient-related operations.
abstract class AbstractPatientApi {
  /// Fetches a list of patients.
  Future<List<PatientModel>> fetchPatients();

  /// Adds a new patient.
  Future<PatientModel> addPatient(PatientModel patient);

  /// Updates an existing patient.
  Future<PatientModel> updatePatient(PatientModel patient);

  /// Deletes a patient by their ID.
  Future<void> deletePatient(String patientId);

  /// Searches patients based on criteria.
  Future<List<PatientModel>> searchPatients(String query);
}

