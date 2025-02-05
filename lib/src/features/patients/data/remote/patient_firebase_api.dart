import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';

class PatientFirebaseApi extends AbstractPatientsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<Either<Failure, List<PatientModel>>> getPatients() async {
    try {
      QuerySnapshot _ = await _firestore.collection('patients').get();
      List<PatientModel> patients = _.docs
          .map(
              (doc) => PatientModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      return Right(patients);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> addPatient(PatientModel patientModel) async {
    try {
      await _firestore.collection('patients').add(patientModel.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> updatePatient(PatientModel patientModel) async {
    try {
      await _firestore
          .collection('patients')
          .doc(patientModel.id)
          .update(patientModel.toJson());
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> deletePatient(String id) async {
    try {
      await _firestore.collection('patients').doc(id).delete();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
