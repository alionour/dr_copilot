import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

void initAiVoiceAssistantInjections() {
  // BLoC
  sl.registerFactory(
    () => AiVoiceAssistantBloc(
      sl(),
      sl(),
      sl(),
    ),
  );

  // Services
  sl.registerLazySingleton(
    () => CommandParserService(
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
      sl(),
    ),
  );

  sl.registerLazySingleton(() => GeminiService(ApiKeyHelper.geminiKey));

  // Datasources
  sl.registerLazySingleton(
    () => SpeechRecognitionDatasource(
      sl(),
    ),
  );
  sl.registerLazySingleton(
    () => TextToSpeechDatasource(
      sl(),
    ),
  );

  // External
  sl.registerLazySingleton(() => Deepgram(ApiKeyHelper.deepgramApiKey));
  sl.registerLazySingleton(() => FirebaseAuth.instance);
}
