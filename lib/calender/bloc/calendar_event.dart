part of 'calendar_bloc.dart';

/// Base class for all calendar events, extending Equatable to allow for easy comparison.
/// 
/// This class is sealed, meaning it cannot be extended outside of this file.
sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  /// Provides a list of properties for comparison.
  /// 
  /// This is used by Equatable to determine if two instances are equal.
  /// 
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [];
}

/// Event to get calendar events, extending the base CalendarEvent class.
/// 
/// This event can be dispatched to trigger the fetching of calendar events.
class GetCalendarEvents extends CalendarEvent {
  /// Provides a list of properties for comparison.
  /// 
  /// This is used by Equatable to determine if two instances are equal.
  /// 
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [];
}

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