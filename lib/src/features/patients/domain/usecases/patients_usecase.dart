import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';

class PatientsUseCase {
  final AbstractPatientsRepository repository;

  PatientsUseCase(this.repository);

  /// Gets a list of patients.
  Future<Either<Failure, List<PatientModel>>> getPatients({
    String? lastDocumentId, // Corrected parameter name
    int limit = 20,
  }) async {
    return await repository.getPatients();
  }

  /// Adds a new patient.
  Future<Either<Failure, PatientModel>> addPatient(
      PatientModel patientModel) async {
    return await repository.addPatient(patientModel);
  }

  /// Updates an existing patient.
  Future<Either<Failure, PatientModel>> updatePatient(
      String id, PatientModel patientModel) async {
    return await repository.updatePatient(id, patientModel);
  }

  /// Deletes a patient by their ID.
  Future<Either<Failure, void>> deletePatient(String patientId) async {
    return await repository.deletePatient(patientId);
  }

  /// Searches patients based on criteria.
  Future<Either<Failure, List<PatientModel>>> searchPatients({
    String? name,
    int? minAge,
    int? maxAge,
    String? address,
    String? gender,
  }) async {
    return await repository.searchPatients(
      name: name,
      minAge: minAge,
      maxAge: maxAge,
      address: address,
      gender: gender,
    );
  }

  /// Gets patients by a specific date.
  Future<Either<Failure, List<PatientModel>>> getPatientsByDate(DateTime date,
      {String? lastDocumentID, int limit = 20}) async {
    return await repository.getPatientsByDate(date,
        lastDocumentID: lastDocumentID, limit: limit);
  }
}
