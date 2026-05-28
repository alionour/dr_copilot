import 'package:dr_copilot/src/features/auth/data/remote/auth_firebase_api.dart';
import 'package:dr_copilot/src/features/auth/data/repositories/auth_repositories_impl.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

final sl = GetIt.instance;

/// Initializes all dependency injections required for authentication features.
///
/// This function sets up the necessary services, repositories, and other dependencies
/// needed for authentication throughout the application. It should be called during
/// the app's initialization phase to ensure all authentication-related dependencies
/// are properly registered and available for use.
void initAuthInjections() {
  // Notifiers
  sl.registerLazySingleton(() => OwnerNotifier());

  // Bloc
  sl.registerFactory(() => AuthBloc(sl()));

  // Use cases
  sl.registerLazySingleton(() => AuthUseCase(sl<AbstractAuthRepository>()));

  // Services
  sl.registerLazySingleton(() => PermissionService());

  // Repository (register as abstract type for flexibility)
  sl.registerLazySingleton<AbstractAuthRepository>(
    () => AuthRepositoryImpl(sl<AuthFirebaseApi>()),
  );

  // Data sources
  sl.registerLazySingleton<AuthFirebaseApi>(
    () => AuthFirebaseApi(FirebaseAuth.instance),
  );
}
