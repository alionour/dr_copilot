import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SessionFirebaseApi extends AbstractSessionsRepository {
  final CollectionReference _sessionsCollection =
      FirebaseFirestore.instance.collection('sessions');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _isAuthenticated() async {
    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    return currentUser != null;
  }

  @override
  Future<Either<Failure, List<SessionModel>>> getSessions(
      {String? lastDocumentID, int limit = 20}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        Query queryRef = _sessionsCollection
            .where('createdBy', isEqualTo: user.uid)
            .limit(limit);

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
      debugPrint('Error getting sessions: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, SessionModel>> addSession(
      SessionModel sessionModel) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final data = sessionModel.toJson();
        data.remove('id'); // Exclude the `id` field from the document data
        final docRef = await _sessionsCollection.add({
          ...data,
          'createdBy': user.uid,
        });
        final createdSession = sessionModel.copyWith(
          id: docRef.id, // Assign the generated document ID
          createdBy: user.uid, // Ensure createdBy is set
        );
        return Right(createdSession);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding session: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, SessionModel>> updateSession(
      String id, SessionModel sessionModel) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Fetching document with ID: $id');
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

          if (createdBy == user.uid) {
            final updatedData = sessionModel.toJson();
            updatedData.remove('id'); // Exclude the `id` field from the update
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
      debugPrint('Error updating session: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, SessionModel>> deleteSession(String id) async {
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
          final createdBy = data?['createdBy'] as String?;
          if (createdBy == null) {
            debugPrint(
                'Error: createdBy field is missing or null in the document');
            return Left(
                ServerFailure('createdBy field is missing or null', 400));
          }
          if (createdBy == user.uid) {
            await _sessionsCollection.doc(id).delete();
            return Right(SessionModel.fromJson({
              ...data!,
              'id': id, // Include the document ID
            }));
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

  /// Fetches sessions based on search criteria.
  @override
  Future<Either<Failure, List<SessionModel>>> searchSessions({String? name,
      String? lastDocumentID, int limit = 20}) async {
    
    
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      
      final user = _auth.currentUser;
      if (user != null) {
          Query queryRef =
            _sessionsCollection.where('createdBy', isEqualTo: user.uid);

        if (name != null && name.isNotEmpty) {
          queryRef = queryRef
              .where('patientName', isGreaterThanOrEqualTo: name)
              .where('patientName', isLessThanOrEqualTo: '$name\uf8ff');
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
            .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(date.year, date.month, date.day)))
            .where('startDateTime', isLessThan: Timestamp.fromDate(DateTime(date.year, date.month, date.day + 1)))
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
}
