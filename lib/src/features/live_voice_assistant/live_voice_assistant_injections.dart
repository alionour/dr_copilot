import 'package:get_it/get_it.dart';
import 'data/remote/abstract_live_assistant_api.dart';
import 'data/remote/live_assistant_firebase_api.dart';
import 'data/repositories/live_assistant_repository_impl.dart';
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

  // Repository
  sl.registerLazySingleton<AbstractLiveAssistantRepository>(
    () => LiveAssistantRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<AbstractLiveAssistantApi>(
    () => LiveAssistantFirebaseApi(),
  );
}
