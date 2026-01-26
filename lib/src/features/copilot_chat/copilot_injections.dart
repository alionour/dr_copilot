import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:get_it/get_it.dart';
import 'presentation/bloc/copilot_bloc.dart';
import 'data/repositories/conversation_repository.dart';
import 'services/vertex_ai_service.dart';
import 'services/gpt_service.dart';
import 'services/gemini_service.dart';
import 'services/deepseek_service.dart';
import 'services/qwen_service.dart';
import 'services/claude_service.dart';
import 'services/groq_service.dart';
import 'services/ai_router_service.dart';
import 'data/services/tts_service.dart';
import 'data/services/live_chat_service.dart';

final sl = GetIt.instance;

/// Initializes the dependency injections required for the copilot chat feature.
///
/// This function sets up all necessary services and dependencies related to
/// AI chat functionality, ensuring they are available throughout the application.
/// Call this during the application's initialization phase.
void initCopilotInjections() {
  // BLoC
  sl.registerFactory(
    () => CopilotBloc(
      vertexAIService: sl(),
      gptService: sl(),
      geminiService: sl(),
      deepSeekService: sl(),
      qwenService: sl(),
      claudeService: sl(),
      routerService: sl(),
      secureStorage: sl(),
      conversationRepo: ConversationRepository(),
    ),
  );

  // Services
  sl.registerLazySingleton(
    () => VertexAIService(ApiKeyHelper.vertexAIKey,
        quotaService: sl(), subscriptionService: sl()),
  );
  sl.registerLazySingleton(
    () => GPTService(
      quotaService: sl(),
      subscriptionService: sl(),
    ),
  );
  sl.registerLazySingleton(
    () => GeminiService(ApiKeyHelper.geminiKey,
        quotaService: sl(), subscriptionService: sl()),
  );
  sl.registerLazySingleton(
    () => DeepSeekService(ApiKeyHelper.deepSeekKey,
        quotaService: sl(), subscriptionService: sl()),
  );
  sl.registerLazySingleton(
    () => QwenService(ApiKeyHelper.qwenKey,
        quotaService: sl(), subscriptionService: sl()),
  );
  sl.registerLazySingleton(
    () => ClaudeService(ApiKeyHelper.claudeKey,
        quotaService: sl(), subscriptionService: sl()),
  );
  sl.registerLazySingleton(
    () => GroqService(ApiKeyHelper.groqKey,
        quotaService: sl(), subscriptionService: sl()),
  );
  sl.registerLazySingleton(
    () => AIRouterService(
      geminiService: sl(),
      groqService: sl(),
      subscriptionService: sl(),
    ),
  );

  sl.registerLazySingleton(() => TtsService());
  sl.registerLazySingleton(
    () => LiveChatService(
      speechService: sl(),
      ttsService: sl(),
    ),
  );
}
