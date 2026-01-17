import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/data/remote/patient_firebase_api.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientService {
  final PatientFirebaseApi _api = PatientFirebaseApi();

  Future<Either<Failure, PatientModel>> createPatient(
      PatientModel newPatient) async {
    return _api.addPatient(newPatient);
  }

  Future<Either<Failure, PatientModel>> getPatient(String patientId) async {
    return _api.getPatientById(patientId);
  }

  Future<Either<Failure, List<PatientModel>>> getAllPatients() async {
    return _api.getAllPatients();
  }

  Future<Either<Failure, PatientModel>> updatePatient(
      PatientModel updatedPatient) async {
    return _api.updatePatient(updatedPatient.id, updatedPatient);
  }

  Future<Either<Failure, void>> deletePatient(String patientId) async {
    return _api.deletePatient(patientId);
  }

  Future<Either<Failure, List<PatientModel>>> searchPatients({
    String? name,
    int? minAge,
    int? maxAge,
    String? address,
    String? gender,
  }) async {
    return _api.searchPatients(
      name: name,
      minAge: minAge,
      maxAge: maxAge,
      address: address,
      gender: gender,
    );
  }

  Future<Either<Failure, List<PatientModel>>> getPatientsByDate(
      int year, int month,
      {DocumentSnapshot? lastDocument, int limit = 20}) async {
    return _api.getPatientsByDate(year, month,
        lastDocument: lastDocument, limit: limit);
  }

  Future<Either<Failure, int>> getPatientsCount() async {
    return _api.getPatientsCount();
  }
}

