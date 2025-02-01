import 'package:dr_copilot/calender/bloc/calendar_bloc.dart';
import 'package:dr_copilot/calender/ui/add_calendar_event_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// UI for displaying and managing calendar events.
class CalenderUI extends StatefulWidget {
  const CalenderUI({super.key});

  @override
  State<CalenderUI> createState() => _CalenderUIState();
}

class _CalenderUIState extends State<CalenderUI> {
  List<DateTime> _visibleDates = [];
  CalendarView _calendarView = CalendarView.month; // Default view

  @override
  void initState() {
    super.initState();
  }

  /// Refreshes the calendar events for the visible date range.
  Future<void> _refreshCalendarEvents(BuildContext context) async {
    if (_visibleDates.isNotEmpty) {
      final startDate = _visibleDates.first;
      final endDate = _visibleDates.last;
      BlocProvider.of<CalendarBloc>(context)
          .add(GetCalendarEventsForRange(startDate, endDate));
    }
  }

  /// Navigates to the AddCalendarEventUI to add a new event.
  Future<void> _navigateToAddEvent(BuildContext context) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => const AddCalendarEventUI(),
      ),
    );
    if (result != null) {
      final newEvent = result['event'] as google_calendar.Event;
      final calendarId = result['calendar'] as String;
      BlocProvider.of<CalendarBloc>(context)
          .add(AddCalendarEvent(newEvent, calendarId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CalendarBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Calendar'),
          centerTitle: true,
          actions: [
            DropdownButton<CalendarView>(
              value: _calendarView,
              icon: const Icon(Icons.arrow_downward),
              onChanged: (CalendarView? newValue) {
                if (newValue != null) {
                  setState(() {
                    _calendarView = newValue;
                  });
                }
              },
              items: <CalendarView>[
                CalendarView.day,
                CalendarView.week,
                CalendarView.workWeek,
                CalendarView.month,
                CalendarView.timelineDay,
                CalendarView.timelineWeek,
                CalendarView.timelineWorkWeek,
                CalendarView.timelineMonth,
              ].map<DropdownMenuItem<CalendarView>>((CalendarView value) {
                return DropdownMenuItem<CalendarView>(
                  value: value,
                  child: Text(value.toString().split('.').last),
                );
              }).toList(),
            ),
          ],
        ),
        floatingActionButton: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            return FloatingActionButton(
              onPressed: () {
                _navigateToAddEvent(context);
              },
              child: const Icon(Icons.add),
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
            print('object $_calendarView');

            return RefreshIndicator(
              onRefresh: () => _refreshCalendarEvents(context),
              child: SfCalendar(
                view: _calendarView,
                dataSource: GoogleCalendarDataSource(events, calendarColors),
                allowAppointmentResize: true,
                allowDragAndDrop: true,
                onViewChanged: (ViewChangedDetails details) {
                  _visibleDates = details.visibleDates;
                  final startDate = details.visibleDates.first;
                  final endDate = details.visibleDates.last;
                  BlocProvider.of<CalendarBloc>(context)
                      .add(GetCalendarEventsForRange(startDate, endDate));
                },
                monthViewSettings: const MonthViewSettings(
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Data source for Google Calendar events.
class GoogleCalendarDataSource extends CalendarDataSource {
  final Map<String, Color> calendarColors;

  /// Constructor for GoogleCalendarDataSource.
  ///
  /// @param source The list of events.
  /// @param calendarColors The map of calendar IDs to their colors.
  GoogleCalendarDataSource(
      List<google_calendar.Event> source, this.calendarColors) {
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

  /// Converts Google Calendar color ID to actual color value.
  ///
  /// @param colorId The color ID from Google Calendar.
  /// @return The corresponding color value.
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
