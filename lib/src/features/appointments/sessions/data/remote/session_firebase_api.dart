import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A Firebase API implementation for managing session data in Firestore.
/// This class provides methods to perform CRUD operations on session data
/// and includes additional functionality such as fetching sessions by date
/// and detecting session types.
class SessionFirebaseApi extends AbstractSessionsRepository {
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
  Future<Either<Failure, List<SessionModel>>> getSessions(
      {String? lastDocumentID, int limit = 20}) async {
    // Check if the user is authenticated
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Initialize the query to fetch sessions created by the authenticated user
        Query queryRef = _sessionsCollection
            .where('createdBy', isEqualTo: user.uid)
            .limit(limit);

        // If a last document ID is provided, use it for pagination
        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _sessionsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef.startAfterDocument(lastDocumentSnapshot);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        }

        // Execute the query and fetch the snapshot
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
    } on FirebaseException catch (e) {
      // Handle Firestore-specific exceptions
      if (e.code == 'failed-precondition') {
        debugPrint('Firestore index required: ${e.message}');
        return Left(ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400));
      }
      debugPrint('Error getting sessions: $e');
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
  /// [lastDocumentID] is the ID of the last document fetched for pagination.
  /// [limit] specifies the maximum number of sessions to fetch.
  ///
  /// Returns a list of [SessionModel] objects or a [Failure] in case of an error.
  @override
  Future<Either<Failure, List<SessionModel>>> searchSessions(
      {String? patientId, String? lastDocumentID, int limit = 20}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        Query queryRef =
            _sessionsCollection.where('createdBy', isEqualTo: user.uid);

        if (patientId != null && patientId.isNotEmpty) {
          queryRef = queryRef
              .where('patientId', isGreaterThanOrEqualTo: patientId)
              .where('patientId', isLessThanOrEqualTo: '$patientId\uf8ff');
        }

        if (lastDocumentID != null) {
          final lastDocumentSnapshot =
              await _sessionsCollection.doc(lastDocumentID).get();
          if (lastDocumentSnapshot.exists) {
            queryRef = queryRef.startAfterDocument(lastDocumentSnapshot);
          } else {
            throw Exception('Document with ID $lastDocumentID does not exist');
          }
        }
        final snapshot = await queryRef.get();

        List<SessionModel> sessions = snapshot.docs
            .map((doc) =>
                SessionModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
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
            .where('createdBy', isEqualTo: user.uid)
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
}
