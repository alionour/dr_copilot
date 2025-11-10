import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/helper/google_signin_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:http/http.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

/// Bloc for handling calendar events and states.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  /// Constructor for CalendarBloc, initializing with the initial state.
  CalendarBloc() : super(CalendarInitial()) {
    on<GetCalendarEvents>(_fetchGoogleCalendarEvents);
    on<GetCalendars>(_fetchGoogleCalendars);
    on<GetCalendarEventsForRange>(_fetchGoogleCalendarEventsForRange);
    on<AddCalendarEvent>(_addCalendarEvent);
    on<AuthenticateCalendar>(_authenticateCalendar);
  }

  final googleSignIn = GoogleSignInHelper();
  final Map<String, Event> _cachedEvents = {};
  final List<DateTimeRange> _fetchedRanges = [];

  Future<void> _authenticateCalendar(AuthenticateCalendar event, Emitter<CalendarState> emit) async {
    try {
      Client? client = await googleSignIn.ensureClientInitialized();
      if (client == null) {
        // If client is still null, it means no user is signed in or silent sign-in failed.
        // Attempt to sign in interactively.
        final account = await googleSignIn.signIn();
        if (account != null) {
          // If interactive sign-in is successful, try to get the client again.
          client = await googleSignIn.ensureClientInitialized();
        }
      }

      if (client == null) {
        emit(CalendarAuthenticationRequired());
      } else {
        // If authentication is successful, trigger a refresh of events
        add(GetCalendarEvents());
      }
    } catch (e) {
      debugPrint('Error during calendar authentication: $e');
      emit(CalendarAuthenticationRequired());
    }
  }

  /// Fetches Google Calendar events from all calendars and emits the appropriate state.
  ///
  /// @param event The event to fetch calendar events.
  /// @param emit The function to emit states.
  Future<void> _fetchGoogleCalendarEvents(
      GetCalendarEvents event, Emitter<CalendarState> emit) async {
    try {
      // Always ensure the client is initialized and valid
      Client? client = await googleSignIn.client;

      if (client == null) {
        debugPrint(
            'Authenticated client missing and could not be initialized!');
        emit(CalendarAuthenticationRequired());
        return;
      }

      final calendarApi = CalendarApi(client);
      final calendarList = await calendarApi.calendarList.list();
      List<Event> allEvents = [];
      Map<String, Color> calendarColors = {};

      for (var calendar in calendarList.items!) {
        debugPrint(
            'Processing calendar: ${calendar.summary} (ID: ${calendar.id})');
        final events = await calendarApi.events.list(
          calendar.id!,
          maxResults: 2500,
        );
        allEvents.addAll(events.items!);
        // Add calendar color to the map
        if (calendar.backgroundColor != null) {
          calendarColors[calendar.id!] = Color(
              int.parse(calendar.backgroundColor!.replaceFirst('#', '0xFF')));
        }
        // Log event details
        for (var event in events.items!) {
          debugPrint('Event: ${event.summary}, Calendar: ${calendar.summary}');
        }
      }

      // Cache the fetched events
      for (var event in allEvents) {
        _cachedEvents[event.id!] = event;
      }

      emit(CalendarEventsLoaded(_cachedEvents.values.toList(), calendarColors));
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      emit(CalendarInitial()); // Emit initial state on error
    }
  }

  /// Fetches Google Calendar events for a specific date range and emits the appropriate state.
  ///
  /// @param event The event to fetch calendar events for the specified date range.
  /// @param emit The function to emit states.
  Future<void> _fetchGoogleCalendarEventsForRange(
      GetCalendarEventsForRange event, Emitter<CalendarState> emit) async {
    try {
      // Check if the date range has already been fetched
      final range = DateTimeRange(start: event.startDate, end: event.endDate);
      if (_fetchedRanges.any((r) =>
          r.start.isAtSameMomentAs(range.start) &&
          r.end.isAtSameMomentAs(range.end))) {
        debugPrint('Date range already fetched: $range');
        emit(CalendarEventsLoaded(_cachedEvents.values.toList(), const {}));
        return;
      }

      // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
      final Client? client = await googleSignIn.client;

      if (client == null) {
        debugPrint('Authenticated client missing!');
        emit(CalendarAuthenticationRequired());
        return;
      }

      final calendarApi = CalendarApi(client);
      final calendarList = await calendarApi.calendarList.list();
      List<Event> allEvents = [];
      Map<String, Color> calendarColors = {};

      for (var calendar in calendarList.items!) {
        debugPrint(
            'Processing calendar: ${calendar.summary} (ID: ${calendar.id})');
        final events = await calendarApi.events.list(
          calendar.id!,
          timeMin: event.startDate.toUtc(),
          timeMax: event.endDate.toUtc(),
        );
        allEvents.addAll(events.items!);
        // Add calendar color to the map
        if (calendar.backgroundColor != null) {
          calendarColors[calendar.id!] = Color(
              int.parse(calendar.backgroundColor!.replaceFirst('#', '0xFF')));
        }
        // Log event details
        for (var event in events.items!) {
          debugPrint('Event: ${event.summary}, Calendar: ${calendar.summary}');
        }
      }

      // Cache the fetched events
      for (var event in allEvents) {
        _cachedEvents[event.id!] = event;
      }

      // Add the fetched range to the list
      _fetchedRanges.add(range);

      emit(CalendarEventsLoaded(_cachedEvents.values.toList(), calendarColors));
    } catch (e) {
      debugPrint('Error fetching calendar events: $e');
      emit(CalendarInitial()); // Emit initial state on error
    }
  }

  /// Fetches Google Calendars and emits the appropriate state.
  ///
  /// @param event The event to fetch calendars.
  /// @param emit The function to emit states.
  Future<void> _fetchGoogleCalendars(
      GetCalendars event, Emitter<CalendarState> emit) async {
    try {
      // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
      final Client? client = await googleSignIn.client;

      if (client == null) {
        debugPrint('Authenticated client missing!');
        emit(CalendarAuthenticationRequired());
        return;
      }

      final calendarApi = CalendarApi(client);
      final calendarList = await calendarApi.calendarList.list();
      emit(CalendarsLoaded(calendarList.items!));
    } catch (e) {
      debugPrint('Error fetching calendars: $e');
      emit(CalendarInitial()); // Emit initial state on error
    }
  }

  /// Adds a new calendar event and emits the appropriate state.
  ///
  /// @param event The event to add a new calendar event.
  /// @param emit The function to emit states.
  Future<void> _addCalendarEvent(
      AddCalendarEvent event, Emitter<CalendarState> emit) async {
    try {
      // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
      final Client? client = await googleSignIn.client;

      if (client == null) {
        debugPrint('Authenticated client missing!');
        emit(CalendarAuthenticationRequired());
        return;
      }

      final calendarApi = CalendarApi(client);
      await calendarApi.events.insert(event.newEvent, event.calendarId);

      // Refresh the events after adding the new event
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      add(GetCalendarEventsForRange(startOfMonth, endOfMonth));
    } catch (e) {
      debugPrint('Error adding calendar event: $e');
      emit(CalendarInitial()); // Emit initial state on error
    }
  }
}
