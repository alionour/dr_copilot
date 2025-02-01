import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/exceptions.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_impl_api.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';

class PatientsRepositoryImpl extends AbstractPatientsRepository {
  final PatientImplApi patientApi;

  PatientsRepositoryImpl(this.patientApi);

  /// Fetches a list of patients.
  @override
  Future<Either<Failure, List<PatientModel>>> getPatients() async {
    try {
      final result = await patientApi.fetchPatients();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  /// Adds a new patient.
  @override
  Future<Either<Failure, PatientModel>> addPatient(PatientModel patient) async {
    try {
      final result = await patientApi.addPatient(patient);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  /// Updates an existing patient.
  @override
  Future<Either<Failure, PatientModel>> updatePatient(
      PatientModel patient) async {
    try {
      final result = await patientApi.updatePatient(patient);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }

  /// Deletes a patient by their ID.
  @override
  Future<Either<Failure, void>> deletePatient(String patientId) async {
    try {
      await patientApi.deletePatient(patientId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.statusCode));
    }
  }
}
