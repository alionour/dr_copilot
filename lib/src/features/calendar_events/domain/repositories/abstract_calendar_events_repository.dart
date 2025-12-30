import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';

/// Abstract repository interface for calendar events
abstract class AbstractCalendarEventsRepository {
  /// Get events within a date range
  /// [startDate] Start of the date range
  /// [endDate] End of the date range
  /// Returns list of calendar events or failure
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  );

  /// Get events filtered by type
  /// [eventType] Type of event to filter (session, evaluation, etc.)
  /// Returns list of calendar events or failure
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByType(
    String eventType,
  );

  /// Add a new calendar event
  /// [event] The calendar event to create
  /// Returns the created event with generated ID or failure
  Future<Either<Failure, CalendarEventModel>> addEvent(
    CalendarEventModel event,
  );

  /// Update an existing calendar event
  /// [id] The event ID to update
  /// [event] The updated event data
  /// Returns the updated event or failure
  Future<Either<Failure, CalendarEventModel>> updateEvent(
    String id,
    CalendarEventModel event,
  );

  /// Delete a calendar event (soft delete)
  /// [id] The event ID to delete
  /// Returns void or failure
  Future<Either<Failure, void>> deleteEvent(String id);

  /// Search events by title or description
  /// [query] Search query string
  /// Returns list of matching events or failure
  Future<Either<Failure, List<CalendarEventModel>>> searchEvents(String query);

  /// Get a single event by ID
  /// [id] The event ID
  /// Returns the event or failure
  Future<Either<Failure, CalendarEventModel>> getEventById(String id);

  /// Get all events without date filtering
  /// Returns all calendar events for the clinic or failure
  Future<Either<Failure, List<CalendarEventModel>>> getAllEvents();

  /// Get event linked to a specific session
  /// [sessionId] The session ID to find linked event
  /// Returns the linked event or failure
  Future<Either<Failure, CalendarEventModel?>> getEventBySessionId(
    String sessionId,
  );

  /// Get event linked to a specific evaluation
  /// [evaluationId] The evaluation ID to find linked event
  /// Returns the linked event or failure
  Future<Either<Failure, CalendarEventModel?>> getEventByEvaluationId(
    String evaluationId,
  );

  /// Get all deleted events
  /// Returns list of deleted calendar events or failure
  Future<Either<Failure, List<CalendarEventModel>>> getDeletedEvents();

  /// Restore a deleted event
  /// [id] The event ID to restore
  /// Returns void or failure
  Future<Either<Failure, void>> restoreEvent(String id);

  /// Permanently delete an event
  /// [id] The event ID to delete permanently
  /// Returns void or failure
  Future<Either<Failure, void>> permanentlyDeleteEvent(String id);
}
