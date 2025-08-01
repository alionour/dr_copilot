import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import '../models/voice_session_model.dart';
import '../models/voice_message_model.dart';
import '../models/assistant_action_model.dart';

/// Abstract repository for live voice assistant operations
abstract class AbstractLiveAssistantRepository {
  /// Speech Recognition Operations
  Future<Either<Failure, bool>> initializeSpeechRecognition();
  Future<Either<Failure, bool>> startListening();
  Future<Either<Failure, String>> stopListening();
  Future<Either<Failure, bool>> cancelListening();
  Future<Either<Failure, bool>> isSpeechRecognitionAvailable();
  Future<Either<Failure, List<String>>> getAvailableLanguages();

  /// Text-to-Speech Operations
  Future<Either<Failure, bool>> initializeTextToSpeech();
  Future<Either<Failure, bool>> speak(String text);
  Future<Either<Failure, bool>> stopSpeaking();
  Future<Either<Failure, bool>> pauseSpeaking();
  Future<Either<Failure, bool>> resumeSpeaking();
  Future<Either<Failure, bool>> isSpeaking();
  Future<Either<Failure, List<String>>> getAvailableVoices();
  Future<Either<Failure, bool>> setVoice(String voiceId);
  Future<Either<Failure, bool>> setSpeechRate(double rate);
  Future<Either<Failure, bool>> setPitch(double pitch);

  /// Voice Session Management
  Future<Either<Failure, VoiceSessionModel>> createVoiceSession({
    required String userId,
    String? title,
    String? selectedAiModel,
  });
  Future<Either<Failure, VoiceSessionModel>> getVoiceSession(String sessionId);
  Future<Either<Failure, List<VoiceSessionModel>>> getUserVoiceSessions(String userId);
  Future<Either<Failure, VoiceSessionModel>> updateVoiceSession(VoiceSessionModel session);
  Future<Either<Failure, bool>> deleteVoiceSession(String sessionId);
  Future<Either<Failure, VoiceSessionModel>> endVoiceSession(String sessionId);

  /// Message Management
  Future<Either<Failure, VoiceMessageModel>> addMessageToSession({
    required String sessionId,
    required VoiceMessageModel message,
  });
  Future<Either<Failure, List<VoiceMessageModel>>> getSessionMessages(String sessionId);
  Future<Either<Failure, VoiceMessageModel>> updateMessage(VoiceMessageModel message);
  Future<Either<Failure, bool>> deleteMessage(String messageId);

  /// AI Processing
  Future<Either<Failure, String>> processVoiceInput({
    required String sessionId,
    required String userInput,
    required String selectedModel,
    Map<String, dynamic>? context,
  });
  Future<Either<Failure, AssistantActionModel>> parseActionFromResponse({
    required String sessionId,
    required String aiResponse,
  });

  /// Action Execution
  Future<Either<Failure, AssistantActionModel>> executeAction(AssistantActionModel action);
  Future<Either<Failure, List<AssistantActionModel>>> getSessionActions(String sessionId);
  Future<Either<Failure, AssistantActionModel>> updateAction(AssistantActionModel action);

  /// Permission Management
  Future<Either<Failure, bool>> requestMicrophonePermission();
  Future<Either<Failure, bool>> checkMicrophonePermission();

  /// Audio File Management
  Future<Either<Failure, String>> saveAudioFile(List<int> audioData, String fileName);
  Future<Either<Failure, List<int>>> loadAudioFile(String filePath);
  Future<Either<Failure, bool>> deleteAudioFile(String filePath);

  /// Context Management
  Future<Either<Failure, Map<String, dynamic>>> getConversationContext(String sessionId);
  Future<Either<Failure, bool>> updateConversationContext({
    required String sessionId,
    required Map<String, dynamic> context,
  });

  /// Real-time Stream Operations
  Stream<Either<Failure, String>> getRealtimeSpeechRecognitionStream();
  Stream<Either<Failure, VoiceSessionModel>> getVoiceSessionStream(String sessionId);
  Stream<Either<Failure, List<VoiceMessageModel>>> getSessionMessagesStream(String sessionId);
}
