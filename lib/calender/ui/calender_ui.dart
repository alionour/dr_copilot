import 'package:dr_copilot/calender/bloc/calendar_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalenderUI extends StatefulWidget {
  const CalenderUI({super.key});

  @override
  State<CalenderUI> createState() => _CalenderUIState();
}

class _CalenderUIState extends State<CalenderUI> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CalendarBloc()..add(GetCalendarEvents()),
      child: Scaffold(
        floatingActionButton: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            return FloatingActionButton(
              onPressed: () {
                BlocProvider.of<CalendarBloc>(context).add(GetCalendarEvents());
                // print state
                print((state is CalendarEventsLoaded)
                    ? (state).events.first.summary
                    : null);
              },
              child: const Icon(Icons.refresh),
            );
          },
        ),
        body: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            List<google_calendar.Event> events = [];
            Map<String, Color> calendarColors = {};
            if (state is CalendarEventsLoaded) {
              events = state.events;
              calendarColors = state.calendarColors;
              for (var element in events) {
                print(element.toJson());
              }
            }
            return SfCalendar(
              view: CalendarView.month,
              dataSource: GoogleCalendarDataSource(events, calendarColors),
              allowAppointmentResize: true,
              allowDragAndDrop: true,
              monthViewSettings: const MonthViewSettings(
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment),
            );
          },
        ),
      ),
    );
  }
}

class GoogleCalendarDataSource extends CalendarDataSource {
  final Map<String, Color> calendarColors;

  GoogleCalendarDataSource(List<google_calendar.Event> source, this.calendarColors) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].start?.dateTime ?? DateTime.now();
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].end?.dateTime ?? DateTime.now();
  }

  @override
  String getSubject(int index) {
    return appointments![index].summary ?? '';
  }

  @override
  String getLocation(int index) {
    return appointments![index].location ?? '';
  }

  @override
  String getNotes(int index) {
    return appointments![index].description ?? '';
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].start?.dateTime == null;
  }

  @override
  Color getColor(int index) {
    final eventColorId = appointments![index].colorId;
    if (eventColorId != null) {
      return _getGoogleCalendarColor(eventColorId);
    }
    final calendarId = appointments![index].organizer?.email;
    if (calendarId != null && calendarColors.containsKey(calendarId)) {
      return calendarColors[calendarId]!;
    }
    return Colors.blue;
  }

  Color _getGoogleCalendarColor(String colorId) {
    // Map of Google Calendar color IDs to actual color values
    const colorMap = {
      '1': Color(0xFF7986CB),
      '2': Color(0xFF33B679),
      '3': Color(0xFF8E24AA),
      '4': Color(0xFFE67C73),
      '5': Color(0xFFF6BF26),
      '6': Color(0xFFF4511E),
      '7': Color(0xFF039BE5),
      '8': Color(0xFFD50000),
      '9': Color(0xFF616161),
      '10': Color(0xFF3F51B5),
      '11': Color(0xFF0B8043),
      '12': Color(0xFF3E2723),
    };
    return colorMap[colorId] ?? Colors.blue;
  }
}
