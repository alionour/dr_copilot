import 'package:dr_copilot/src/features/financials/data/remote/financials_firebase_api.dart';
import 'package:dr_copilot/src/features/financials/data/repositories/financials_repository_impl.dart';
import 'package:dr_copilot/src/features/financials/domain/repositories/abstract_financials_repository.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:get_it/get_it.dart';

/// An instance of the [GetIt] service locator used for dependency injection throughout the application.
/// 
/// This allows for registering and retrieving dependencies in a centralized manner.
/// 
/// Example usage:
/// ```dart
/// sl.registerSingleton<MyService>(MyService());
/// final myService = sl<MyService>();
/// ```
final sl = GetIt.instance;

/// Initializes the dependency injections required for the financials feature.
/// 
/// This function sets up all necessary services, repositories, and other dependencies
/// related to the financials module, ensuring they are available for use throughout
/// the application.
void initFinancialsInjections() {
  // Bloc
  sl.registerFactory(() => FinancialsBloc(sl()));

  // Use cases
  sl.registerLazySingleton(() => FinancialsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AbstractFinancialsRepository>(
    () => FinancialsRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<FinancialsFirebaseApi>(
    () => FinancialsFirebaseApi(),
  );
}
