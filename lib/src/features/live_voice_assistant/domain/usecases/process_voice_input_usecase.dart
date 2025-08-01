import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:uuid/uuid.dart';
import '../models/voice_session_model.dart';
import '../models/voice_message_model.dart';

import '../repositories/abstract_live_assistant_repository.dart';

/// Use case for processing voice input in a live session
class ProcessVoiceInputUseCase {
  final AbstractLiveAssistantRepository repository;
  final Uuid _uuid = const Uuid();

  ProcessVoiceInputUseCase(this.repository);

  /// Process voice input and generate AI response
  Future<Either<Failure, VoiceSessionModel>> call({
    required String sessionId,
    required String userInput,
    required String selectedModel,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      // Get current session
      final sessionResult = await repository.getVoiceSession(sessionId);
      if (sessionResult.isLeft()) {
        return Left(sessionResult.fold(
            (l) => l, (r) => ServerFailure('Session not found', 404)));
      }

      VoiceSessionModel session = sessionResult.fold((l) => throw l, (r) => r);

      // Create user message
      final userMessage = VoiceMessageModel.userVoice(
        id: _uuid.v4(),
        sessionId: sessionId,
        content: userInput,
      );

      // Add user message to session
      session = session.addMessage(userMessage);

      // Save user message
      final addMessageResult = await repository.addMessageToSession(
        sessionId: sessionId,
        message: userMessage,
      );
      if (addMessageResult.isLeft()) {
        return Left(addMessageResult.fold((l) => l,
            (r) => ServerFailure('Failed to save user message', 500)));
      }

      // Update session status to processing
      session = session.updateStatus(VoiceSessionStatus.processing);
      await repository.updateVoiceSession(session);

      // Get conversation context
      final contextResult = await repository.getConversationContext(sessionId);
      Map<String, dynamic> context = contextResult.fold((l) => {}, (r) => r);

      // Add additional context if provided
      if (additionalContext != null) {
        context.addAll(additionalContext);
      }

      // Process with AI
      final aiResponseResult = await repository.processVoiceInput(
        sessionId: sessionId,
        userInput: userInput,
        selectedModel: selectedModel,
        context: context,
      );

      if (aiResponseResult.isLeft()) {
        // Create error message
        final errorMessage = VoiceMessageModel.error(
          id: _uuid.v4(),
          sessionId: sessionId,
          errorMessage:
              aiResponseResult.fold((l) => l.message, (r) => 'Unknown error'),
        );

        session = session.addMessage(errorMessage);
        session = session.updateStatus(VoiceSessionStatus.error);
        await repository.updateVoiceSession(session);

        return Left(aiResponseResult.fold(
            (l) => l, (r) => ServerFailure('AI processing failed', 500)));
      }

      final aiResponse = aiResponseResult.fold((l) => throw l, (r) => r);

      // Create assistant message
      final assistantMessage = VoiceMessageModel.assistantVoice(
        id: _uuid.v4(),
        sessionId: sessionId,
        content: aiResponse,
      );

      // Add assistant message to session
      session = session.addMessage(assistantMessage);

      // Save assistant message
      await repository.addMessageToSession(
        sessionId: sessionId,
        message: assistantMessage,
      );

      // Check if response contains actionable commands
      final actionResult = await repository.parseActionFromResponse(
        sessionId: sessionId,
        aiResponse: aiResponse,
      );

      if (actionResult.isRight()) {
        final action = actionResult.fold((l) => throw l, (r) => r);

        // Create action message
        final actionMessage = VoiceMessageModel.systemAction(
          id: _uuid.v4(),
          sessionId: sessionId,
          content: 'Action identified: ${action.description}',
          actionType: action.actionType.toString(),
          actionData: action.parameters,
        );

        session = session.addMessage(actionMessage);
        await repository.addMessageToSession(
          sessionId: sessionId,
          message: actionMessage,
        );
      }

      // Update session status back to idle
      session = session.updateStatus(VoiceSessionStatus.idle);

      // Update conversation context
      final updatedContext = Map<String, dynamic>.from(context);
      updatedContext['lastUserInput'] = userInput;
      updatedContext['lastAiResponse'] = aiResponse;
      updatedContext['messageCount'] = session.messageCount;

      await repository.updateConversationContext(
        sessionId: sessionId,
        context: updatedContext,
      );

      // Save updated session
      final updateResult = await repository.updateVoiceSession(session);
      if (updateResult.isLeft()) {
        return Left(updateResult.fold(
            (l) => l, (r) => ServerFailure('Failed to update session', 500)));
      }

      return Right(updateResult.fold((l) => throw l, (r) => r));
    } catch (e) {
      return Left(
          ServerFailure('Failed to process voice input: ${e.toString()}', 500));
    }
  }

