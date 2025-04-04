import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class EvaluationFirebaseApi extends AbstractEvaluationsRepository {
  final CollectionReference _evaluationsCollection =
      FirebaseFirestore.instance.collection('evaluations');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<bool> _isAuthenticated() async {
    final currentUser = await FirebaseAuth.instance.authStateChanges().first;
    return currentUser != null;
  }

  @override
  Future<Either<Failure, List<EvaluationModel>>> getEvaluations(
      {String? lastDocumentID, int limit = 20}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        Query queryRef = _evaluationsCollection
            .where('createdBy', isEqualTo: user.uid)
            .limit(limit);

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
        return Left(ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400));
      }
      debugPrint('Error getting evaluations: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, EvaluationModel>> addEvaluation(
      EvaluationModel evaluationModel) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final data = evaluationModel.toJson();
        data.remove('id'); // Exclude the `id` field from the document data
        final docRef = await _evaluationsCollection.add({
          ...data,
          'createdBy': user.uid,
        });
        final createdEvaluation = evaluationModel.copyWith(
          id: docRef.id, // Assign the generated document ID
          createdBy: user.uid, // Ensure createdBy is set
        );
        return Right(createdEvaluation);
      }
      return Left(ServerFailure('User not authenticated', 401));
    } catch (e) {
      debugPrint('Error adding evaluation: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, EvaluationModel>> updateEvaluation(
      String id, EvaluationModel evaluationModel) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Fetching document with ID: $id');
        final doc = await _evaluationsCollection.doc(id).get();

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
            final updatedData = evaluationModel.toJson();
            updatedData.remove('id'); // Exclude the `id` field from the update
            await _evaluationsCollection.doc(id).update(updatedData);

            return Right(evaluationModel.copyWith(id: id));
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
      debugPrint('Error updating evaluation: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  @override
  Future<Either<Failure, EvaluationModel>> deleteEvaluation(String id) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _evaluationsCollection.doc(id).get();
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
            await _evaluationsCollection.doc(id).delete();
            return Right(EvaluationModel.fromJson({
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
      debugPrint('Error deleting evaluation: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }

  /// Fetches evaluations based on search criteria.
  @override
  Future<Either<Failure, List<EvaluationModel>>> searchEvaluations(
      {String? name, String? lastDocumentID, int limit = 20}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        Query queryRef =
            _evaluationsCollection.where('createdBy', isEqualTo: user.uid);

        if (name != null && name.isNotEmpty) {
          queryRef = queryRef
              .where('patientName', isGreaterThanOrEqualTo: name)
              .where('patientName', isLessThanOrEqualTo: '$name\uf8ff');
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

        List<EvaluationModel> evaluations = snapshot.docs
            .map((doc) =>
                EvaluationModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        return Right(evaluations);
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

  @override
  Future<Either<Failure, List<EvaluationModel>>> getEvaluationsByDate(DateTime date,
      {DocumentSnapshot? lastDocument, int limit = 20}) async {
    if (!await _isAuthenticated()) {
      debugPrint('User not authenticated');
      return Left(ServerFailure('User not authenticated', 401));
    }
    try {
      final user = _auth.currentUser;
      if (user != null) {
        debugPrint('Filtering evaluations for user: ${user.uid} on date: $date');
        Query queryRef = _evaluationsCollection
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
        return Left(ServerFailure(
            'Firestore index required. Please create the index in the Firestore console.',
            400));
      }
      debugPrint('Error getting evaluations by date: $e');
      return Left(ServerFailure(e.toString(), 404));
    }
  }
}
