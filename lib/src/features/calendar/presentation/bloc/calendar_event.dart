part of 'calendar_bloc.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object> get props => [];
}

class AuthenticateCalendar extends CalendarEvent {}

class GetCalendarEvents extends CalendarEvent {}

/// Event to get the list of calendars, extending the base CalendarEvent class.
/// 
/// This event can be dispatched to trigger the fetching of the list of calendars.
class GetCalendars extends CalendarEvent {
  /// Provides a list of properties for comparison.
  /// 
  /// This is used by Equatable to determine if two instances are equal.
  /// 
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [];
}

/// Event to get calendar events for a specific date range.
/// 
/// This event can be dispatched to trigger the fetching of calendar events for the specified date range.
class GetCalendarEventsForRange extends CalendarEvent {
  final DateTime startDate;
  final DateTime endDate;

  const GetCalendarEventsForRange(this.startDate, this.endDate);

  /// Provides a list of properties for comparison.
  /// 
  /// This is used by Equatable to determine if two instances are equal.
  /// 
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [startDate, endDate];
}

/// Event to add a new calendar event.
class AddCalendarEvent extends CalendarEvent {
  final Event newEvent;
  final String calendarId;

  const AddCalendarEvent(this.newEvent, this.calendarId);

  @override
  List<Object> get props => [newEvent, calendarId];
}