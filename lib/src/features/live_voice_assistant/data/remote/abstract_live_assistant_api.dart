import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import '../../domain/models/voice_session_model.dart';
import '../../domain/models/voice_message_model.dart';
import '../../domain/models/assistant_action_model.dart';

/// Abstract API interface for live voice assistant operations
/// This interface defines the contract for data operations related to voice sessions,
/// messages, and actions. Implementations can be Firebase, REST API, or mock data.
abstract class AbstractLiveAssistantApi {
  /// Voice Session Management
  Future<Either<Failure, VoiceSessionModel>> createVoiceSession({
    required String userId,
    String? title,
    String? selectedAiModel,
  });

  Future<Either<Failure, VoiceSessionModel>> getVoiceSession(String sessionId);
  
  Future<Either<Failure, VoiceSessionModel>> updateVoiceSession(VoiceSessionModel session);
  
  Future<Either<Failure, bool>> deleteVoiceSession(String sessionId);
  
  Future<Either<Failure, List<VoiceSessionModel>>> getUserVoiceSessions({
    required String userId,
    String? lastDocumentId,
    int limit = 20,
  });

  /// Voice Message Management
  Future<Either<Failure, VoiceMessageModel>> addMessage(VoiceMessageModel message);
  
  Future<Either<Failure, List<VoiceMessageModel>>> getSessionMessages(String sessionId);
  
  Future<Either<Failure, VoiceMessageModel>> updateMessage(VoiceMessageModel message);
  
  Future<Either<Failure, bool>> deleteMessage(String messageId);

  /// Assistant Action Management
  Future<Either<Failure, AssistantActionModel>> addAction(AssistantActionModel action);
  
  Future<Either<Failure, List<AssistantActionModel>>> getSessionActions(String sessionId);
  
  Future<Either<Failure, AssistantActionModel>> updateAction(AssistantActionModel action);
  
  Future<Either<Failure, bool>> deleteAction(String actionId);

  /// Session Statistics
  Future<Either<Failure, int>> getSessionsCount(String userId);
  
  Future<Either<Failure, int>> getSessionsCountForMonth({
    required String userId,
    required int year,
    required int month,
  });
  
  Future<Either<Failure, double>> getTotalSessionDuration(String userId);
  
  Future<Either<Failure, int>> getTotalMessagesCount(String userId);
}