  /// Start listening for voice input
  Future<Either<Failure, bool>> startListening(String sessionId) async {
    try {
      // Update session status to listening
      final sessionResult = await repository.getVoiceSession(sessionId);
      if (sessionResult.isLeft()) {
        return Left(sessionResult.fold(
            (l) => l, (r) => ServerFailure('Session not found', 404)));
      }

      final session = sessionResult.fold((l) => throw l, (r) => r);
      final updatedSession = session.updateStatus(VoiceSessionStatus.listening);
      await repository.updateVoiceSession(updatedSession);

      // Start speech recognition
      return await repository.startListening();
    } catch (e) {
      return Left(
          ServerFailure('Failed to start listening: ${e.toString()}', 500));
    }
  }

  /// Stop listening and get recognized text
  Future<Either<Failure, String>> stopListening(String sessionId) async {
    try {
      // Get recognized text
      final textResult = await repository.stopListening();

      // Update session status back to idle
      final sessionResult = await repository.getVoiceSession(sessionId);
      if (sessionResult.isRight()) {
        final session = sessionResult.fold((l) => throw l, (r) => r);
        final updatedSession = session.updateStatus(VoiceSessionStatus.idle);
        await repository.updateVoiceSession(updatedSession);
      }

      return textResult;
    } catch (e) {
      return Left(
          ServerFailure('Failed to stop listening: ${e.toString()}', 500));
    }
  }

  /// Cancel listening
  Future<Either<Failure, bool>> cancelListening(String sessionId) async {
    try {
      // Cancel speech recognition
      final cancelResult = await repository.cancelListening();

      // Update session status back to idle
      final sessionResult = await repository.getVoiceSession(sessionId);
      if (sessionResult.isRight()) {
        final session = sessionResult.fold((l) => throw l, (r) => r);
        final updatedSession = session.updateStatus(VoiceSessionStatus.idle);
        await repository.updateVoiceSession(updatedSession);
      }

      return cancelResult;
    } catch (e) {
      return Left(
          ServerFailure('Failed to cancel listening: ${e.toString()}', 500));
    }
  }

  /// Speak AI response
  Future<Either<Failure, bool>> speakResponse({
    required String sessionId,
    required String text,
  }) async {
    try {
      // Update session status to speaking
      final sessionResult = await repository.getVoiceSession(sessionId);
      if (sessionResult.isLeft()) {
        return Left(sessionResult.fold(
            (l) => l, (r) => ServerFailure('Session not found', 404)));
      }

      final session = sessionResult.fold((l) => throw l, (r) => r);
      final updatedSession = session.updateStatus(VoiceSessionStatus.speaking);
      await repository.updateVoiceSession(updatedSession);

      // Start speaking
      final speakResult = await repository.speak(text);

      // Update session status back to idle after speaking
      final finalSession = updatedSession.updateStatus(VoiceSessionStatus.idle);
      await repository.updateVoiceSession(finalSession);

      return speakResult;
    } catch (e) {
      return Left(
          ServerFailure('Failed to speak response: ${e.toString()}', 500));
    }
  }

  /// Stop speaking
  Future<Either<Failure, bool>> stopSpeaking(String sessionId) async {
    try {
      final stopResult = await repository.stopSpeaking();

      // Update session status back to idle
      final sessionResult = await repository.getVoiceSession(sessionId);
      if (sessionResult.isRight()) {
        final session = sessionResult.fold((l) => throw l, (r) => r);
        final updatedSession = session.updateStatus(VoiceSessionStatus.idle);
        await repository.updateVoiceSession(updatedSession);
      }

      return stopResult;
    } catch (e) {
      return Left(
          ServerFailure('Failed to stop speaking: ${e.toString()}', 500));
    }
  }
}
