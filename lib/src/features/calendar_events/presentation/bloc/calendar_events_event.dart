part of 'calendar_events_bloc.dart';

/// Base class for all calendar events BLoC events
abstract class CalendarEventsEvent extends Equatable {
  const CalendarEventsEvent();

  @override
  List<Object?> get props => [];
}

/// Load events within a specific date range
class LoadEventsByDateRange extends CalendarEventsEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadEventsByDateRange(this.startDate, this.endDate);

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Load all events without date filtering
class LoadAllEvents extends CalendarEventsEvent {
  const LoadAllEvents();
}

/// Filter events by type
class FilterByType extends CalendarEventsEvent {
  final String? eventType;

  const FilterByType(this.eventType);

  @override
  List<Object?> get props => [eventType];
}

/// Add a new calendar event
class AddCalendarEvent extends CalendarEventsEvent {
  final CalendarEventModel event;

  const AddCalendarEvent(this.event);

  @override
  List<Object?> get props => [event];
}

/// Update an existing calendar event
class UpdateCalendarEvent extends CalendarEventsEvent {
  final String id;
  final CalendarEventModel event;

  const UpdateCalendarEvent(this.id, this.event);

  @override
  List<Object?> get props => [id, event];
}

/// Delete a calendar event
class DeleteCalendarEvent extends CalendarEventsEvent {
  final String id;

  const DeleteCalendarEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Search events by query
class SearchEvents extends CalendarEventsEvent {
  final String query;

  const SearchEvents(this.query);

  @override
  List<Object?> get props => [query];
}

/// Load a single event by ID
class LoadEventById extends CalendarEventsEvent {
  final String id;

  const LoadEventById(this.id);

  @override
  List<Object?> get props => [id];
}
