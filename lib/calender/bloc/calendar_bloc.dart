import 'package:bloc/bloc.dart';
import 'package:dr_copilot/auth/helpers/google_signin_helper.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

part 'calendar_event.dart';
part 'calendar_state.dart';

/// Bloc for handling calendar events and states.
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  /// Constructor for CalendarBloc, initializing with the initial state.
  CalendarBloc() : super(CalendarInitial()) {
    on<GetCalendarEvents>(_fetchGoogleCalendarEvents);
    on<GetCalendars>(_fetchGoogleCalendars);
  }

  final googleSignIn = GoogleSignInHelper();

  /// Fetches Google Calendar events from all calendars and emits the appropriate state.
  ///
  /// @param event The event to fetch calendar events.
  /// @param emit The function to emit states.
  Future<void> _fetchGoogleCalendarEvents(
      GetCalendarEvents event, Emitter<CalendarState> emit) async {
    try {
      // Retrieve an [auth.AuthClient] from the current [GoogleSignIn] instance.
      final AuthClient? client = googleSignIn.client;

      assert(client != null, 'Authenticated client missing!');

      final calendarApi = CalendarApi(client!);
      final calendarList = await calendarApi.calendarList.list();
      List<Event> allEvents = [];
      Map<String, Color> calendarColors = {};

      for (var calendar in calendarList.items!) {
        print('Processing calendar: ${calendar.summary} (ID: ${calendar.id})');
        final events = await calendarApi.events.list(calendar.id!);
        allEvents.addAll(events.items!);
        // Add calendar color to the map
        if (calendar.backgroundColor != null) {
          calendarColors[calendar.id!] = Color(int.parse(calendar.backgroundColor!.replaceFirst('#', '0xFF')));
        }
        // Log event details
        for (var event in events.items!) {
          print('Event: ${event.summary}, Calendar ID: ${calendar.id}');
        }
      }

      emit(CalendarEventsLoaded(allEvents, calendarColors));
    } catch (e) {
      print('Error fetching calendar events: $e');
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
      final AuthClient? client = googleSignIn.client;

      assert(client != null, 'Authenticated client missing!');

      final calendarApi = CalendarApi(client!);
      final calendarList = await calendarApi.calendarList.list();
      emit(CalendarsLoaded(calendarList.items!));
    } catch (e) {
      print('Error fetching calendars: $e');
      emit(CalendarInitial()); // Emit initial state on error
    }
  }
}
