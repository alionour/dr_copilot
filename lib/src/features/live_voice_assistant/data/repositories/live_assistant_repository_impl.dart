import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/models/voice_session_model.dart';
import '../../domain/models/voice_message_model.dart';
import '../../domain/models/assistant_action_model.dart';
import '../../domain/repositories/abstract_live_assistant_repository.dart';
import '../remote/abstract_live_assistant_api.dart';
import '../services/abstract_speech_recognition_service.dart';
import '../services/abstract_text_to_speech_service.dart';
import '../services/abstract_ai_processing_service.dart';
import '../services/abstract_audio_recording_service.dart';

/// Implementation of the live voice assistant repository
/// This class acts as a bridge between the domain layer and the data layer,
/// delegating all operations to the provided API implementation.
class LiveAssistantRepositoryImpl implements AbstractLiveAssistantRepository {
  final AbstractLiveAssistantApi _api;
  final AbstractSpeechRecognitionService _speechRecognitionService;
  final AbstractTextToSpeechService _textToSpeechService;
  final AbstractAIProcessingService _aiProcessingService;
  final AbstractAudioRecordingService _audioRecordingService;

  const LiveAssistantRepositoryImpl(
    this._api,
    this._speechRecognitionService,
    this._textToSpeechService,
    this._aiProcessingService,
    this._audioRecordingService,
  );

  /// Speech Recognition Operations
  @override
  Future<Either<Failure, bool>> initializeSpeechRecognition() async {
    return await _speechRecognitionService.initialize();
  }

  @override
  Future<Either<Failure, bool>> startListening() async {
    return await _speechRecognitionService.startListening();
  }

  @override
  Future<Either<Failure, String>> stopListening() async {
    return await _speechRecognitionService.stopListening();
  }

  @override
  Future<Either<Failure, bool>> cancelListening() async {
    return await _speechRecognitionService.cancelListening();
  }

