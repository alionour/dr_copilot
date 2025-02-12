import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

/// An abstract class that defines the repository for patient-related operations.
abstract class AbstractPatientsRepository {
  /// Gets a list of patients.
  Future<Either<Failure, List<PatientModel>>> getPatients(String query);

  /// Adds a new patient.
  Future<Either<Failure, PatientModel>> addPatient(PatientModel patientModel);

  /// Updates an existing patient.
  Future<Either<Failure, PatientModel>> updatePatient(
      PatientModel patientModel);

  /// Deletes a patient by their ID.
  Future<Either<Failure, PatientModel>> deletePatient(String id);

  /// Searches patients based on criteria.
  Future<Either<Failure, List<PatientModel>>> searchPatients(String query);
}
