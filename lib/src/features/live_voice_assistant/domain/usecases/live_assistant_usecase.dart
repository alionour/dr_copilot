import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import '../models/voice_session_model.dart';
import '../models/voice_message_model.dart';
import '../models/assistant_action_model.dart';
import '../repositories/abstract_live_assistant_repository.dart';

/// Use case for managing live voice assistant operations
/// This class encapsulates all business logic related to voice sessions,
/// messages, and actions, providing a clean interface for the presentation layer.
class LiveAssistantUseCase {
  final AbstractLiveAssistantRepository _repository;

  const LiveAssistantUseCase(this._repository);

  /// Voice Session Management

  /// Creates a new voice session for the user
  Future<Either<Failure, VoiceSessionModel>> createVoiceSession({
    required String userId,
    String? title,
    String? selectedAiModel,
  }) async {
    return await _repository.createVoiceSession(
      userId: userId,
      title: title ?? 'Voice Session ${DateTime.now().millisecondsSinceEpoch}',
      selectedAiModel: selectedAiModel ?? 'gemini-pro',
    );
  }

  /// Retrieves a specific voice session
  Future<Either<Failure, VoiceSessionModel>> getVoiceSession(
      String sessionId) async {
    if (sessionId.isEmpty) {
      return Left(ValidationFailure('Session ID cannot be empty'));
    }
    return await _repository.getVoiceSession(sessionId);
  }

  /// Updates an existing voice session
  Future<Either<Failure, VoiceSessionModel>> updateVoiceSession(
      VoiceSessionModel session) async {
    if (session.id.isEmpty) {
      return Left(ValidationFailure('Session ID cannot be empty'));
    }
    return await _repository.updateVoiceSession(session);
  }

  /// Deletes a voice session and all its related data
  Future<Either<Failure, bool>> deleteVoiceSession(String sessionId) async {
    if (sessionId.isEmpty) {
      return Left(ValidationFailure('Session ID cannot be empty'));
    }
    return await _repository.deleteVoiceSession(sessionId);
  }

  /// Retrieves user's voice sessions
  Future<Either<Failure, List<VoiceSessionModel>>> getUserVoiceSessions(
      String userId) async {
    if (userId.isEmpty) {
      return Left(ValidationFailure('User ID cannot be empty'));
    }
    return await _repository.getUserVoiceSessions(userId);
  }

  /// Voice Message Management

  /// Adds a new message to a voice session
  Future<Either<Failure, VoiceMessageModel>> addMessage({
    required String sessionId,
    required VoiceMessageModel message,
  }) async {
    if (sessionId.isEmpty) {
      return Left(ValidationFailure('Session ID cannot be empty'));
    }
    if (message.content.isEmpty && message.audioPath == null) {
      return Left(
          ValidationFailure('Message must have either content or audio'));
    }
    return await _repository.addMessageToSession(
      sessionId: sessionId,
      message: message,
    );
  }

  /// Retrieves all messages for a session
  Future<Either<Failure, List<VoiceMessageModel>>> getSessionMessages(
      String sessionId) async {
    if (sessionId.isEmpty) {
      return Left(ValidationFailure('Session ID cannot be empty'));
    }
    return await _repository.getSessionMessages(sessionId);
  }

  /// Updates an existing message
  Future<Either<Failure, VoiceMessageModel>> updateMessage(
      VoiceMessageModel message) async {
    if (message.id.isEmpty) {
      return Left(ValidationFailure('Message ID cannot be empty'));
    }
    return await _repository.updateMessage(message);
  }

  /// Deletes a message
  Future<Either<Failure, bool>> deleteMessage(String messageId) async {
    if (messageId.isEmpty) {
      return Left(ValidationFailure('Message ID cannot be empty'));
    }
    return await _repository.deleteMessage(messageId);
  }

  /// AI Processing Operations

  /// Processes voice input using AI
  Future<Either<Failure, String>> processVoiceInput({
    required String sessionId,
    required String userInput,
    required String selectedModel,
    Map<String, dynamic>? context,
  }) async {
    if (sessionId.isEmpty) {
      return Left(ValidationFailure('Session ID cannot be empty'));
    }
    if (userInput.isEmpty) {
      return Left(ValidationFailure('User input cannot be empty'));
    }
    if (selectedModel.isEmpty) {
      return Left(ValidationFailure('Selected model cannot be empty'));
    }
    return await _repository.processVoiceInput(
      sessionId: sessionId,
      userInput: userInput,
      selectedModel: selectedModel,
      context: context,
    );
  }

  /// Executes an action
  Future<Either<Failure, AssistantActionModel>> executeAction(
      AssistantActionModel action) async {
    if (action.sessionId.isEmpty) {
      return Left(ValidationFailure('Session ID cannot be empty'));
    }
    return await _repository.executeAction(action);
  }

  /// Business Logic Methods

  /// Starts a new voice session with default settings
  Future<Either<Failure, VoiceSessionModel>> startNewSession({
    required String userId,
    String? customTitle,
    String? preferredAiModel,
  }) async {
    final title = customTitle ??
        'Voice Session ${DateTime.now().toString().substring(0, 16)}';
    return await createVoiceSession(
      userId: userId,
      title: title,
      selectedAiModel: preferredAiModel,
    );
  }

  /// Ends a voice session by updating its end time and status
  Future<Either<Failure, VoiceSessionModel>> endSession(
      String sessionId) async {
    final sessionResult = await getVoiceSession(sessionId);
    return sessionResult.fold(
      (failure) => Left(failure),
      (session) async {
        final updatedSession = session.copyWith(
          endTime: Timestamp.fromDate(DateTime.now()),
          status: VoiceSessionStatus.ended,
        );
        return await updateVoiceSession(updatedSession);
      },
    );
  }

  /// Calculates session duration and updates the session
  Future<Either<Failure, VoiceSessionModel>> updateSessionDuration(
      String sessionId) async {
    final sessionResult = await getVoiceSession(sessionId);
    return sessionResult.fold(
      (failure) => Left(failure),
      (session) async {
        if (session.endTime != null) {
          final duration = session.endTime!
              .toDate()
              .difference(session.startTime.toDate())
              .inSeconds
              .toDouble();
          final updatedSession = session.copyWith(totalDuration: duration);
          return await updateVoiceSession(updatedSession);
        }
        return Right(session);
      },
    );
  }
}
