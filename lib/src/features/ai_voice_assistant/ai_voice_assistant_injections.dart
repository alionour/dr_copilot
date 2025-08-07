import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
  sl.registerLazySingleton(() => SpeechToText());
  sl.registerLazySingleton(() => FlutterTts());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
}
