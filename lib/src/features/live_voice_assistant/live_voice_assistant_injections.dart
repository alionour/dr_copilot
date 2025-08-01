import 'package:get_it/get_it.dart';
import 'data/remote/abstract_live_assistant_api.dart';
import 'data/remote/live_assistant_firebase_api.dart';
import 'data/repositories/live_assistant_repository_impl.dart';
import 'data/services/abstract_speech_recognition_service.dart';
import 'data/services/speech_recognition_service.dart';
import 'data/services/windows_speech_recognition_service.dart';
import 'dart:io';
import 'data/services/abstract_text_to_speech_service.dart';
import 'data/services/text_to_speech_service.dart';
import 'data/services/windows_text_to_speech_service.dart';
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
      startVoiceSessionUseCase: sl(),
      processVoiceInputUseCase: sl(),
      repository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton<LiveAssistantUseCase>(
    () => LiveAssistantUseCase(sl()),
  );

  sl.registerLazySingleton<StartVoiceSessionUseCase>(
    () => StartVoiceSessionUseCase(sl()),
  );

  sl.registerLazySingleton<ProcessVoiceInputUseCase>(
    () => ProcessVoiceInputUseCase(sl()),
  );

  // Services
  sl.registerLazySingleton<AbstractSpeechRecognitionService>(
    () => Platform.isWindows
        ? WindowsSpeechRecognitionService()
        : SpeechRecognitionService(),
  );

  sl.registerLazySingleton<AbstractTextToSpeechService>(
    () => Platform.isWindows
        ? WindowsTextToSpeechService()
        : TextToSpeechService(),
  );

  sl.registerLazySingleton<AbstractAIProcessingService>(
    () => AIProcessingService(
      vertexAIService: sl(),
      gptService: sl(),
      geminiService: sl(),
      deepSeekService: sl(),
      qwenService: sl(),
      claudeService: sl(),
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
      sl(), // API
      sl(), // Speech Recognition Service
      sl(), // Text-to-Speech Service
      sl(), // AI Processing Service
      sl(), // Audio Recording Service
      sl(), // Audio Playback Service
    ),
  );

  // Data sources
  sl.registerLazySingleton<AbstractLiveAssistantApi>(
    () => LiveAssistantFirebaseApi(),
  );
}
