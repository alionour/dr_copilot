import 'package:dr_copilot/src/features/appointments/sessions/data/remote/session_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/sessions/data/repositories/sessions_repository_impl.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void initSessionsInjections() {
  // Bloc
  sl.registerFactory(() => SessionsBloc(sl(),sl()));

  // Use cases
  sl.registerLazySingleton(() => SessionsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SessionsRepositoryImpl>(
    () => SessionsRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<SessionsFirebaseApi>(
    () => SessionsFirebaseApi(),
  );
}
