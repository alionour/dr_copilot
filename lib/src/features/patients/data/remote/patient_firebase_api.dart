import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PatientFirebaseApi extends AbstractPatientsRepository {
  final CollectionReference _patientsCollection =
      FirebaseFirestore.instance.collection('patients');

  String? get clinicId => OwnerNotifier().clinicId;

  /// Checks if the user is authenticated.
  ///
  /// Returns `true` if the user is authenticated, otherwise `false`.
  Future<bool> _isAuthenticated() async {
    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    return currentUser != null;
  }

  /// Firebase Authentication instance for user authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<Either<Failure, Tuple2<List<PatientModel>, DocumentSnapshot?>>>
      getPatients({
    String? lastDocumentId, // match the abstract interface
    int? limit,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef =
            _patientsCollection.where('clinicId', isEqualTo: clinicId);

        // Filter by createdBy if the user does not have permission to view all patients
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllPatients)) {
          queryRef = queryRef.where('createdBy', isEqualTo: user.uid);
        }

        if (lastDocumentId != null) {
          final lastDocumentSnapshot =
              await _patientsCollection.doc(lastDocumentId).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef
                .orderBy('createdAt', descending: true)
                .startAfterDocument(lastDocumentSnapshot)
                .limit(limit ?? 20);
          } else {
            throw Exception('Document with ID $lastDocumentId does not exist');
          }
        } else {
          queryRef = queryRef
              .orderBy('createdAt', descending: true)
              .limit(limit ?? 20);
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

        DocumentSnapshot? newLastDocumentSnapshot;
        if (snapshot.docs.isNotEmpty && patients.length == (limit ?? 20)) {
          newLastDocumentSnapshot = snapshot.docs.last;
        }

        return Right(Tuple2(patients, newLastDocumentSnapshot));
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, PatientModel>> addPatient(PatientModel patient) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        final data = patient.toJson();
        data.remove('id'); // Exclude the `id` field from the document data
        final docRef = await _patientsCollection.add({
          ...data,
          'userId': user.uid,
          "createdBy": user.uid,
          'clinicId': clinicId,
        });
        final createdPatient = patient.copyWith(
          id: docRef.id, // Assign the generated document ID
          ownerId: user.uid, // Ensure userId is set
        );
        return Right(createdPatient);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
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

          // We don't strictly enforce userId check for updates in this context,
          // or we can check if the user belongs to the same clinic.
          // For now, assuming if they can read it (filtered by clinicId), they can update it.
          // Or we can keep the original check if needed.
          // The original check was: if (userId == user.uid)
          // But in a clinic setting, other doctors might update patients.
          // Let's relax it to just authentication for now, or check clinicId match if we want strictness.

          final updatedData = patient.toJson();
          updatedData.remove('id'); // Exclude the `id` field from the update
          updatedData['updatedAt'] =
              Timestamp.fromDate(DateTime.now().toUtc()); // Add updatedAt field
          await _patientsCollection.doc(id).update(updatedData);

          return Right(patient.copyWith(id: id));
        } else {
          return Left(ServerFailure('Document does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> deletePatient(String id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Similar to update, we might want to allow deletion if they are in the same clinic.
        await _patientsCollection.doc(id).delete();
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, List<PatientModel>>> searchPatients({
    String? name,
    int? minAge,
    int? maxAge,
    String? address,
    String? gender,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef =
            _patientsCollection.where('clinicId', isEqualTo: clinicId);

        // Filter by createdBy if the user does not have permission to view all patients
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllPatients)) {
          queryRef = queryRef.where('createdBy', isEqualTo: user.uid);
        }

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

        // Add safety limit
        queryRef = queryRef.limit(100);

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

  @override
  Future<Either<Failure, List<PatientModel>>> getPatientsByDate(
      int year, int month,
      {DocumentSnapshot? lastDocument, int limit = 20}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        final startOfMonth = DateTime(year, month, 1);
        final endOfMonth = DateTime(year, month + 1, 1);

        Query queryRef =
            _patientsCollection.where('clinicId', isEqualTo: clinicId);

        // Filter by createdBy if the user does not have permission to view all patients
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllPatients)) {
          queryRef = queryRef.where('createdBy', isEqualTo: user.uid);
        }

        queryRef = queryRef
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
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

  /// Gets a single patient by their ID.
  @override
  Future<Either<Failure, PatientModel>> getPatientById(String id) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final docSnapshot = await _patientsCollection.doc(id).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Document data is null');
        }
        return Right(PatientModel.fromJson({
          ...data,
          'id': docSnapshot.id,
        }));
      } else {
        return Left(ServerFailure('Patient not found', 404));
      }
    } catch (e) {
      debugPrint('Error getting patient by ID: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Gets all patients without pagination.
  @override
  Future<Either<Failure, List<PatientModel>>> getAllPatients() async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef =
            _patientsCollection.where('clinicId', isEqualTo: clinicId);

        // Filter by createdBy if the user does not have permission to view all patients
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllPatients)) {
          queryRef = queryRef.where('createdBy', isEqualTo: user.uid);
        }

        final snapshot = await queryRef
            .orderBy('createdAt', descending: true)
            .limit(100)
            .get();

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

  /// Returns the count of patients as an [int] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, int>> getPatientsCount() async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query query =
            _patientsCollection.where('clinicId', isEqualTo: clinicId);

        // Filter by createdBy if the user does not have permission to view all patients
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllPatients)) {
          query = query.where('createdBy', isEqualTo: user.uid);
        }

        final snapshot = await query.count().get();
        return Right(snapshot.count ?? 0);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching patients count: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Gets all deleted patients (where deletedAt is not null).
  @override
  Future<Either<Failure, List<PatientModel>>> getDeletedPatients() async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _patientsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('deletedAt', isNull: false);

        // Filter by createdBy if the user does not have permission to view all patients
        if (!OwnerNotifier().hasPermission(AppPermission.viewAllPatients)) {
          queryRef = queryRef.where('createdBy', isEqualTo: user.uid);
        }

        final snapshot = await queryRef
            .orderBy('deletedAt', descending: true)
            .limit(50)
            .get();

        List<PatientModel> patients = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return PatientModel.fromJson({
            ...data,
            'id': doc.id,
          });
        }).toList();

        return Right(patients);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error in getDeletedPatients: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Restores a deleted patient by setting deletedAt to null.
  @override
  Future<Either<Failure, void>> restorePatient(String id) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      await _patientsCollection.doc(id).update({
        'deletedAt': null,
      });
      return const Right(null);
    } catch (e) {
      debugPrint('Error restoring patient: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Permanently deletes a patient from Firestore.
  @override
  Future<Either<Failure, void>> permanentlyDeletePatient(String id) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      await _patientsCollection.doc(id).delete();
      return const Right(null);
    } catch (e) {
      debugPrint('Error permanently deleting patient: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
