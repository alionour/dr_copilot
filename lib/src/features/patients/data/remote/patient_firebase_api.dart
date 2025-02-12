import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart'; // Add this import
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Add this import for debugPrint

class PatientFirebaseApi extends AbstractPatientsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignInHelper _googleSignInHelper =
      GoogleSignInHelper(); // Add this line
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _isAuthenticated() async {
    return _googleSignInHelper.currentUser != null;
  }

  @override
  Future<Either<Failure, List<PatientModel>>> getPatients(String query) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('patients')
            .where('createdBy', isEqualTo: user.uid)
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: '$query\uf8ff')
            .get();

        List<PatientModel> patients = snapshot.docs
            .map((doc) => PatientModel.fromJson(doc.data()))
            .toList();
        return Right(patients);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('Firestore index required: ${e.message}');
        return Left(ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400));
      }
      debugPrint('Error getting patients: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, PatientModel>> addPatient(
      PatientModel patientModel) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('patients').add({
          ...patientModel.toJson(),
          'createdBy': user.uid,
        });
        return Right(patientModel);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding patient: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, PatientModel>> updatePatient(
      PatientModel patientModel) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore.collection('patients').doc(patientModel.id).get();
        if (doc.exists && doc.data()?['createdBy'] == user.uid) {
          await _firestore
              .collection('patients')
              .doc(patientModel.id)
              .update(patientModel.toJson());
          return Right(patientModel);
        } else {
          return Left(ServerFailure('Unauthorized', 403));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating patient: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, PatientModel>> deletePatient(String id) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('patients').doc(id).get();
        if (doc.exists && doc.data()?['createdBy'] == user.uid) {
          await _firestore.collection('patients').doc(id).delete();
          return Right(PatientModel(
              id: id,
              name: '')); // Return a dummy patient model with the deleted ID
        } else {
          return Left(ServerFailure('Unauthorized', 403));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting patient: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Fetches patients based on search criteria.
  @override
  Future<Either<Failure, List<PatientModel>>> searchPatients(
      String query) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final snapshot = await _firestore
            .collection('patients')
            .where('createdBy', isEqualTo: user.uid)
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThanOrEqualTo: '$query\uf8ff')
            .get();

        List<PatientModel> patients = snapshot.docs
            .map((doc) => PatientModel.fromJson(doc.data()))
            .toList();
        return Right(patients);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('Firestore index required: ${e.message}');
        return Left(ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400));
      }
      debugPrint('Error searching patients: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
