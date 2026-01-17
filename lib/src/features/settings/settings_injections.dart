import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:dr_copilot/src/features/settings/domain/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

/// Initializes the dependency injections required for the settings feature.
///
/// This function sets up all necessary services and dependencies related to
/// application settings, ensuring they are available throughout the application.
/// Call this during the application's initialization phase.
void initSettingsInjections() {
  // Repository
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());

  // BLoC
  sl.registerFactory(() => SettingsBloc(
        repository: sl<SettingsRepository>(),
        ownerNotifier: OwnerNotifier(),
      ));
}
