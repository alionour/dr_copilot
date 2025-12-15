import 'package:get_it/get_it.dart';
import 'presentation/bloc/settings_bloc.dart';

final sl = GetIt.instance;

/// Initializes the dependency injections required for the settings feature.
///
/// This function sets up all necessary services and dependencies related to
/// application settings, ensuring they are available throughout the application.
/// Call this during the application's initialization phase.
void initSettingsInjections() {
  // BLoC
  sl.registerFactory(() => SettingsBloc());
}

