
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'presentation/bloc/copilot_bloc.dart';
import 'services/vertex_ai_service.dart';
import 'services/gpt_service.dart';
import 'services/gemini_service.dart';
import 'services/deepseek_service.dart';
import 'services/qwen_service.dart';
import 'services/claude_service.dart';
import '../../core/helper/platform_env_io.dart'
    if (dart.library.html) '../../core/helper/platform_env_web.dart';

final sl = GetIt.instance;

/// Initializes the dependency injections required for the copilot chat feature.
///
/// This function sets up all necessary services and dependencies related to
/// AI chat functionality, ensuring they are available throughout the application.
/// Call this during the application's initialization phase.
void initCopilotInjections() {
  // BLoC
  sl.registerFactory(() => CopilotBloc(
        vertexAIService: sl(),
        gptService: sl(),
        geminiService: sl(),
        deepSeekService: sl(),
        qwenService: sl(),
        claudeService: sl(),
      ));

  // Services
  sl.registerLazySingleton(() => VertexAIService(''));
  sl.registerLazySingleton(() => GPTService(''));
  sl.registerLazySingleton(
    () => GeminiService(
      kIsWeb
          ? getPlatformEnv('GEMINI_KEY')
          : (getPlatformEnv('GEMINI_KEY').isEmpty
              ? getPlatformEnv('GEMINI_KEY_2')
              : getPlatformEnv('GEMINI_KEY')),
    ),
  );
  sl.registerLazySingleton(() => DeepSeekService(''));
  sl.registerLazySingleton(() => QwenService(''));
  sl.registerLazySingleton(() => ClaudeService(''));
}
