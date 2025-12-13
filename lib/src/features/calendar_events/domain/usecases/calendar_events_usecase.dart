import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/repositories/abstract_calendar_events_repository.dart';

/// Use case for calendar events business logic
class CalendarEventsUseCase {
  final AbstractCalendarEventsRepository repository;

  CalendarEventsUseCase(this.repository);

  /// Validate event before creation/update
  Either<Failure, bool> validateEvent(CalendarEventModel event) {
    // Check required fields
    if (event.title.trim().isEmpty) {
      return Left(ValidationFailure('Event title is required'));
    }

    // Check that end time is after start time
    if (event.endDateTime.toDate().isBefore(event.startDateTime.toDate()) ||
        event.endDateTime.toDate().isAtSameMomentAs(
          event.startDateTime.toDate(),
        )) {
      return Left(ValidationFailure('Event end time must be after start time'));
    }

    // Check that event is not in the past (for new events)
    if (event.id.isEmpty &&
        event.startDateTime.toDate().isBefore(DateTime.now())) {
      return Left(ValidationFailure('Cannot create events in the past'));
    }

    return Right(true);
  }

  /// Get events by date range
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Validate date range
    if (endDate.isBefore(startDate)) {
      return Left(ValidationFailure('End date must be after start date'));
    }

    return await repository.getEventsByDateRange(startDate, endDate);
  }

  /// Get events by type
  Future<Either<Failure, List<CalendarEventModel>>> getEventsByType(
    String eventType,
  ) async {
    return await repository.getEventsByType(eventType);
  }

  /// Add a new event with validation
  Future<Either<Failure, CalendarEventModel>> addEvent(
    CalendarEventModel event,
  ) async {
    // Validate event
    final validation = validateEvent(event);
    if (validation.isLeft()) {
      return validation.fold(
        (failure) => Left(failure),
        (_) => Left(ValidationFailure('Unknown validation error')),
      );
    }

    // Check for conflicts (optional - can be enabled based on requirements)
    // final conflicts = await checkConflicts(event);
    // if (conflicts.isNotEmpty) {
    //   return Left(ValidationFailure('Event conflicts with existing events'));
    // }

    return await repository.addEvent(event);
  }

  /// Update an existing event
  Future<Either<Failure, CalendarEventModel>> updateEvent(
    String id,
    CalendarEventModel event,
  ) async {
    // Validate event
    final validation = validateEvent(event);
    if (validation.isLeft()) {
      return validation.fold(
        (failure) => Left(failure),
        (_) => Left(ValidationFailure('Unknown validation error')),
      );
    }

    return await repository.updateEvent(id, event);
  }

  /// Delete an event
  Future<Either<Failure, void>> deleteEvent(String id) async {
    return await repository.deleteEvent(id);
  }

  /// Search events
  Future<Either<Failure, List<CalendarEventModel>>> searchEvents(
    String query,
  ) async {
    if (query.trim().isEmpty) {
      return Left(ValidationFailure('Search query cannot be empty'));
    }

    return await repository.searchEvents(query);
  }

  /// Get event by ID
  Future<Either<Failure, CalendarEventModel>> getEventById(String id) async {
    return await repository.getEventById(id);
  }

  /// Get all events
  Future<Either<Failure, List<CalendarEventModel>>> getAllEvents() async {
    return await repository.getAllEvents();
  }

  /// Get event linked to a session
  Future<Either<Failure, CalendarEventModel?>> getEventBySessionId(
    String sessionId,
  ) async {
    return await repository.getEventBySessionId(sessionId);
  }

  /// Get event linked to an evaluation
  Future<Either<Failure, CalendarEventModel?>> getEventByEvaluationId(
    String evaluationId,
  ) async {
    return await repository.getEventByEvaluationId(evaluationId);
  }

  /// Check for conflicting events in the same time slot for a doctor
  /// Returns list of conflicting events
  Future<List<CalendarEventModel>> checkConflicts(
    CalendarEventModel event,
  ) async {
    // Get events in the same date range
    final result = await repository.getEventsByDateRange(
      event.startDateTime.toDate(),
      event.endDateTime.toDate(),
    );

    return result.fold((failure) => [], (events) {
      // Filter for same doctor and overlapping time
      return events.where((e) {
        // Skip checking against itself
        if (e.id == event.id) return false;

        // Only check doctor's events
        if (e.doctorId != event.doctorId) return false;

        // Check for time overlap
        final existingStart = e.startDateTime.toDate();
        final existingEnd = e.endDateTime.toDate();
        final newStart = event.startDateTime.toDate();
        final newEnd = event.endDateTime.toDate();

        return (newStart.isBefore(existingEnd) &&
            newEnd.isAfter(existingStart));
      }).toList();
    });
  }
}

/// Validation failure class
class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message, 400);
}
