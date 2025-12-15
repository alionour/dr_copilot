import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/repositories/evaluations_repository_impl.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void initEvaluationsInjections() {
  // Bloc
  sl.registerFactory(() => EvaluationsBloc(sl(), sl()));

  // Use cases
  sl.registerLazySingleton(() => EvaluationsUseCase(sl()));

  // Repository (register as abstract type)
  sl.registerLazySingleton<AbstractEvaluationsRepository>(
    () => EvaluationsRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<EvaluationsFirebaseApi>(
    () => EvaluationsFirebaseApi(),
  );
}

