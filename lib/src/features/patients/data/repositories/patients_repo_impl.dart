import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';

class PatientsRepositoryImpl extends AbstractPatientsRepository {
  final PatientFirebaseApi api;

  PatientsRepositoryImpl(this.api);

  /// Fetches a list of patients.
  @override
  Future<Either<Failure, List<PatientModel>>> getPatients() {
    return api.getPatients();
  }

  /// Adds a new patient.
  @override
  Future<Either<Failure, PatientModel>> addPatient(PatientModel patientModel) {
    return api.addPatient(patientModel);
  }

  /// Updates an existing patient.
  @override
  Future<Either<Failure, PatientModel>> updatePatient(String id,
      PatientModel patientModel) {
    return api.updatePatient(id, patientModel);
  }

  /// Deletes a patient by their ID.
  @override
  Future<Either<Failure, void>> deletePatient(String id) {
    return api.deletePatient(id);
  }

  /// Searches patients based on criteria.
  @override
  Future<Either<Failure, List<PatientModel>>> searchPatients(String query) {
    return api.searchPatients(query);
  }

  /// Fetches patients by a specific date.
  Future<Either<Failure, List<PatientModel>>> getPatientsByDate(DateTime date,
      {String? lastDocumentID, int limit = 20}) {
    return api.getPatientsByDate(date, limit: limit);
  }
}
