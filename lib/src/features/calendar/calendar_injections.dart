import 'package:get_it/get_it.dart';
import 'presentation/bloc/calendar_bloc.dart';

final sl = GetIt.instance;

/// Initializes the dependency injections required for the calendar feature.
///
/// This function sets up all necessary services and dependencies related to
/// calendar functionality, ensuring they are available throughout the application.
/// Call this during the application's initialization phase.
void initCalendarInjections() {
  // BLoC
  sl.registerFactory(() => CalendarBloc());
}
