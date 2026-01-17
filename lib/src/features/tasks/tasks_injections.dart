import 'package:get_it/get_it.dart';
import 'data/remote/task_firebase_api.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/abstract_task_repository.dart';
import 'domain/usecases/task_usecase.dart';
import 'presentation/bloc/tasks_bloc.dart';

void initTasksInjections() {
  final sl = GetIt.instance;

  // Data Source
  sl.registerLazySingleton(() => TaskFirebaseApi());

  // Repository
  sl.registerLazySingleton<AbstractTaskRepository>(
    () => TaskRepositoryImpl(
      sl(),
      sl(),
    ),
  );

  // Use Case
  sl.registerLazySingleton(() => TaskUseCase(sl()));

  // Bloc
  sl.registerFactory(() => TasksBloc(sl()));
}
