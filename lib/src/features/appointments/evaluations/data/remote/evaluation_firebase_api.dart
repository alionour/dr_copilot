import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/core/services/error_reporting_service.dart';

class EvaluationsFirebaseApi extends AbstractEvaluationsRepository {
  final CollectionReference _evaluationsCollection =
      FirebaseFirestore.instance.collection('evaluations');

  /// Reference to the Firestore collection for patients.
  /// This is used to fetch patient data.
  final CollectionReference _patientsCollection =
      FirebaseFirestore.instance.collection('patients');

  String? get clinicId => OwnerNotifier().clinicId;

  Future<bool> _isAuthenticated() async {
    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    return currentUser != null;
  }

  @override
  Future<Either<Failure, List<EvaluationModel>>> getEvaluations({
    String? lastDocumentID,
    int limit = 20,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted evaluations
        queryRef = queryRef.where('deletedAt', isNull: true);

        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _evaluationsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef
                .orderBy('startDateTime', descending: true)
                .startAfterDocument(lastDocumentSnapshot)
                .limit(limit);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        } else {
          queryRef =
              queryRef.orderBy('startDateTime', descending: true).limit(limit);
        }

        final snapshot = await queryRef.get();

        List<EvaluationModel> evaluations = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            // Fetch the patient name dynamically using the patient ID
            final patientName = await getPatientNameById(
              data['patientId'] as String,
            );
            if (patientName == null) {
              debugPrint('Patient name not found for ID: ${data['patientId']}');
            }
            return EvaluationModel.fromJson({
              ...data,
              'id': doc.id, // Ensure the document ID is included
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );

        return Right(evaluations);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e, stack) {
      ErrorReportingService.reportError(e, stack);
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, EvaluationModel>> addEvaluation(
    EvaluationModel evaluationModel,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.createEvaluation)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        final data = evaluationModel.toJson();

        // Save the patient name before removing it from the data
        final patientName = data['patientName'];

        data.remove('id');
        data.remove('patientName');

        final docRef = await _evaluationsCollection.add({
          ...data,
          'createdBy': user.uid,
          'doctorId': data['doctorId'] ?? user.uid,
          'clinicId': clinicId,
        });
        final createdEvaluation = evaluationModel.copyWith(
          id: docRef.id,
          createdBy: user.uid,
          doctorId: data['doctorId'] ?? user.uid,
          patientName: patientName,
        );
        return Right(createdEvaluation);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e, stack) {
      debugPrint('Error adding evaluation: $e');
      ErrorReportingService.reportError(e, stack);
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, EvaluationModel>> updateEvaluation(
    String id,
    EvaluationModel evaluationModel,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.updateEvaluation)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Apply scope check before update
        Query checkQuery =
            _evaluationsCollection.where(FieldPath.documentId, isEqualTo: id);
        checkQuery = _applyScopeFilter(checkQuery, user);
        final checkResult = await checkQuery.get();

        if (checkResult.docs.isEmpty) {
          return Left(ServerFailure('Access denied to this evaluation', 403));
        }

        final updatedData = evaluationModel.toJson();
        updatedData.remove('id');
        updatedData.remove('patientName');

        await _evaluationsCollection.doc(id).update(updatedData);
        return Right(evaluationModel.copyWith(id: id));
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e, stack) {
      debugPrint('Error updating evaluation: $e');
      ErrorReportingService.reportError(e, stack);
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> deleteEvaluation(String id) async {
    if (!OwnerNotifier().hasPermission(AppPermission.deleteEvaluation)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Apply scope check before delete
        Query checkQuery =
            _evaluationsCollection.where(FieldPath.documentId, isEqualTo: id);
        checkQuery = _applyScopeFilter(checkQuery, user);
        final checkResult = await checkQuery.get();

        if (checkResult.docs.isEmpty) {
          return Left(ServerFailure('Access denied to this evaluation', 403));
        }

        // Soft delete: Update deletedAt timestamp and deletedBy
        await _evaluationsCollection.doc(id).update({
          'deletedAt': Timestamp.now(),
          'deletedBy': user.uid,
        });
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e, stack) {
      debugPrint('Error deleting evaluation: $e');
      ErrorReportingService.reportError(e, stack);
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, List<EvaluationModel>>> getDeletedEvaluations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        queryRef = _applyScopeFilter(queryRef, user);

        queryRef = queryRef
            .where('deletedAt', isNull: false)
            .orderBy('deletedAt', descending: true);

        final snapshot = await queryRef.get();

        List<EvaluationModel> evaluations = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            final patientName = await getPatientNameById(
              data['patientId'] as String,
            );
            return EvaluationModel.fromJson({
              ...data,
              'id': doc.id,
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );

        return Right(evaluations);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> restoreEvaluation(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      await _evaluationsCollection.doc(id).update({
        'deletedAt': null,
        'deletedBy': null,
      });
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> permanentlyDeleteEvaluation(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      await _evaluationsCollection.doc(id).delete();
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Fetches evaluations based on search criteria.
  @override
  Future<Either<Failure, List<EvaluationModel>>> searchEvaluations({
    String? name,
    String? lastDocumentID,
    int limit = 20,
  }) async {
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
        List<String> patientIds = [];
        if (name != null && name.isNotEmpty) {
          // 1. Find patient IDs by name
          final patientsSnapshot = await _patientsCollection
              .where('clinicId', isEqualTo: clinicId)
              .where('name', isGreaterThanOrEqualTo: name)
              .where('name', isLessThanOrEqualTo: '$name\uf8ff')
              .get();
          patientIds = patientsSnapshot.docs.map((doc) => doc.id).toList();
          if (patientIds.isEmpty) {
            // No patients found, return empty result
            return Right([]);
          }
        }

        Query queryRef = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        // Filter by doctorId if the user does not have permission to view all evaluations
        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted evaluations
        queryRef = queryRef.where('deletedAt', isNull: true);

        if (patientIds.isNotEmpty) {
          // Firestore whereIn supports max 10 items, so take first 10
          queryRef = queryRef.where(
            'patientId',
            whereIn: patientIds.take(10).toList(),
          );
        }

        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _evaluationsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef.startAfterDocument(lastDocumentSnapshot);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        }

        final snapshot = await queryRef.get();

        List<EvaluationModel> evaluations = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            // Fetch the patient name dynamically using the patient ID
            final patientName = await getPatientNameById(
              data['patientId'] as String,
            );
            if (patientName == null) {
              debugPrint(
                'Patient name not found for ID: \\${data['patientId']}',
              );
            }
            return EvaluationModel.fromJson({
              ...data,
              'id': doc.id, // Ensure the document ID is included
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );
        return Right(evaluations);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('Firestore index required: ${e.message}');
        return Left(
          ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400,
          ),
        );
      }
      debugPrint('Error searching evaluations: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, List<EvaluationModel>>> getEvaluationsByDate(
    DateTime date, {
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
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
        debugPrint(
          'Filtering evaluations for user: ${user.uid} on date: $date',
        );
        Query queryRef = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        // Filter by doctorId if the user does not have permission to view all evaluations
        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted evaluations
        queryRef = queryRef.where('deletedAt', isNull: true);

        queryRef = queryRef
            .where(
              'startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                DateTime(date.year, date.month, date.day),
              ),
            )
            .where(
              'startDateTime',
              isLessThan: Timestamp.fromDate(
                DateTime(date.year, date.month, date.day + 1),
              ),
            )
            .limit(limit);

        if (lastDocument != null) {
          debugPrint('Using lastDocument for pagination');
          queryRef = queryRef.startAfterDocument(lastDocument);
        }

        final snapshot = await queryRef.get();
        debugPrint('Query returned ${snapshot.docs.length} documents');

        List<EvaluationModel> evaluations = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return EvaluationModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
          });
        }).toList();
        return Right(evaluations);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('Firestore index required: ${e.message}');
        return Left(
          ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400,
          ),
        );
      }
      debugPrint('Error getting evaluations by date: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Fetches the name of a patient by their ID.
  ///
  /// [patientId] is the ID of the patient to fetch the name for.
  ///
  /// Returns the patient's name as a [String] or `null` if not found.
  Future<String?> getPatientNameById(String patientId) async {
    try {
      final docSnapshot = await _patientsCollection.doc(patientId).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        if (data != null && data['name'] != null) {
          return data['name'] as String;
        } else {
          debugPrint(
            'Patient document found but name is missing for ID: $patientId',
          );
        }
      } else {
        debugPrint('No patient document found for ID: $patientId');
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching patient name for ID $patientId: $e');
      return null;
    }
  }

  /// Gets all evaluations without pagination.
  @override
  Future<Either<Failure, List<EvaluationModel>>> getAllEvaluations() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        // Filter by doctorId if the user does not have permission to view all evaluations
        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted evaluations
        queryRef = queryRef.where('deletedAt', isNull: true);

        final snapshot =
            await queryRef.orderBy('startDateTime', descending: true).get();

        List<EvaluationModel> evaluations = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            final patientName = await getPatientNameById(
              data['patientId'] as String,
            );
            if (patientName == null) {
              debugPrint('Patient name not found for ID: ${data['patientId']}');
            }
            return EvaluationModel.fromJson({
              ...data,
              'id': doc.id,
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );

        return Right(evaluations);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Gets a single evaluation by its ID.
  @override
  Future<Either<Failure, EvaluationModel>> getEvaluationById(String id) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final docSnapshot = await _evaluationsCollection.doc(id).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Document data is null');
        }
        final patientName = await getPatientNameById(
          data['patientId'] as String,
        );
        return Right(
          EvaluationModel.fromJson({
            ...data,
            'id': docSnapshot.id,
            'patientName': patientName ?? 'No Name Available',
          }),
        );
      } else {
        return Left(ServerFailure('Evaluation not found', 404));
      }
    } catch (e) {
      debugPrint('Error getting evaluation by ID: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, int>> getEvaluationsCount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query query = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted evaluations
        query = query.where('deletedAt', isNull: true);

        final snapshot = await query.count().get();
        return Right(snapshot.count ?? 0);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Gets the count of evaluations for a specific month and year.
  @override
  Future<Either<Failure, int>> getEvaluationsCountForMonth({
    required int year,
    required int month,
  }) async {
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
        final start = DateTime(year, month, 1);
        final end = (month < 12)
            ? DateTime(year, month + 1, 1)
            : DateTime(year + 1, 1, 1);
        Query query = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted evaluations
        query = query.where('deletedAt', isNull: true);

        query = query
            .where(
              'startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('startDateTime', isLessThan: Timestamp.fromDate(end));
        final aggregateQuerySnapshot = await query.count().get();
        return Right(aggregateQuerySnapshot.count ?? 0);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching evaluation count for month: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Gets the count of evaluations for a specific year.
  @override
  Future<Either<Failure, int>> getEvaluationsCountForYear({
    required int year,
  }) async {
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
        final start = DateTime(year, 1, 1);
        final end = DateTime(year + 1, 1, 1);
        Query query = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted evaluations
        query = query.where('deletedAt', isNull: true);

        query = query
            .where(
              'startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('startDateTime', isLessThan: Timestamp.fromDate(end));
        final aggregateQuerySnapshot = await query.count().get();
        return Right(aggregateQuerySnapshot.count ?? 0);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching evaluation count for year: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Sums the total price of all evaluations in a specific month for the authenticated user.
  @override
  Future<Either<Failure, double>> sumEvaluationCostsForMonth({
    required int year,
    required int month,
  }) async {
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
        final start = DateTime(year, month, 1);
        final end = (month < 12)
            ? DateTime(year, month + 1, 1)
            : DateTime(year + 1, 1, 1);
        Query query = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted evaluations
        query = query.where('deletedAt', isNull: true);

        query = query
            .where(
              'startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('startDateTime', isLessThan: Timestamp.fromDate(end));
        final aggregateQuerySnapshot =
            await query.aggregate(sum('price')).get();
        final endSum = aggregateQuerySnapshot.getSum('price') ?? 0;
        return Right(
          endSum is int ? endSum.toDouble() : (endSum as double? ?? 0.0),
        );
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error summing evaluation costs: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Sums the total price of all evaluations in a specific year for the authenticated user.
  @override
  Future<Either<Failure, double>> sumEvaluationCostsForYear({
    required int year,
  }) async {
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
        final start = DateTime(year, 1, 1);
        final end = DateTime(year + 1, 1, 1);
        Query query = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted evaluations
        query = query.where('deletedAt', isNull: true);

        query = query
            .where(
              'startDateTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start),
            )
            .where('startDateTime', isLessThan: Timestamp.fromDate(end));
        final aggregateQuerySnapshot =
            await query.aggregate(sum('price')).get();
        final endSum = aggregateQuerySnapshot.getSum('price') ?? 0;
        return Right(
          endSum is int ? endSum.toDouble() : (endSum as double? ?? 0.0),
        );
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error summing evaluation costs for year: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Sums the total price of all evaluations for the authenticated user (all time).
  @override
  Future<Either<Failure, double>> sumAllEvaluationCostsForUser() async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Query query = _evaluationsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        // Filter by doctorId if the user does not have permission to view all evaluations
        if (!OwnerNotifier().hasPermission(AppPermission.viewEvaluations)) {
          query = query.where('doctorId', isEqualTo: user.uid);
        }

        // Filter out deleted evaluations
        query = query.where('deletedAt', isNull: true);

        final aggregateQuerySnapshot =
            await query.aggregate(sum('price')).get();
        final endSum = aggregateQuerySnapshot.getSum('price') ?? 0;
        return Right(
          endSum is int ? endSum.toDouble() : (endSum as double? ?? 0.0),
        );
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error summing all evaluation costs: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Applies scope-based filtering to a Firestore query for evaluations.
  Query _applyScopeFilter(Query queryRef, User user) {
    final notifier = OwnerNotifier();

    // 1. Check if user has basic view permission
    if (!notifier.hasPermission(AppPermission.viewEvaluations)) {
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
      scopeFilters.add(Filter('doctorId', whereIn: notifier.linkedDoctorIds));
    }

    if (notifier.departmentIds.isNotEmpty) {
      scopeFilters.add(Filter('departmentId', whereIn: notifier.departmentIds));
    }

    if (notifier.teamIds.isNotEmpty) {
      scopeFilters.add(Filter('teamId', whereIn: notifier.teamIds));
    }

    // 4. Flexible Model: If user has at least one association, also allow seeing evaluations with null doctor
    if (scopeFilters.isNotEmpty) {
      scopeFilters.add(Filter('doctorId', isNull: true));
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
      return queryRef.where(Filter.or(
        scopeFilters[0],
        scopeFilters[1],
        scopeFilters[2],
        scopeFilters[3],
      ));
    }
  }
}
