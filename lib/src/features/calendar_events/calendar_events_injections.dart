import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/calendar_events/data/remote/calendar_events_firebase_api.dart';
import 'package:dr_copilot/src/features/calendar_events/data/repositories/calendar_events_repository_impl.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/repositories/abstract_calendar_events_repository.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/usecases/calendar_events_usecase.dart';
import 'package:dr_copilot/src/features/calendar_events/presentation/bloc/calendar_events_bloc.dart';

/// Initializes the dependency injections required for calendar events.
void initCalendarEventsInjections() {
  // Data Layer - Firebase API
  sl.registerLazySingleton<CalendarEventsFirebaseApi>(
    () => CalendarEventsFirebaseApi(),
  );

  // Data Layer - Repository
  sl.registerLazySingleton<AbstractCalendarEventsRepository>(
    () => CalendarEventsRepositoryImpl(sl()),
  );

  // Domain Layer - Use Case
  sl.registerLazySingleton<CalendarEventsUseCase>(
    () => CalendarEventsUseCase(sl()),
  );

  // Presentation Layer - BLoC
  sl.registerFactory<CalendarEventsBloc>(() => CalendarEventsBloc(sl()));
}

