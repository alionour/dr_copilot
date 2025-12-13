import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/calendar_events/data/remote/calendar_events_firebase_api.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/repositories/abstract_calendar_events_repository.dart';

/// Repository implementation for calendar events
/// Delegates to Firebase API
class CalendarEventsRepositoryImpl extends AbstractCalendarEventsRepository {
  final CalendarEventsFirebaseApi firebaseApi;

  CalendarEventsRepositoryImpl(this.firebaseApi);

  @override
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    return firebaseApi.getEventsByDateRange(startDate, endDate);
  }

  @override
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByType(
    String eventType,
  ) {
    return firebaseApi.getEventsByType(eventType);
  }

  @override
  Future<Either<Failure, CalendarEventModel>> addEvent(
    CalendarEventModel event,
  ) {
    return firebaseApi.addEvent(event);
  }

  @override
  Future<Either<Failure, CalendarEventModel>> updateEvent(
    String id,
    CalendarEventModel event,
  ) {
    return firebaseApi.updateEvent(id, event);
  }

  @override
  Future<Either<Failure, void>> deleteEvent(String id) {
    return firebaseApi.deleteEvent(id);
  }

  @override
  Future<Either<Failure, List<CalendarEventModel>>> searchEvents(String query) {
    return firebaseApi.searchEvents(query);
  }

  @override
  Future<Either<Failure, CalendarEventModel>> getEventById(String id) {
    return firebaseApi.getEventById(id);
  }

  @override
  Future<Either<Failure, List<CalendarEventModel>>> getAllEvents() {
    return firebaseApi.getAllEvents();
  }

  @override
  Future<Either<Failure, CalendarEventModel?>> getEventBySessionId(
    String sessionId,
  ) {
    return firebaseApi.getEventBySessionId(sessionId);
  }

  @override
  Future<Either<Failure, CalendarEventModel?>> getEventByEvaluationId(
    String evaluationId,
  ) {
    return firebaseApi.getEventByEvaluationId(evaluationId);
  }
}
