import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/repositories/evaluations_repository_impl.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:dr_copilot/src/features/financials/data/remote/financials_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/data/repositories/financials_repository_impl.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

void initFinancialsInjections() {
  // Bloc
  sl.registerFactory(() => FinancialsBloc(sl()));

  // Use cases
  sl.registerLazySingleton(() => FinancialsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<FinancialsRepositoryImpl>(
    () => FinancialsRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<FinancialsFirebaseApi>(
    () => FinancialsFirebaseApi(),
  );
}