  @override
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable() async {
    return await _speechRecognitionService.isAvailable();
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableLanguages() async {
    return await _speechRecognitionService.getAvailableLanguages();
  }

  /// Text-to-Speech Operations
  @override
  Future<Either<Failure, bool>> initializeTextToSpeech() async {
    return await _textToSpeechService.initialize();
  }

  @override
  Future<Either<Failure, bool>> speak(String text) async {
    return await _textToSpeechService.speak(text);
  }

  @override
  Future<Either<Failure, bool>> stopSpeaking() async {
    return await _textToSpeechService.stopSpeaking();
  }

  @override
  Future<Either<Failure, bool>> pauseSpeaking() async {
    return await _textToSpeechService.pauseSpeaking();
  }

  @override
  Future<Either<Failure, bool>> resumeSpeaking() async {
    return await _textToSpeechService.resumeSpeaking();
  }

  @override
  Future<Either<Failure, bool>> isSpeaking() async {
    return await _textToSpeechService.isSpeaking();
  }

  @override
  Future<Either<Failure, List<String>>> getAvailableVoices() async {
    return await _textToSpeechService.getAvailableVoices();
  }

  @override
  Future<Either<Failure, bool>> setVoice(String voiceId) async {
    return await _textToSpeechService.setVoice(voiceId);
  }

  @override
  Future<Either<Failure, bool>> setSpeechRate(double rate) async {
    return await _textToSpeechService.setSpeechRate(rate);
  }

  @override
  Future<Either<Failure, bool>> setPitch(double pitch) async {
    return await _textToSpeechService.setPitch(pitch);
  }

  /// Voice Session Management
  @override
  Future<Either<Failure, VoiceSessionModel>> createVoiceSession({
    required String userId,
    String? title,
    String? selectedAiModel,
  }) async {
    return await _api.createVoiceSession(
      userId: userId,
      title: title,
      selectedAiModel: selectedAiModel,
    );
  }

  @override
  Future<Either<Failure, VoiceSessionModel>> getVoiceSession(
      String sessionId) async {
    return await _api.getVoiceSession(sessionId);
  }

  @override
  Future<Either<Failure, List<VoiceSessionModel>>> getUserVoiceSessions(
      String userId) async {
    return await _api.getUserVoiceSessions(userId: userId);
  }

  @override
  Future<Either<Failure, VoiceSessionModel>> updateVoiceSession(
      VoiceSessionModel session) async {
    return await _api.updateVoiceSession(session);
  }

  @override
  Future<Either<Failure, bool>> deleteVoiceSession(String sessionId) async {
    return await _api.deleteVoiceSession(sessionId);
  }

  @override
  Future<Either<Failure, VoiceSessionModel>> endVoiceSession(
      String sessionId) async {
    // First get the current session
    final sessionResult = await _api.getVoiceSession(sessionId);

    return sessionResult.fold(
      (failure) => Left(failure),
      (session) async {
        // Update the session with ended status
        final updatedSession = session.copyWith(
          status: VoiceSessionStatus.ended,
          endTime: Timestamp.now(),
          isActive: false,
        );

        return await _api.updateVoiceSession(updatedSession);
      },
    );
  }

  /// Message Management
  @override
  Future<Either<Failure, VoiceMessageModel>> addMessageToSession({
    required String sessionId,
    required VoiceMessageModel message,
  }) async {
    return await _api.addMessage(message);
  }

  @override
  Future<Either<Failure, List<VoiceMessageModel>>> getSessionMessages(
      String sessionId) async {
    return await _api.getSessionMessages(sessionId);
  }

  @override
  Future<Either<Failure, VoiceMessageModel>> updateMessage(
      VoiceMessageModel message) async {
    return await _api.updateMessage(message);
  }

  @override
  Future<Either<Failure, bool>> deleteMessage(String messageId) async {
    return await _api.deleteMessage(messageId);
  }

  /// AI Processing
  @override
  Future<Either<Failure, String>> processVoiceInput({
    required String sessionId,
    required String userInput,
    required String selectedModel,
    Map<String, dynamic>? context,
  }) async {
    return await _aiProcessingService.processVoiceInput(
      sessionId: sessionId,
      userInput: userInput,
      selectedModel: selectedModel,
      context: context,
    );
  }

  @override
  Future<Either<Failure, AssistantActionModel>> parseActionFromResponse({
    required String sessionId,
    required String aiResponse,
  }) async {
    final result = await _aiProcessingService.parseActionFromResponse(
      sessionId: sessionId,
      aiResponse: aiResponse,
    );

    return result.fold(
      (failure) => Left(failure),
      (action) => action != null
          ? Right(action)
          : Left(ServerFailure('No action found in response', 404)),
    );
  }

  /// Action Execution
  @override
  Future<Either<Failure, AssistantActionModel>> executeAction(
      AssistantActionModel action) async {
    return await _api.updateAction(action.copyWith(
      status: ActionExecutionStatus.completed,
      executedAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, List<AssistantActionModel>>> getSessionActions(
      String sessionId) async {
    return await _api.getSessionActions(sessionId);
  }

  @override
  Future<Either<Failure, AssistantActionModel>> updateAction(
      AssistantActionModel action) async {
    return await _api.updateAction(action);
  }

  /// Permission Management
  @override
  Future<Either<Failure, bool>> requestMicrophonePermission() async {
    return await _speechRecognitionService.requestMicrophonePermission();
  }

  @override
  Future<Either<Failure, bool>> checkMicrophonePermission() async {
    return await _speechRecognitionService.checkMicrophonePermission();
  }

  /// Audio File Management
  @override
  Future<Either<Failure, String>> saveAudioFile(
      List<int> audioData, String fileName) async {
    try {
      // Use path_provider to get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${directory.path}/recordings');
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      final filePath = '${recordingsDir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(audioData);

      return Right(filePath);
    } catch (e) {
      return Left(
          ServerFailure('Failed to save audio file: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, List<int>>> loadAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return Left(ServerFailure('Audio file not found', 404));
      }

      final audioData = await file.readAsBytes();
      return Right(audioData);
    } catch (e) {
      return Left(
          ServerFailure('Failed to load audio file: ${e.toString()}', 500));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteAudioFile(String filePath) async {
    return await _audioRecordingService.deleteRecordingFile(filePath);
  }

  /// Context Management
  @override
  Future<Either<Failure, Map<String, dynamic>>> getConversationContext(
      String sessionId) async {
    return await _aiProcessingService.getConversationContext(sessionId);
  }

  @override
  Future<Either<Failure, bool>> updateConversationContext({
    required String sessionId,
    required Map<String, dynamic> context,
  }) async {
    return await _aiProcessingService.updateConversationContext(
      sessionId: sessionId,
      context: context,
    );
  }

  /// Real-time Stream Operations
  @override
  Stream<Either<Failure, String>> getRealtimeSpeechRecognitionStream() {
    return _speechRecognitionService.getRealtimeRecognitionStream();
  }

  @override
  Stream<Either<Failure, VoiceSessionModel>> getVoiceSessionStream(
      String sessionId) {
    // Create a periodic stream that polls for session updates
    return Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) => _api.getVoiceSession(sessionId))
        .distinct();
  }

  @override
  Stream<Either<Failure, List<VoiceMessageModel>>> getSessionMessagesStream(
      String sessionId) {
    // Create a periodic stream that polls for message updates
    return Stream.periodic(const Duration(seconds: 1))
        .asyncMap((_) => _api.getSessionMessages(sessionId))
        .distinct();
  }
}
