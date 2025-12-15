part of 'calendar_events_bloc.dart';

/// Base class for all calendar events BLoC states
abstract class CalendarEventsState extends Equatable {
  const CalendarEventsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any events are loaded
class CalendarEventsInitial extends CalendarEventsState {}

/// Loading state while fetching events
class CalendarEventsLoading extends CalendarEventsState {}

/// Loaded state with list of events
class CalendarEventsLoaded extends CalendarEventsState {
  final List<CalendarEventModel> events;
  final String? filter;

  const CalendarEventsLoaded(this.events, {this.filter});

  @override
  List<Object?> get props => [events, filter];
}

/// Error state with error message
class CalendarEventsError extends CalendarEventsState {
  final String message;

  const CalendarEventsError(this.message);

  @override
  List<Object?> get props => [message];
}

