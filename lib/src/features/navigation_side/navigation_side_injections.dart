import 'package:dr_copilot/src/features/navigation_side/presentation/bloc/navigation_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

/// Initializes the dependency injections required for the navigation side feature.
///
/// This function sets up all necessary services and dependencies related to
/// navigation and side menu functionality, ensuring they are available throughout
/// the application. Call this during the application's initialization phase.
void initNavigationSideInjections() {
  // Bloc
  sl.registerFactory(() => NavigationBloc());
}
