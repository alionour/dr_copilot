part of 'calendar_bloc.dart';

/// Base class for all calendar states, extending Equatable to allow for easy comparison.
///
/// This class is sealed, meaning it cannot be extended outside of this file.
sealed class CalendarState extends Equatable {
  /// A list of [Event] objects representing the events in the calendar.
  ///
  /// This list is immutable and initialized as an empty constant list.
  final List<Event> events;

  const CalendarState(this.events);

  /// Provides a list of properties for comparison.
  ///
  /// This is used by Equatable to determine if two instances are equal.
  ///
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [events];
}

/// Initial state of the calendar, before any events have been loaded.
final class CalendarInitial extends CalendarState {
  const CalendarInitial() : super(const []);
}

/// State indicating that Google Calendar authentication is required.
final class CalendarAuthenticationRequired extends CalendarState {
  const CalendarAuthenticationRequired() : super(const []);
}

/// State when calendar events are being loaded.
final class CalendarEventsLoading extends CalendarState {
  const CalendarEventsLoading() : super(const []);
}

/// State when the list of calendars is being loaded.
final class CalendarsLoading extends CalendarState {
  const CalendarsLoading() : super(const []);
}

/// State when calendar events have been successfully loaded.
///
/// Contains a list of loaded events and their corresponding calendar colors.
final class CalendarEventsLoaded extends CalendarState {
  final Map<String, Color> calendarColors;

  const CalendarEventsLoaded(super.events, this.calendarColors);

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
  const CalendarsLoaded(this.calendars) : super(const []);

  /// Provides a list of properties for comparison.
  ///
  /// This is used by Equatable to determine if two instances are equal.
  ///
  /// @return A list of properties to compare.
  @override
  List<Object> get props => [calendars];
}
