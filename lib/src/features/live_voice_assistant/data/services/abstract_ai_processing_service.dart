import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/models/assistant_action_model.dart';

abstract class AbstractAIProcessingService {
  Future<Either<Failure, String>> processVoiceInput({
    required String sessionId,
    required String userInput,
    required String selectedModel,
    Map<String, dynamic>? context,
  });
  Future<Either<Failure, AssistantActionModel?>> parseActionFromResponse({
    required String sessionId,
    required String aiResponse,
  });
  Future<Either<Failure, Map<String, dynamic>>> getConversationContext(
      String sessionId);
  Future<Either<Failure, bool>> updateConversationContext({
    required String sessionId,
    required Map<String, dynamic> context,
  });
}
