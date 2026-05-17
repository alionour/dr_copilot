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

  Query _applyPatientFilter(Query queryRef, User user) {
    final notifier = OwnerNotifier();

    // 1. Check if user has basic view permission
    if (!notifier.hasPermission(AppPermission.viewPatients)) {
      // If no permission, return no results
      return queryRef.where(FieldPath.documentId, isEqualTo: 'PERMISSION_DENIED');
    }

    // 2. Global Access Check
    if (notifier.hasAllDoctorsAccess ||
        notifier.hasAllDepartmentsAccess ||
        notifier.hasAllTeamsAccess) {
      return queryRef;
    }

    // 3. Association Scoping
    List<Filter> scopeFilters = [];

    if (notifier.linkedDoctorIds.isNotEmpty) {
      scopeFilters.add(
        Filter('treatingDoctorId', whereIn: notifier.linkedDoctorIds),
      );
    }

    if (notifier.departmentIds.isNotEmpty) {
      scopeFilters.add(Filter('departmentId', whereIn: notifier.departmentIds));
    }

    if (notifier.teamIds.isNotEmpty) {
      scopeFilters.add(Filter('teamId', whereIn: notifier.teamIds));
    }

    // 4. Flexible Model: If user has at least one association, also allow seeing patients with null doctor
    if (scopeFilters.isNotEmpty) {
      scopeFilters.add(Filter('treatingDoctorId', isNull: true));
    }

    // 5. Apply filters
    if (scopeFilters.isEmpty) {
      return queryRef.where(
        FieldPath.documentId,
        isEqualTo: 'NO_ASSOCIATIONS_ACCESS',
      );
    }

    if (scopeFilters.length == 1) {
      return queryRef.where(scopeFilters.first);
    } else if (scopeFilters.length == 2) {
      return queryRef.where(Filter.or(scopeFilters[0], scopeFilters[1]));
    } else if (scopeFilters.length == 3) {
      return queryRef.where(Filter.or(scopeFilters[0], scopeFilters[1], scopeFilters[2]));
    } else {
      return queryRef.where(
        Filter.or(scopeFilters[0], scopeFilters[1], scopeFilters[2], scopeFilters[3]),
      );
    }
  }


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

        queryRef = _applyPatientFilter(queryRef, user);

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
    if (!OwnerNotifier().hasPermission(AppPermission.createPatient)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        final data = patient.toJson();
        data.remove('id');
        final docRef = await _patientsCollection.add({
          ...data,
          'userId': user.uid,
          "createdBy": user.uid,
          'clinicId': clinicId,
        });
        final createdPatient = patient.copyWith(
          id: docRef.id,
          ownerId: user.uid,
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
    if (!OwnerNotifier().hasPermission(AppPermission.updatePatient)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _patientsCollection.doc(id).get();

        if (doc.exists) {
          // Apply scope check before update
          Query checkQuery =
              _patientsCollection.where(FieldPath.documentId, isEqualTo: id);
          checkQuery = _applyPatientFilter(checkQuery, user);
          final checkResult = await checkQuery.get();

          if (checkResult.docs.isEmpty) {
            return Left(ServerFailure('Access denied to this patient', 403));
          }

          final updatedData = patient.toJson();
          updatedData.remove('id');
          updatedData['updatedAt'] = Timestamp.fromDate(DateTime.now().toUtc());
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
    if (!OwnerNotifier().hasPermission(AppPermission.deletePatient)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ensure patient is within user's scope
        final doc = await _patientsCollection.doc(id).get();
        if (!doc.exists) {
          return Left(ServerFailure('Patient not found', 404));
        }

        // Apply scope check before deletion
        Query checkQuery =
            _patientsCollection.where(FieldPath.documentId, isEqualTo: id);
        checkQuery = _applyPatientFilter(checkQuery, user);
        final checkResult = await checkQuery.get();

        if (checkResult.docs.isEmpty) {
          return Left(ServerFailure('Access denied to this patient', 403));
        }

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
    String? departmentId,
    String? teamId,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef =
            _patientsCollection.where('clinicId', isEqualTo: clinicId);

        queryRef = _applyPatientFilter(queryRef, user);

        // Fetch up to 1000 clinic patients for client-side search to guarantee state resilience
        queryRef = queryRef.limit(1000);

        debugPrint('Executing search patients query: $queryRef');

        final snapshot = await queryRef.get();

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

        // Perform case-insensitive searches and bounds checking in memory
        if (name != null && name.trim().isNotEmpty) {
          final cleanQuery = name.trim().toLowerCase();
          patients = patients.where((patient) {
            return patient.name.toLowerCase().contains(cleanQuery);
          }).toList();
        }

        if (minAge != null) {
          patients = patients.where((p) => p.age != null && p.age! >= minAge).toList();
        }

        if (maxAge != null) {
          patients = patients.where((p) => p.age != null && p.age! <= maxAge).toList();
        }

        if (address != null && address.trim().isNotEmpty) {
          final cleanAddr = address.trim().toLowerCase();
          patients = patients.where((p) => p.address != null && p.address!.toLowerCase().contains(cleanAddr)).toList();
        }

        if (gender != null && gender.trim().isNotEmpty) {
          final cleanGender = gender.trim().toLowerCase();
          patients = patients.where((p) => p.gender != null && p.gender!.toLowerCase() == cleanGender).toList();
        }

        if (departmentId != null && departmentId.isNotEmpty) {
          patients = patients.where((p) => p.departmentId == departmentId).toList();
        }

        if (teamId != null && teamId.isNotEmpty) {
          patients = patients.where((p) => p.teamId == teamId).toList();
        }

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

        queryRef = _applyPatientFilter(queryRef, user);

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

        queryRef = _applyPatientFilter(queryRef, user);

        final snapshot =
            await queryRef.orderBy('createdAt', descending: true).get();

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

        query = _applyPatientFilter(query, user);

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

        queryRef = _applyPatientFilter(queryRef, user);

        final snapshot =
            await queryRef.orderBy('deletedAt', descending: true).get();

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
