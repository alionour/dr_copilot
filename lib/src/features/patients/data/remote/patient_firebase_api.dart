import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientFirebaseApi {
  final CollectionReference _patientsCollection =
      FirebaseFirestore.instance.collection('patients');

  Future<Either<Failure, List<PatientModel>>> getPatients({
    String? lastDocumentID,
    int limit = 20,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Query queryRef = _patientsCollection
            .where('userId', isEqualTo: user.uid)
            .limit(limit);

        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _patientsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef.startAfterDocument(lastDocumentSnapshot);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        }

        final snapshot = await queryRef.get();

        List<PatientModel> patients = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return PatientModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
          });
        }).toList();

        return Right(patients);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  Future<Either<Failure, PatientModel>> addPatient(PatientModel patient) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final data = patient.toJson();
        data.remove('id'); // Exclude the `id` field from the document data
        final docRef = await _patientsCollection.add({
          ...data,
          'userId': user.uid,
        });
        final createdPatient = patient.copyWith(
          id: docRef.id, // Assign the generated document ID
          userId: user.uid, // Ensure userId is set
        );
        return Right(createdPatient);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  Future<Either<Failure, PatientModel>> updatePatient(
      String id, PatientModel patient) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _patientsCollection.doc(id).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            return Left(ServerFailure('Document data is null', 400));
          }

          final userId = data['userId'] as String?;
          if (userId == null) {
            return Left(ServerFailure('userId field is missing or null', 400));
          }

          if (userId == user.uid) {
            final updatedData = patient.toJson();
            updatedData.remove('id'); // Exclude the `id` field from the update
            await _patientsCollection.doc(id).update(updatedData);

            return Right(patient.copyWith(id: id));
          } else {
            return Left(ServerFailure('Unauthorized', 403));
          }
        } else {
          return Left(ServerFailure('Document does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  Future<Either<Failure, void>> deletePatient(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _patientsCollection.doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final userId = data?['userId'] as String?;
          if (userId == null) {
            return Left(ServerFailure('userId field is missing or null', 400));
          }
          if (userId == user.uid) {
            await _patientsCollection.doc(id).delete();
            return const Right(null);
          } else {
            return Left(ServerFailure('Unauthorized', 403));
          }
        } else {
          return Left(ServerFailure('Document does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  Future<Either<Failure, List<PatientModel>>> searchPatients({
    String? name,
    int? minAge,
    int? maxAge,
    String? address,
    String? gender,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Query queryRef =
            _patientsCollection.where('userId', isEqualTo: user.uid);

        if (name != null && name.isNotEmpty) {
          queryRef = queryRef
              .where('name', isGreaterThanOrEqualTo: name)
              .where('name', isLessThanOrEqualTo: '$name\uf8ff');
        }

        if (minAge != null) {
          queryRef = queryRef.where('age', isGreaterThanOrEqualTo: minAge);
        }

        if (maxAge != null) {
          queryRef = queryRef.where('age', isLessThanOrEqualTo: maxAge);
        }

        if (address != null && address.isNotEmpty) {
          queryRef = queryRef.where('address', isEqualTo: address);
        }

        if (gender != null && gender.isNotEmpty) {
          queryRef = queryRef.where('gender', isEqualTo: gender);
        }

        debugPrint('Executing query: $queryRef');

        final snapshot = await queryRef.get();

        List<PatientModel> patients = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          debugPrint('Fetched patient data: $data');
          return PatientModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
          });
        }).toList();

        return Right(patients);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error in searchPatients: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  Future<Either<Failure, List<PatientModel>>> getPatientsByDate(DateTime date,
      {DocumentSnapshot? lastDocument, int limit = 20}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Query queryRef = _patientsCollection
            .where('userId', isEqualTo: user.uid)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day)))
            .where('createdAt',
                isLessThan: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day + 1)))
            .limit(limit);

        if (lastDocument != null) {
          queryRef = queryRef.startAfterDocument(lastDocument);
        }

        final snapshot = await queryRef.get();

        List<PatientModel> patients = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return PatientModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
          });
        }).toList();

        return Right(patients);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
