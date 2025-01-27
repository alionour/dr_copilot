import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalenderUI extends StatefulWidget {
  const CalenderUI({super.key});

  @override
  State<CalenderUI> createState() => _CalenderUIState();
}

class _CalenderUIState extends State<CalenderUI> {
  List<google_calendar.Event> _events = [];

  @override
  void initState() {
    super.initState();
    _fetchGoogleCalendarEvents();
  }

  Future<void> _fetchGoogleCalendarEvents() async {
    // try {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null || session.providerToken == null) {
      // User is not authenticated or providerToken is null
      print('User is not authenticated or providerToken is null');
      return;
    }

    final accessToken = session.providerToken;
    if (accessToken == null) {
      print('Access token is null');
      return;
    }

    final client = authenticatedClient(
      http.Client(),
      AccessCredentials(
        AccessToken(
          'Bearer',
          accessToken,
          DateTime.now().toUtc().add(
              const Duration(hours: 1)), // Ensure the expiry date is in UTC
        ),
        '',
        [
          google_calendar.CalendarApi.calendarScope,
          google_calendar.CalendarApi.calendarEventsScope,
          google_calendar.CalendarApi.calendarReadonlyScope,
          google_calendar.CalendarApi.calendarEventsReadonlyScope,
          google_calendar.CalendarApi.calendarSettingsReadonlyScope
        ], // Ensure all required scopes are included
        idToken: 
      ),
    );

    final calendarApi = google_calendar.CalendarApi(client);
    final events = await calendarApi.events.list('primary');
    setState(() {
      _events = events.items!;
    });
    // } catch (e) {
    //   print('Error fetching Google Calendar events: $e');
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SfCalendar(
        view: CalendarView.month,
        dataSource: GoogleCalendarDataSource(_events),
        allowAppointmentResize: true,
        allowDragAndDrop: true,
      ),
    );
  }
}

class GoogleCalendarDataSource extends CalendarDataSource {
  GoogleCalendarDataSource(List<google_calendar.Event> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].start!.dateTime!;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].end!.dateTime!;
  }

  @override
  String getSubject(int index) {
    return appointments![index].summary ?? '';
  }
}
