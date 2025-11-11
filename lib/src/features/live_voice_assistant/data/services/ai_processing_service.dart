import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/models/assistant_action_model.dart';
import 'abstract_ai_processing_service.dart';

class AIProcessingService implements AbstractAIProcessingService {
  final dynamic vertexAIService;
  final dynamic gptService;
  final dynamic geminiService;
  final dynamic deepSeekService;
  final dynamic qwenService;
  final dynamic claudeService;

  AIProcessingService({
    required this.vertexAIService,
    required this.gptService,
    required this.geminiService,
    required this.deepSeekService,
    required this.qwenService,
    required this.claudeService,
  });

  @override
  Future<Either<Failure, String>> processVoiceInput({
    required String sessionId,
    required String userInput,
    required String selectedModel,
    Map<String, dynamic>? context,
  }) async {
    return const Right("");
  }

  @override
  Future<Either<Failure, AssistantActionModel?>> parseActionFromResponse({
    required String sessionId,
    required String aiResponse,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getConversationContext(
      String sessionId) async {
    return const Right({});
  }

  @override
  Future<Either<Failure, bool>> updateConversationContext({
    required String sessionId,
    required Map<String, dynamic> context,
  }) async {
    return const Right(true);
  }
}
