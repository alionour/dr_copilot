import 'package:dr_copilot/src/features/copilot_chat/services/claude_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/deepseek_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gpt_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/qwen_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/vertex_ai_service.dart';
import 'package:get_it/get_it.dart';
import 'data/remote/abstract_live_assistant_api.dart';
import 'data/remote/live_assistant_firebase_api.dart';
import 'data/repositories/live_assistant_repository_impl.dart';
import 'data/services/abstract_speech_recognition_service.dart';
import 'data/services/speech_recognition_service.dart';

import 'data/services/abstract_text_to_speech_service.dart';
import 'data/services/text_to_speech_service.dart';

import 'data/services/abstract_ai_processing_service.dart';
import 'data/services/ai_processing_service.dart';
import 'data/services/abstract_audio_recording_service.dart';
import 'data/services/audio_recording_service.dart';
import 'data/services/abstract_audio_playback_service.dart';
import 'data/services/audio_playback_service.dart';
import 'domain/repositories/abstract_live_assistant_repository.dart';
import 'domain/usecases/live_assistant_usecase.dart';
import 'domain/usecases/start_voice_session_usecase.dart';
import 'domain/usecases/process_voice_input_usecase.dart';
import 'presentation/bloc/live_assistant_bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies for the Live Voice Assistant feature
void initLiveVoiceAssistantInjections() {
  // BLoC
  sl.registerFactory<LiveAssistantBloc>(
    () => LiveAssistantBloc(
      startVoiceSessionUseCase: sl<StartVoiceSessionUseCase>(),
      processVoiceInputUseCase: sl<ProcessVoiceInputUseCase>(),
      repository: sl<AbstractLiveAssistantRepository>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<LiveAssistantUseCase>(
    () => LiveAssistantUseCase(sl<AbstractLiveAssistantRepository>()),
  );

  sl.registerLazySingleton<StartVoiceSessionUseCase>(
    () => StartVoiceSessionUseCase(sl<AbstractLiveAssistantRepository>()),
  );

  sl.registerLazySingleton<ProcessVoiceInputUseCase>(
    () => ProcessVoiceInputUseCase(sl<AbstractLiveAssistantRepository>()),
  );

  // Services
  sl.registerLazySingleton<AbstractSpeechRecognitionService>(
    () => SpeechRecognitionService(
        deepgramApiKey: const String.fromEnvironment('DEEPGRAM_KEY')),
  );

  sl.registerLazySingleton<AbstractTextToSpeechService>(
    () => TextToSpeechService(),
  );

  sl.registerLazySingleton<AbstractAIProcessingService>(
    () => AIProcessingService(
      vertexAIService: sl<VertexAIService>(),
      gptService: sl<GPTService>(),
      geminiService: sl<GeminiService>(),
      deepSeekService: sl<DeepSeekService>(),
      qwenService: sl<QwenService>(),
      claudeService: sl<ClaudeService>(),
    ),
  );

  sl.registerLazySingleton<AbstractAudioRecordingService>(
    () => AudioRecordingService(),
  );

  sl.registerLazySingleton<AbstractAudioPlaybackService>(
    () => AudioPlaybackService(),
  );

  // Repository
  sl.registerLazySingleton<AbstractLiveAssistantRepository>(
    () => LiveAssistantRepositoryImpl(
      sl<AbstractLiveAssistantApi>(), // API
      sl<AbstractSpeechRecognitionService>(), // Speech Recognition Service
      sl<AbstractTextToSpeechService>(), // Text-to-Speech Service
      sl<AbstractAIProcessingService>(), // AI Processing Service
      sl<AbstractAudioRecordingService>(), // Audio Recording Service
    ),
  );

  // Data sources
  sl.registerLazySingleton<AbstractLiveAssistantApi>(
    () => LiveAssistantFirebaseApi(),
  );
}
