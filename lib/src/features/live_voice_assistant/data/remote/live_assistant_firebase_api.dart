import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../domain/models/voice_session_model.dart';
import '../../domain/models/voice_message_model.dart';
import '../../domain/models/assistant_action_model.dart';
import 'abstract_live_assistant_api.dart';

/// Firebase implementation of the live voice assistant API
/// Handles all Firestore operations for voice sessions, messages, and actions
class LiveAssistantFirebaseApi extends AbstractLiveAssistantApi {
  final ownerId = OwnerNotifier().ownerId;

  /// Reference to the Firestore collection for voice sessions
  final CollectionReference _sessionsCollection =
      FirebaseFirestore.instance.collection('voice_sessions');

  /// Reference to the Firestore collection for voice messages
  final CollectionReference _messagesCollection =
      FirebaseFirestore.instance.collection('voice_messages');

  /// Reference to the Firestore collection for assistant actions
  final CollectionReference _actionsCollection =
      FirebaseFirestore.instance.collection('assistant_actions');

  /// Firebase Authentication instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Creates a new voice session in Firestore
  @override
  Future<Either<Failure, VoiceSessionModel>> createVoiceSession({
    required String userId,
    String? title,
    String? selectedAiModel,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final sessionId = _sessionsCollection.doc().id;
      final session = VoiceSessionModel.create(
        id: sessionId,
        userId: userId,
        title: title,
        selectedAiModel: selectedAiModel,
      );

      final data = session.toJson();
      data.remove('id'); // Firestore generates the ID

      await _sessionsCollection.doc(sessionId).set({
        ...data,
        'ownerId': ownerId,
        'createdBy': user.uid,
      });

      return Right(session);
    } catch (e) {
      debugPrint('Error creating voice session: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Retrieves a voice session by ID
  @override
  Future<Either<Failure, VoiceSessionModel>> getVoiceSession(
      String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final doc = await _sessionsCollection.doc(sessionId).get();
      if (!doc.exists) {
        return Left(ServerFailure('Session not found', 404));
      }

      final data = doc.data() as Map<String, dynamic>;

      // Check ownership
      if (data['ownerId'] != ownerId) {
        return Left(ServerFailure('Access denied', 403));
      }

      data['id'] = doc.id;
      final session = VoiceSessionModel.fromJson(data);
      return Right(session);
    } catch (e) {
      debugPrint('Error getting voice session: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Updates an existing voice session
  @override
  Future<Either<Failure, VoiceSessionModel>> updateVoiceSession(
      VoiceSessionModel session) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final data = session.toJson();
      data.remove('id');
      data['updatedAt'] = Timestamp.now();

      await _sessionsCollection.doc(session.id).update(data);
      return Right(session);
    } catch (e) {
      debugPrint('Error updating voice session: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Deletes a voice session and all its related data
  @override
  Future<Either<Failure, bool>> deleteVoiceSession(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      // Delete session document
      await _sessionsCollection.doc(sessionId).delete();

      // Delete all messages for this session
      final messagesQuery = await _messagesCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in messagesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete all actions for this session
      final actionsQuery = await _actionsCollection
          .where('sessionId', isEqualTo: sessionId)
          .get();

      for (final doc in actionsQuery.docs) {
        await doc.reference.delete();
      }

      return const Right(true);
    } catch (e) {
      debugPrint('Error deleting voice session: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Retrieves user's voice sessions with pagination
  @override
  Future<Either<Failure, List<VoiceSessionModel>>> getUserVoiceSessions({
    required String userId,
    String? lastDocumentId,
    int limit = 20,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      Query queryRef = _sessionsCollection
          .where('ownerId', isEqualTo: ownerId)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(limit);

      if (lastDocumentId != null) {
        final lastDoc = await _sessionsCollection.doc(lastDocumentId).get();
        if (lastDoc.exists) {
          queryRef = queryRef.startAfterDocument(lastDoc);
        }
      }

      final querySnapshot = await queryRef.get();
      final sessions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return VoiceSessionModel.fromJson(data);
      }).toList();

      return Right(sessions);
    } catch (e) {
      debugPrint('Error getting user voice sessions: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Adds a new message to a voice session
  @override
  Future<Either<Failure, VoiceMessageModel>> addMessage(
      VoiceMessageModel message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final messageId = _messagesCollection.doc().id;
      final data = message.toJson();
      data.remove('id');

      await _messagesCollection.doc(messageId).set({
        ...data,
        'ownerId': ownerId,
        'createdBy': user.uid,
      });

      final createdMessage = message.copyWith(id: messageId);
      return Right(createdMessage);
    } catch (e) {
      debugPrint('Error adding message: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Retrieves all messages for a session
  @override
  Future<Either<Failure, List<VoiceMessageModel>>> getSessionMessages(
      String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final querySnapshot = await _messagesCollection
          .where('ownerId', isEqualTo: ownerId)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false)
          .get();

      final messages = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return VoiceMessageModel.fromJson(data);
      }).toList();

      return Right(messages);
    } catch (e) {
      debugPrint('Error getting session messages: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Updates an existing message
  @override
  Future<Either<Failure, VoiceMessageModel>> updateMessage(
      VoiceMessageModel message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final data = message.toJson();
      data.remove('id');
      data['updatedAt'] = Timestamp.now();

      await _messagesCollection.doc(message.id).update(data);
      return Right(message);
    } catch (e) {
      debugPrint('Error updating message: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Deletes a message
  @override
  Future<Either<Failure, bool>> deleteMessage(String messageId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      await _messagesCollection.doc(messageId).delete();
      return const Right(true);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Adds a new action to a voice session
  @override
  Future<Either<Failure, AssistantActionModel>> addAction(
      AssistantActionModel action) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final actionId = _actionsCollection.doc().id;
      final data = action.toJson();
      data.remove('id');

      await _actionsCollection.doc(actionId).set({
        ...data,
        'ownerId': ownerId,
        'createdBy': user.uid,
      });

      final createdAction = action.copyWith(id: actionId);
      return Right(createdAction);
    } catch (e) {
      debugPrint('Error adding action: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Retrieves all actions for a session
  @override
  Future<Either<Failure, List<AssistantActionModel>>> getSessionActions(
      String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final querySnapshot = await _actionsCollection
          .where('ownerId', isEqualTo: ownerId)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('createdAt', descending: false)
          .get();

      final actions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return AssistantActionModel.fromJson(data);
      }).toList();

      return Right(actions);
    } catch (e) {
      debugPrint('Error getting session actions: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Updates an existing action
  @override
  Future<Either<Failure, AssistantActionModel>> updateAction(
      AssistantActionModel action) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final data = action.toJson();
      data.remove('id');
      data['updatedAt'] = Timestamp.now();

      await _actionsCollection.doc(action.id).update(data);
      return Right(action);
    } catch (e) {
      debugPrint('Error updating action: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Deletes an action
  @override
  Future<Either<Failure, bool>> deleteAction(String actionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      await _actionsCollection.doc(actionId).delete();
      return const Right(true);
    } catch (e) {
      debugPrint('Error deleting action: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Gets the total count of sessions for a user
  @override
  Future<Either<Failure, int>> getSessionsCount(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final querySnapshot = await _sessionsCollection
          .where('ownerId', isEqualTo: ownerId)
          .where('userId', isEqualTo: userId)
          .get();

      return Right(querySnapshot.docs.length);
    } catch (e) {
      debugPrint('Error getting sessions count: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Gets the count of sessions for a specific month
  @override
  Future<Either<Failure, int>> getSessionsCountForMonth({
    required String userId,
    required int year,
    required int month,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      final querySnapshot = await _sessionsCollection
          .where('ownerId', isEqualTo: ownerId)
          .where('userId', isEqualTo: userId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('startTime',
              isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      return Right(querySnapshot.docs.length);
    } catch (e) {
      debugPrint('Error getting sessions count for month: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Gets the total session duration for a user
  @override
  Future<Either<Failure, double>> getTotalSessionDuration(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      final querySnapshot = await _sessionsCollection
          .where('ownerId', isEqualTo: ownerId)
          .where('userId', isEqualTo: userId)
          .get();

      double totalDuration = 0.0;
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final duration = data['totalDuration'] as double?;
        if (duration != null) {
          totalDuration += duration;
        }
      }

      return Right(totalDuration);
    } catch (e) {
      debugPrint('Error getting total session duration: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  /// Gets the total count of messages for a user
  @override
  Future<Either<Failure, int>> getTotalMessagesCount(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Left(ServerFailure('User not authenticated', 401));
      }

      // Get all sessions for the user first
      final sessionsSnapshot = await _sessionsCollection
          .where('ownerId', isEqualTo: ownerId)
          .where('userId', isEqualTo: userId)
          .get();

      int totalMessages = 0;
      for (final sessionDoc in sessionsSnapshot.docs) {
        final messagesSnapshot = await _messagesCollection
            .where('sessionId', isEqualTo: sessionDoc.id)
            .get();
        totalMessages += messagesSnapshot.docs.length;
      }

      return Right(totalMessages);
    } catch (e) {
      debugPrint('Error getting total messages count: $e');
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
