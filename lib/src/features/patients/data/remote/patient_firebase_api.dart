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

  List<String> _generateAccessTags(Map<String, dynamic> data) {
    List<String> tags = [];
    if (data['treatingDoctorId'] != null) {
      tags.add('doc_${data['treatingDoctorId']}');
    } else {
      tags.add('unassigned');
    }
    if (data['departmentId'] != null) {
      tags.add('dept_${data['departmentId']}');
    }
    if (data['teamId'] != null) {
      tags.add('team_${data['teamId']}');
    }
    return tags;
  }

  /// Returns the access info for the current user:
  /// - `hasGlobalAccess`: true if the user can see all patients (no tag filtering needed)
  /// - `hasNoAccess`: true if the user has no permission at all
  /// - `accessTags`: the set of tags this user is allowed to see
  ({bool hasGlobalAccess, bool hasNoAccess, Set<String> accessTags})
      _getUserAccessInfo() {
    final notifier = OwnerNotifier();

    // 1. Permission check
    if (!notifier.hasPermission(AppPermission.viewPatients)) {
      return (hasGlobalAccess: false, hasNoAccess: true, accessTags: {});
    }

    // 2. Global access (owner / all-doctors / all-departments / all-teams)
    if (notifier.hasAllDoctorsAccess ||
        notifier.hasAllDepartmentsAccess ||
        notifier.hasAllTeamsAccess) {
      return (hasGlobalAccess: true, hasNoAccess: false, accessTags: {});
    }

    // 3. Build access tag set
    final Set<String> tags = {};

    for (final id in notifier.linkedDoctorIds) {
      tags.add('doc_$id');
    }
    for (final id in notifier.departmentIds) {
      tags.add('dept_$id');
    }
    for (final id in notifier.teamIds) {
      tags.add('team_$id');
    }

    // Also allow unassigned patients when the user has any association
    if (tags.isNotEmpty) {
      tags.add('unassigned');
    }

    if (tags.isEmpty) {
      return (hasGlobalAccess: false, hasNoAccess: true, accessTags: {});
    }

    return (hasGlobalAccess: false, hasNoAccess: false, accessTags: tags);
  }

  /// Returns true if a patient document passes the in-memory access tag filter.
  bool _patientPassesFilter(
      Map<String, dynamic> data, Set<String> userAccessTags) {
    final rawTags = data['accessTags'];
    if (rawTags == null) return false;
    final List<String> patientTags =
        (rawTags as List<dynamic>).map((e) => e.toString()).toList();
    return patientTags.any((tag) => userAccessTags.contains(tag));
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
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final access = _getUserAccessInfo();
      if (access.hasNoAccess) {
        return Right(Tuple2([], null));
      }

      // KEY FIX: Do NOT use orderBy('createdAt') with where('clinicId') because
      // that combination requires a composite index (clinicId, createdAt) which
      // cannot be deployed due to network restrictions.
      //
      // Instead, mirror exactly what searchPatients does (which is proven to
      // return newest-first correctly):
      //   1. Fetch by clinicId only — NO orderBy — uses auto single-field index
      //   2. Filter accessTags in memory
      //   3. Sort by createdAt DESC in memory
      //
      // For pagination: we fetch all matching docs in one shot (up to 1000),
      // returning null as the cursor to signal no further pages are needed.
      // This prevents LoadMorePatients from issuing redundant fetches.
      final snapshot = await _patientsCollection
          .where('clinicId', isEqualTo: clinicId)
          .limit(1000)
          .get();

      // Filter accessTags in memory and parse to PatientModel
      final List<PatientModel> patients = snapshot.docs
          .where((docSnap) {
            if (access.hasGlobalAccess) return true;
            final d = docSnap.data() as Map<String, dynamic>?;
            return d != null && _patientPassesFilter(d, access.accessTags);
          })
            .map((docSnap) {
              final data = docSnap.data() as Map<String, dynamic>?;
              if (data == null) throw Exception('Document data is null');
              return PatientModel.fromJson({...data, 'id': docSnap.id});
            })
            .where((patient) => patient.deletedAt == null)
          .toList();

      // Sort newest-first entirely in memory — same proven approach as
      // searchPatients (which the user confirmed works correctly).
      patients.sort((a, b) {
        final aTime = a.createdAt;
        final bTime = b.createdAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      // Return null cursor: we fetched everything in one shot, so there is
      // nothing more to paginate. The BLoC's LoadMorePatients deduplication
      // handles any redundant scroll events gracefully.
      return Right(Tuple2(patients, null));
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
        data['accessTags'] = _generateAccessTags(data);
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
          // In-memory access check before update
          final access = _getUserAccessInfo();
          if (access.hasNoAccess) {
            return Left(ServerFailure('Access denied to this patient', 403));
          }
          if (!access.hasGlobalAccess) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null || !_patientPassesFilter(data, access.accessTags)) {
              return Left(ServerFailure('Access denied to this patient', 403));
            }
          }

          final updatedData = patient.toJson();
          updatedData.remove('id');
          updatedData['updatedAt'] = Timestamp.fromDate(DateTime.now().toUtc());
          updatedData['accessTags'] = _generateAccessTags(updatedData);
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

        // In-memory access check before deletion
        final access = _getUserAccessInfo();
        if (access.hasNoAccess) {
          return Left(ServerFailure('Access denied to this patient', 403));
        }
        if (!access.hasGlobalAccess) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null || !_patientPassesFilter(data, access.accessTags)) {
            return Left(ServerFailure('Access denied to this patient', 403));
          }
        }

        await _patientsCollection.doc(id).update({
          'deletedAt': Timestamp.fromDate(DateTime.now().toUtc()),
          'deletedBy': user.uid,
        });
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
        final access = _getUserAccessInfo();
        if (access.hasNoAccess) return Right([]);

        // Fetch up to 1000 clinic patients for client-side search
        Query queryRef = _patientsCollection
            .where('clinicId', isEqualTo: clinicId)
            .limit(1000);

        debugPrint('Executing search patients query: $queryRef');

        final snapshot = await queryRef.get();

        List<PatientModel> patients = snapshot.docs
            .where((doc) {
              if (access.hasGlobalAccess) return true;
              final d = doc.data() as Map<String, dynamic>?;
              return d != null && _patientPassesFilter(d, access.accessTags);
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) throw Exception('Document data is null');
              return PatientModel.fromJson({...data, 'id': doc.id});
            })
            .where((patient) => patient.deletedAt == null)
            .toList();

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

        patients.sort((a, b) {
          final aTime = a.createdAt;
          final bTime = b.createdAt;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

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
        final access = _getUserAccessInfo();
        if (access.hasNoAccess) return Right([]);

        final startOfMonth = DateTime(year, month, 1);
        final endOfMonth = DateTime(year, month + 1, 1);

        // Query by clinicId + date range + orderBy only (no arrayContainsAny)
        // so no composite index is required.
        Query queryRef = _patientsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('createdAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .where('createdAt', isLessThan: Timestamp.fromDate(endOfMonth))
            .orderBy('createdAt', descending: true)
            .limit(access.hasGlobalAccess ? limit : limit * 5);

        if (lastDocument != null) {
          queryRef = queryRef.startAfterDocument(lastDocument);
        }

        final snapshot = await queryRef.get();

        final List<PatientModel> patients = snapshot.docs
            .where((doc) {
              if (access.hasGlobalAccess) return true;
              final d = doc.data() as Map<String, dynamic>?;
              return d != null && _patientPassesFilter(d, access.accessTags);
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) throw Exception('Document data is null');
              return PatientModel.fromJson({...data, 'id': doc.id});
            })
            .where((patient) => patient.deletedAt == null)
            .take(limit)
            .toList();

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
        final access = _getUserAccessInfo();
        if (access.hasNoAccess) return Right([]);

        // Query by clinicId + orderBy only — no composite index needed.
        final snapshot = await _patientsCollection
            .where('clinicId', isEqualTo: clinicId)
            .orderBy('createdAt', descending: true)
            .get();

        final List<PatientModel> patients = snapshot.docs
            .where((doc) {
              if (access.hasGlobalAccess) return true;
              final d = doc.data() as Map<String, dynamic>?;
              return d != null && _patientPassesFilter(d, access.accessTags);
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) throw Exception('Document data is null');
              return PatientModel.fromJson({...data, 'id': doc.id});
            })
            .where((patient) => patient.deletedAt == null)
            .toList();

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
        final access = _getUserAccessInfo();
        if (access.hasNoAccess) return Right(0);

        // Fetch all matching docs and filter in memory to exclude soft-deleted patients
        final snapshot = await _patientsCollection
            .where('clinicId', isEqualTo: clinicId)
            .get();
        final count = snapshot.docs.where((doc) {
          if (!access.hasGlobalAccess) {
            final d = doc.data() as Map<String, dynamic>?;
            if (d == null || !_patientPassesFilter(d, access.accessTags)) {
              return false;
            }
          }
          final data = doc.data() as Map<String, dynamic>?;
          return data?['deletedAt'] == null;
        }).length;
        return Right(count);
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
        final access = _getUserAccessInfo();
        if (access.hasNoAccess) return Right([]);

        // Query by clinicId + deletedAt filter + orderBy only — no composite index needed.
        final snapshot = await _patientsCollection
            .where('clinicId', isEqualTo: clinicId)
            .where('deletedAt', isNull: false)
            .orderBy('deletedAt', descending: true)
            .get();

        final List<PatientModel> patients = snapshot.docs
            .where((doc) {
              if (access.hasGlobalAccess) return true;
              final d = doc.data() as Map<String, dynamic>?;
              return d != null && _patientPassesFilter(d, access.accessTags);
            })
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              if (data == null) throw Exception('Document data is null');
              return PatientModel.fromJson({...data, 'id': doc.id});
            })
            .toList();

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
        'deletedBy': null,
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
