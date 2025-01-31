part of 'calendar_bloc.dart';

/// Base class for all calendar states, extending Equatable to allow for easy comparison.
/// 
/// This class is sealed, meaning it cannot be extended outside of this file.
sealed class CalendarState extends Equatable {
  const CalendarState();

  /// Provides a list of properties for comparison.
  /// 
  /// This is used by Equatable to determine if two instances are equal.
  /// 
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [];
}

/// Initial state of the calendar, before any events have been loaded.
final class CalendarInitial extends CalendarState {}

/// State when calendar events are being loaded.
final class CalendarEventsLoading extends CalendarState {}

/// State when the list of calendars is being loaded.
final class CalendarsLoading extends CalendarState {}

/// State when calendar events have been successfully loaded.
/// 
/// Contains a list of loaded events and their corresponding calendar colors.
final class CalendarEventsLoaded extends CalendarState {
  final List<Event> events;
  final Map<String, Color> calendarColors;

  /// Constructor for CalendarEventsLoaded state.
  /// 
  /// @param events The list of loaded events.
  /// @param calendarColors The map of calendar IDs to their colors.
  const CalendarEventsLoaded(this.events, this.calendarColors);

  /// Provides a list of properties for comparison.
  /// 
  /// This is used by Equatable to determine if two instances are equal.
  /// 
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [events, calendarColors];
}

/// State when the list of calendars has been successfully loaded.
/// 
/// Contains a list of loaded calendar list entries.
final class CalendarsLoaded extends CalendarState {
  final List<CalendarListEntry> calendars;

  /// Constructor for CalendarsLoaded state.
  /// 
  /// @param calendars The list of loaded calendar list entries.
  const CalendarsLoaded(this.calendars);

  /// Provides a list of properties for comparison.
  /// 
  /// This is used by Equatable to determine if two instances are equal.
  /// 
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [calendars];
}
