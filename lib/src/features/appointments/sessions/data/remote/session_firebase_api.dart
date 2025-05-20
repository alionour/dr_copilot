import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/bigquery/v2.dart';

/// A Firebase API implementation for managing session data in Firestore.
/// This class provides methods to perform CRUD operations on session data
/// and includes additional functionality such as fetching sessions by date
/// and detecting session types.
class SessionsFirebaseApi extends AbstractSessionsRepository {

  final ownerId = OwnerNotifier().ownerId; 
  
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
      if (user != null) {
        Query queryRef;
        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _sessionsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = _sessionsCollection
                .where('ownerId', isEqualTo: ownerId)
                .orderBy('startDateTime', descending: true)
                .startAfterDocument(lastDocumentSnapshot)
                .limit(limit);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        } else {
          queryRef = _sessionsCollection
              .where('ownerId', isEqualTo: ownerId)
              .orderBy('startDateTime', descending: true)
              .limit(limit);
        }

        final snapshot = await queryRef.get();

        // Map the snapshot documents to a list of SessionModel objects
        List<SessionModel> sessions =
            await Future.wait(snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          // Fetch the patient name dynamically using the patient ID
          final patientName =
              await getPatientNameById(data['patientId'] as String);
          if (patientName == null) {
            debugPrint('Patient name not found for ID: ${data['patientId']}');
          }
          return SessionModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
            'patientName': patientName ?? 'No Name Available',
          });
        }).toList());

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
      SessionModel sessionModel) async {
    // Check if the user is authenticated
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Prepare the session data for Firestore
        final data = sessionModel.toJson();

        // Save the patient name before removing it from the data
        final patientName = data['patientName'];

        // Remove the `id` field because Firestore generates a unique ID for each document.
        data.remove('id');

        // Remove the `patientName` field because only the `patientId` is stored in Firestore.
        data.remove('patientName');

        // Add the session data to the Firestore collection
        final docRef = await _sessionsCollection.add({
          ...data,
          'createdBy': user.uid,
        });

        // Create a new SessionModel with the generated document ID and patientName
        final createdSession = sessionModel.copyWith(
          id: docRef.id, // Assign the generated document ID
          createdBy: user.uid, // Ensure createdBy is set
          patientName:
              patientName, // Include the patient name in the returned model
        );

        return Right(createdSession);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      // Handle general exceptions
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
      String id, SessionModel sessionModel) async {
    // Check if the user is authenticated
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Fetching document with ID: $id');
        // Fetch the document to be updated
        final doc = await _sessionsCollection.doc(id).get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            debugPrint('Error: Document data is null');
            return Left(ServerFailure('Document data is null', 400));
          }

          final createdBy = data['createdBy'] as String?;
          if (createdBy == null) {
            debugPrint(
                'Error: createdBy field is missing or null in the document');
            return Left(
                ServerFailure('createdBy field is missing or null', 400));
          }

          // Check if the authenticated user is authorized to update the document
          if (createdBy == user.uid) {
            final updatedData = sessionModel.toJson();

            // Remove the `id` field because Firestore does not allow updating the document ID.
            updatedData.remove('id');

            // Remove the `patientName` field because only the `patientId` is stored in Firestore.
            // The `patientName` is dynamically fetched when needed to ensure data consistency.
            updatedData.remove('patientName');

            // Update the document in Firestore
            await _sessionsCollection.doc(id).update(updatedData);

            return Right(sessionModel.copyWith(id: id));
          } else {
            debugPrint(
                'Error: Unauthorized access. createdBy: $createdBy, user.uid: ${user.uid}');
            return Left(ServerFailure('Unauthorized', 403));
          }
        } else {
          debugPrint('Error: Document does not exist');
          return Left(ServerFailure('Document does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      // Handle general exceptions
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
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _sessionsCollection.doc(id).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          debugPrint('Session data to delete: $data'); // Log the document data

          if (data == null) {
            debugPrint('Error: Document data is null');
            return Left(ServerFailure('Document data is null', 400));
          }

          // Validate all required fields
          final createdBy = data['createdBy']?.toString();

          if (createdBy == user.uid) {
            await _sessionsCollection.doc(id).delete();
            debugPrint('Session with ID $id deleted successfully');
            return Right(null); // Return void on successful deletion
          } else {
            debugPrint(
                'Error: Unauthorized access. createdBy: $createdBy, user.uid: ${user.uid}');
            return Left(ServerFailure('Unauthorized', 403));
          }
        } else {
          debugPrint('Error: Document does not exist');
          return Left(ServerFailure('Document does not exist', 404));
        }
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error deleting session: $e');
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
   @override
  Future<Either<Failure, List<SessionModel>>> searchSessions({String? name, String? lastDocumentID, int limit = 20}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        List<String> patientIds = [];
        if (name != null && name.isNotEmpty) {
          // 1. Find patient IDs by name
          final patientsSnapshot = await _patientsCollection
              .where('name', isGreaterThanOrEqualTo: name)
              .where('name', isLessThanOrEqualTo: '$name\uf8ff')
              .get();
          patientIds = patientsSnapshot.docs.map((doc) => doc.id).toList();
          if (patientIds.isEmpty) {
            // No patients found, return empty result
            return Right([]);
          }
        }

        Query queryRef = _sessionsCollection.where('ownerId', isEqualTo: ownerId);
        if (patientIds.isNotEmpty) {
          // Firestore whereIn supports max 10 items, so take first 10
          queryRef = queryRef.where('patientId', whereIn: patientIds.take(10).toList());
        }

        if (lastDocumentID != null) {
          final lastDocumentSnapshot = await _sessionsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef.startAfterDocument(lastDocumentSnapshot);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        }

        final snapshot = await queryRef.get();

        List<SessionModel> sessions = await Future.wait(snapshot.docs.map((doc) async {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            throw Exception('Document data is null');
          }
          // Fetch the patient name dynamically using the patient ID
          final patientName = await getPatientNameById(data['patientId'] as String);
          if (patientName == null) {
            debugPrint('Patient name not found for ID: \\${data['patientId']}');
          }
          return SessionModel.fromJson({
            ...data,
            'id': doc.id, // Ensure the document ID is included
            'patientName': patientName ?? 'No Name Available',
          });
        }).toList());
        return Right(sessions);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        debugPrint('Firestore index required: ${e.message}');
        return Left(ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400));
      }
      debugPrint('Error searching evaluations: $e');
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
  Future<Either<Failure, List<SessionModel>>> getSessionsByDate(DateTime date,
      {DocumentSnapshot? lastDocument, int limit = 20}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Filtering sessions for user: ${user.uid} on date: $date');
        Query queryRef = _sessionsCollection
            .where('ownerId', isEqualTo: ownerId)
            .where('startDateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day)))
            .where('startDateTime',
                isLessThan: Timestamp.fromDate(
                    DateTime(date.year, date.month, date.day + 1)))
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
        return Left(ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400));
      }
      debugPrint('Error getting sessions by date: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Detects the session type for a given patient.
  ///
  /// [patientId] is the ID of the patient to detect the session type for.
  ///
  /// Returns the detected [SessionType] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, SessionType>> detectSessionType(
      String patientId) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final querySnapshot = await _sessionsCollection
          .where('patientId', isEqualTo: patientId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>?;
        if (data == null) {
          debugPrint('Error: Document data is null');
          return Left(ServerFailure('Document data is null', 400));
        }
        final sessionTypeString = data['type'] as String?;

        if (sessionTypeString != null) {
          try {
            final sessionType = SessionType.values.firstWhere(
              (type) => type.text == sessionTypeString,
              orElse: () => throw Exception('Invalid session type'),
            );
            return Right(sessionType);
          } catch (e) {
            debugPrint('Error: Invalid session type - $e');
            return Left(ServerFailure('Invalid session type', 400));
          }
        } else {
          debugPrint('Error: Session type is missing or null');
          return Left(ServerFailure('Session type is missing or null', 400));
        }
      } else {
        debugPrint('Error: No sessions found for the given patientId');
        return Left(
            ServerFailure('No sessions found for the given patientId', 404));
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
              'Patient document found but name is missing for ID: $patientId');
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

  /// Returns the count of sessions as an [int] or a [Failure] in case of an error.
  @override
  Future<Either<Failure, int>> getSessionsCount() async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final query = _sessionsCollection.where('ownerId', isEqualTo: ownerId);
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
  Future<Either<Failure, int>> getSessionsCountForMonth(
      {required int year, required int month}) async {
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
        final query = _sessionsCollection
            .where('ownerId', isEqualTo: ownerId)
            .where('startDateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
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
  Future<Either<Failure, int>> getSessionsCountForYear(
      {required int year}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final start = DateTime(year, 1, 1);
        final end = DateTime(year + 1, 1, 1);
        final query = _sessionsCollection
            .where('ownerId', isEqualTo: ownerId)
            .where('startDateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
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
  Future<Either<Failure, double>> sumSessionCostsForMonth(
      {required int year, required int month}) async {
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
        final query = _sessionsCollection
            .where('ownerId', isEqualTo: ownerId)
            .where('startDateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('startDateTime', isLessThan: Timestamp.fromDate(end));
        final aggregateQuerySnapshot =
            await query.aggregate(sum('price')).get();
        final endSum = aggregateQuerySnapshot.getSum('price') ?? 0;
        return Right(
            endSum is int ? endSum.toDouble() : (endSum as double? ?? 0.0));
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
  Future<Either<Failure, double>> sumSessionCostsForYear(
      {required int year}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final start = DateTime(year, 1, 1);
        final end = DateTime(year + 1, 1, 1);
        final query = _sessionsCollection
            .where('ownerId', isEqualTo: ownerId)
            .where('startDateTime',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('startDateTime', isLessThan: Timestamp.fromDate(end));
        final aggregateQuerySnapshot =
            await query.aggregate(sum('price')).get();
        final endSum = aggregateQuerySnapshot.getSum('price') ?? 0;
        return Right(
            endSum is int ? endSum.toDouble() : (endSum as double? ?? 0.0));
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
        final query = _sessionsCollection.where('ownerId', isEqualTo: ownerId);
        final aggregateQuerySnapshot =
            await query.aggregate(sum('price')).get();
        final endSum = aggregateQuerySnapshot.getSum('price') ?? 0;
        return Right(
            endSum is int ? endSum.toDouble() : (endSum as double? ?? 0.0));
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error summing all session costs: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
