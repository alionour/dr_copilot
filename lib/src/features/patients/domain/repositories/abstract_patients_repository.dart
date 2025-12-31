import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

/// An abstract class that defines the repository for patient-related operations.
abstract class AbstractPatientsRepository {
  /// Gets a list of patients with pagination.
  Future<Either<Failure, Tuple2<List<PatientModel>, DocumentSnapshot?>>>
      getPatients({
    String? lastDocumentId,
    int? limit,
    String? treatingDoctorId,
  });

  /// Adds a new patient.
  Future<Either<Failure, PatientModel>> addPatient(PatientModel patientModel);

  /// Updates an existing patient.
  Future<Either<Failure, PatientModel>> updatePatient(
      String id, PatientModel patientModel);

  /// Deletes a patient by their ID.
  Future<Either<Failure, void>> deletePatient(String id);

  /// Searches patients based on criteria.
  Future<Either<Failure, List<PatientModel>>> searchPatients({
    String? name,
    int? minAge,
    int? maxAge,
    String? address,
    String? gender,
  });

  /// Gets patients by a specific date.
  Future<Either<Failure, List<PatientModel>>> getPatientsByDate(
      int year, int month,
      {DocumentSnapshot? lastDocument, int limit = 20});

  /// Gets a single patient by their ID.
  Future<Either<Failure, PatientModel>> getPatientById(String id);

  /// Gets all patients without pagination.
  Future<Either<Failure, List<PatientModel>>> getAllPatients();

  /// Gets the total count of patients in Firestore.
  Future<Either<Failure, int>> getPatientsCount();

  /// Gets all deleted patients (where deletedAt is not null).
  Future<Either<Failure, List<PatientModel>>> getDeletedPatients();

  /// Restores a deleted patient by setting deletedAt to null.
  Future<Either<Failure, void>> restorePatient(String id);

  /// Permanently deletes a patient from Firestore.
  Future<Either<Failure, void>> permanentlyDeletePatient(String id);
}
