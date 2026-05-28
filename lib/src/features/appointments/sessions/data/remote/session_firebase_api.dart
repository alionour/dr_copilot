import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A Firebase API implementation for managing session data in Firestore.
/// This class provides methods to perform CRUD operations on session data
/// and includes additional functionality such as fetching sessions by date
/// and detecting session types.
class SessionsFirebaseApi extends AbstractSessionsRepository {
  String? get clinicId => OwnerNotifier().clinicId;

  /// Reference to the Firestore collection for sessions.
  final CollectionReference _sessionsCollection =
      FirebaseFirestore.instance.collection('sessions');

  /// Reference to the Firestore collection for patients.
  final CollectionReference _patientsCollection =
      FirebaseFirestore.instance.collection('patients');

  /// Firebase Authentication instance for user authentication.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Checks if the user is authenticated.
  ///
  /// Returns `true` if the user is authenticated, otherwise `false`.
  Future<bool> _isAuthenticated() async {
    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    return currentUser != null;
  }

  /// Fetches a list of sessions created by the authenticated user.
  ///
  /// [lastDocumentID] is the ID of the last document fetched for pagination.
  /// [limit] specifies the maximum number of sessions to fetch.
  ///
  /// Returns a list of [SessionModel] objects or a [Failure] in case of an error.
  @override
  Future<Either<Failure, List<SessionModel>>> getSessions({
    String? lastDocumentID,
    int limit = 20,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted sessions
        queryRef = queryRef.where('deletedAt', isNull: true);

        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _sessionsCollection.doc(lastDocumentID).get();
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

        // Map the snapshot documents to a list of SessionModel objects
        List<SessionModel> sessions = await Future.wait(
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
            return SessionModel.fromJson({
              ...data,
              'id': doc.id, // Ensure the document ID is included
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );

        return Right(sessions);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Adds a new session to the Firestore collection.
  ///
  /// [sessionModel] is the session data to be added.
  ///
  /// Returns the created [SessionModel] with the generated document ID
  /// or a [Failure] in case of an error.
  @override
  Future<Either<Failure, SessionModel>> addSession(
    SessionModel sessionModel,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.createSession)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    // Check if the user is authenticated
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (clinicId == null) {
          return Left(ServerFailure('No clinic ID found', 403));
        }
        // Prepare the session data for Firestore
        final data = sessionModel.toJson();

        // Save the patient name before removing it from the data
        final patientName = data['patientName'];

        data.remove('id');
        data.remove('patientName');

        // Add the session data to the Firestore collection
        final docRef = await _sessionsCollection.add({
          ...data,
          'createdBy': user.uid,
          'doctorId': data['doctorId'] ?? user.uid,
          'clinicId': clinicId,
        });

        final createdSession = sessionModel.copyWith(
          id: docRef.id,
          createdBy: user.uid,
          doctorId: data['doctorId'] ?? user.uid,
          patientName: patientName,
        );

        return Right(createdSession);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding session: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Updates an existing session in the Firestore collection.
  ///
  /// [id] is the document ID of the session to be updated.
  /// [sessionModel] is the updated session data.
  ///
  /// Returns the updated [SessionModel] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, SessionModel>> updateSession(
    String id,
    SessionModel sessionModel,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.updateSession)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    // Check if the user is authenticated
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Apply scope check before update
        Query checkQuery =
            _sessionsCollection.where(FieldPath.documentId, isEqualTo: id);
        checkQuery = _applyScopeFilter(checkQuery, user);
        final checkResult = await checkQuery.get();

        if (checkResult.docs.isEmpty) {
          return Left(ServerFailure('Access denied to this session', 403));
        }

        final updatedData = sessionModel.toJson();
        updatedData.remove('id');
        updatedData.remove('patientName');

        await _sessionsCollection.doc(id).update(updatedData);
        return Right(sessionModel.copyWith(id: id));
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error updating session: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Deletes a session from the Firestore collection.
  ///
  /// [id] is the document ID of the session to be deleted.
  ///
  /// Returns the deleted [SessionModel] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, void>> deleteSession(String id) async {
    if (!OwnerNotifier().hasPermission(AppPermission.deleteSession)) {
      return Left(ServerFailure('Permission denied', 403));
    }
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Apply scope check before delete
        Query checkQuery =
            _sessionsCollection.where(FieldPath.documentId, isEqualTo: id);
        checkQuery = _applyScopeFilter(checkQuery, user);
        final checkResult = await checkQuery.get();

        if (checkResult.docs.isEmpty) {
          return Left(ServerFailure('Access denied to this session', 403));
        }

        // Soft delete: Update deletedAt timestamp and deletedBy
        await _sessionsCollection.doc(id).update({
          'deletedAt': Timestamp.now(),
          'deletedBy': user.uid,
        });
        debugPrint('Session with ID $id soft deleted successfully');
        return const Right(null);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting session: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, List<SessionModel>>> getDeletedSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        queryRef = _applyScopeFilter(queryRef, user);

        queryRef = queryRef
            .where('deletedAt', isNull: false)
            .orderBy('deletedAt', descending: true);

        final snapshot = await queryRef.get();

        List<SessionModel> sessions = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            final patientName = await getPatientNameById(
              data['patientId'] as String,
            );
            return SessionModel.fromJson({
              ...data,
              'id': doc.id,
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );

        return Right(sessions);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> restoreSession(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      await _sessionsCollection.doc(id).update({
        'deletedAt': null,
        'deletedBy': null,
      });
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, void>> permanentlyDeleteSession(String id) async {
    if (!await _isAuthenticated()) {
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      await _sessionsCollection.doc(id).delete();
      return Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Searches for sessions based on the provided criteria.
  ///
  /// [patientId] is the ID of the patient to filter sessions by.
  /// [name] is the name of the patient to filter sessions by (optional, will be converted to patientId(s)).
  /// [lastDocumentID] is the ID of the last document fetched for pagination.
  /// [limit] specifies the maximum number of sessions to fetch.
  ///
  /// Returns a list of [SessionModel] objects or a [Failure] in case of an error.
  @override
  Future<Either<Failure, List<SessionModel>>> searchSessions({
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
        List<String> matchedPatientIds = [];
        
        // Fetch up to 1000 clinic patients to resolve case-insensitive name matching in memory
        final patientsSnapshot = await _patientsCollection
            .where('clinicId', isEqualTo: clinicId)
            .limit(1000)
            .get();

        final patients = patientsSnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return {
            'id': doc.id,
            'name': (data?['name'] as String? ?? '').toLowerCase(),
          };
        }).toList();

        if (name != null && name.trim().isNotEmpty) {
          final cleanQuery = name.trim().toLowerCase();
          for (var p in patients) {
            final pName = p['name'] ?? '';
            if (pName.contains(cleanQuery)) {
              matchedPatientIds.add(p['id']!);
            }
          }
          if (matchedPatientIds.isEmpty) {
            return const Right([]);
          }
        } else {
          matchedPatientIds = patients.map((p) => p['id']!).toList();
        }

        Query queryRef = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted sessions
        queryRef = queryRef.where('deletedAt', isNull: true);

        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _sessionsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef.startAfterDocument(lastDocumentSnapshot);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        }

        // Limit results to keep search fast and responsive
        queryRef = queryRef.limit(200);

        final snapshot = await queryRef.get();

        List<SessionModel> sessions = await Future.wait(
          snapshot.docs.map((doc) async {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) {
              throw Exception('Document data is null');
            }
            // Fetch the patient name dynamically using the patient ID
            final patientName = await getPatientNameById(
              data['patientId'] as String,
            );
            return SessionModel.fromJson({
              ...data,
              'id': doc.id, // Ensure the document ID is included
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );

        // Filter sessions to only those that match the matched patient IDs
        sessions = sessions.where((session) {
          return matchedPatientIds.contains(session.patientId);
        }).toList();

        return Right(sessions);
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
      debugPrint('Error searching sessions: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Fetches sessions for a specific date.
  ///
  /// [date] is the date to filter sessions by.
  /// [lastDocument] is the last document fetched for pagination.
  /// [limit] specifies the maximum number of sessions to fetch.
  ///
  /// Returns a list of [SessionModel] objects or a [Failure] in case of an error.
  @override
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(
    DateTime date, {
    DocumentSnapshot? lastDocument,
    int limit = 20,
  }) async {
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
        debugPrint('Filtering sessions for user: ${user.uid} on date: $date');
        Query queryRef = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted sessions
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

        List<SessionModel> sessions = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          return SessionModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
          });
        }).toList();
        return Right(sessions);
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
      debugPrint('Error getting sessions by date: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Detects the session type for a given patient.
  ///
  /// [patientId] is the ID of the patient to detect the session type for.
  ///
  /// Returns the detected [String] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, String>> detectSessionType(String patientId) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      final querySnapshot = await _sessionsCollection
          .where('clinicId', isEqualTo: clinicId)
          .where('patientId', isEqualTo: patientId)
          .where('deletedAt', isNull: true) // Filter out deleted sessions
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Error: Document data is null');
          return Left(ServerFailure('Document data is null', 400));
        }
        final sessionTypeString = data['sessionType']
            as String?; // Changed from 'type' to 'sessionType' based on model

        if (sessionTypeString != null) {
          return Right(sessionTypeString);
        } else {
          // Fallback or default?
          // If sessionType is missing, maybe return standard?
          return Right(SessionTypePresets.standard);
        }
      } else {
        debugPrint('No sessions found for the given patientId. Defaulting to standard.');
        return const Right(SessionTypePresets.standard);
      }
    } catch (e) {
      debugPrint('Error detecting session type: $e');
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

  /// Gets a single session by its ID.
  @override
  Future<Either<Failure, SessionModel>> getSessionById(String id) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final docSnapshot = await _sessionsCollection.doc(id).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('Document data is null');
        }
        final patientName = await getPatientNameById(
          data['patientId'] as String,
        );
        return Right(
          SessionModel.fromJson({
            ...data,
            'id': docSnapshot.id,
            'patientName': patientName ?? 'No Name Available',
          }),
        );
      } else {
        return Left(ServerFailure('Session not found', 404));
      }
    } catch (e) {
      debugPrint('Error getting session by ID: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Gets all sessions without pagination.
  @override
  Future<Either<Failure, List<SessionModel>>> getAllSessions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (clinicId == null) {
        return Left(ServerFailure('No clinic ID found', 403));
      }
      if (user != null) {
        Query queryRef = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        queryRef = _applyScopeFilter(queryRef, user);

        // Filter out deleted sessions
        queryRef = queryRef.where('deletedAt', isNull: true);

        final snapshot =
            await queryRef.orderBy('startDateTime', descending: true).get();

        List<SessionModel> sessions = await Future.wait(
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
            return SessionModel.fromJson({
              ...data,
              'id': doc.id,
              'patientName': patientName ?? 'No Name Available',
            });
          }).toList(),
        );

        return Right(sessions);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Returns the count of sessions as an [int] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, int>> getSessionsCount() async {
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
        Query query = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted sessions
        query = query.where('deletedAt', isNull: true);

        final aggregateQuerySnapshot = await query.count().get();
        return Right(aggregateQuerySnapshot.count ?? 0);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error fetching session count: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Returns the count of sessions for a specific month and year.
  @override
  Future<Either<Failure, int>> getSessionsCountForMonth({
    required int year,
    required int month,
  }) async {
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
        final start = DateTime(year, month, 1);
        final end = (month < 12)
            ? DateTime(year, month + 1, 1)
            : DateTime(year + 1, 1, 1);
        Query query = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted sessions
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
      debugPrint('Error fetching session count for month: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Returns the count of sessions for a specific year.
  @override
  Future<Either<Failure, int>> getSessionsCountForYear({
    required int year,
  }) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final start = DateTime(year, 1, 1);
        final end = DateTime(year + 1, 1, 1);
        Query query = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted sessions
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
      debugPrint('Error fetching session count for year: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Sums the total price of all sessions in a specific month for the authenticated user.
  ///
  /// [year] is the year (e.g., 2025).
  /// [month] is the month (1-12).
  /// Returns the total cost as a double, or a [Failure] in case of an error.
  @override
  Future<Either<Failure, double>> sumSessionCostsForMonth({
    required int year,
    required int month,
  }) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final start = DateTime(year, month, 1);
        final end = (month < 12)
            ? DateTime(year, month + 1, 1)
            : DateTime(year + 1, 1, 1);
        Query query = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted sessions
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
      debugPrint('Error summing session costs: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Sums the total price of all sessions in a specific year for the authenticated user.
  ///
  /// [year] is the year (e.g., 2025).
  /// Returns the total cost as a double, or a [Failure] in case of an error.
  @override
  Future<Either<Failure, double>> sumSessionCostsForYear({
    required int year,
  }) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final start = DateTime(year, 1, 1);
        final end = DateTime(year + 1, 1, 1);
        Query query = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted sessions
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
      debugPrint('Error summing session costs for year: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Sums the total price of all sessions for the authenticated user (all time).
  /// Returns the total cost as a double, or a [Failure] in case of an error.
  @override
  Future<Either<Failure, double>> sumAllSessionCostsForUser() async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        Query query = _sessionsCollection.where(
          'clinicId',
          isEqualTo: clinicId,
        );

        query = _applyScopeFilter(query, user);

        // Filter out deleted sessions
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
      debugPrint('Error summing all session costs: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Applies scope-based filtering to a Firestore query for sessions.
  Query _applyScopeFilter(Query queryRef, User user) {
    final notifier = OwnerNotifier();

    // 1. Check if user has basic view permission
    if (!notifier.hasPermission(AppPermission.viewSessions)) {
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
      // Assuming sessions might have departmentId in future
      scopeFilters.add(Filter('departmentId', whereIn: notifier.departmentIds));
    }

    if (notifier.teamIds.isNotEmpty) {
      // Assuming sessions might have teamId in future
      scopeFilters.add(Filter('teamId', whereIn: notifier.teamIds));
    }

    // 4. Flexible Model: If user has at least one association, also allow seeing sessions with null doctor
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
