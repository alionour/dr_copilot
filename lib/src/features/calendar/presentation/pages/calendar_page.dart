import 'package:dr_copilot/src/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<DateTime> _visibleDates = [];
  CalendarView _calendarView = CalendarView.month; // Default view

  @override
  void initState() {
    super.initState();
    context.read<CalendarBloc>().add(AuthenticateCalendar());
  }

  Future<void> _refreshCalendarEvents(BuildContext context) async {
    if (_visibleDates.isNotEmpty) {
      final startDate = _visibleDates.first;
      final endDate = _visibleDates.last;
      BlocProvider.of<CalendarBloc>(
        context,
      ).add(GetCalendarEventsForRange(startDate, endDate));
    }
  }

  // ignore: unused_element
  Future<void> _navigateToAddEvent(BuildContext context) async {
    final result = await context.push<Map<String, dynamic>>('/events/new');
    if (result != null) {
      final newEvent = result['event'] as google_calendar.Event;
      final calendarId = result['calendar'] as String;
      if (!context.mounted) return;
      BlocProvider.of<CalendarBloc>(
        context,
      ).add(AddCalendarEvent(newEvent, calendarId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);
    return BlocProvider(
      create: (context) => CalendarBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            borderRadius: BorderRadius.circular(6),
            // onTap: () => _showCalendarViewSelection(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('calendarTitle'.tr()),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ],
            ),
          ),
          leading: Icon(Icons.calendar_month_outlined),
          actions: [navMenuButton ?? SizedBox()],
        ),
        body: Builder(
          builder: (context) {
            return BlocBuilder<CalendarBloc, CalendarState>(
              builder: (context, state) {
                List<google_calendar.Event> events = [];
                Map<String, Color> calendarColors = {};
                if (state is CalendarAuthenticationRequired) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('calendarAuthRequired'.tr()),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<CalendarBloc>().add(
                              AuthenticateCalendar(),
                            );
                          },
                          child: Text('connectGoogleCalendar'.tr()),
                        ),
                      ],
                    ),
                  );
                }
                if (state is CalendarEventsLoaded) {
                  events = state.events;
                  calendarColors = state.calendarColors;
                }
                return RefreshIndicator(
                  onRefresh: () => _refreshCalendarEvents(context),
                  child: DefaultTextStyle(
                    style:
                        Theme.of(context).textTheme.bodyMedium ??
                        const TextStyle(),
                    child: SfCalendar(
                      key: ValueKey(
                        _calendarView,
                      ), // Force rebuild on view change
                      view: _calendarView, // Ensure this is bound to the state
                      dataSource: GoogleCalendarDataSource(
                        events,
                        calendarColors,
                      ),
                      onTap: (calendarTapDetails) {
                        if (calendarTapDetails.targetElement ==
                            CalendarElement.header) {
                          // show modal bottom sheet
                          _showCalendarViewSelection(context);
                        }
                      },
                      allowAppointmentResize: true,
                      allowDragAndDrop: true,
                      onViewChanged: (ViewChangedDetails details) {
                        _visibleDates = details.visibleDates;
                        final startDate = details.visibleDates.first;
                        final endDate = details.visibleDates.last;
                        debugPrint(
                          'View changed: StartDate=$startDate, EndDate=$endDate',
                        ); // Debugging
                        BlocProvider.of<CalendarBloc>(
                          context,
                        ).add(GetCalendarEventsForRange(startDate, endDate));
                      },
                      monthViewSettings: const MonthViewSettings(
                        appointmentDisplayMode:
                            MonthAppointmentDisplayMode.appointment,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // This method is used to show the modal bottom sheet for selecting calendar view
  void _showCalendarViewSelection(BuildContext context) async {
    final selected = await showModalBottomSheet<CalendarView>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final maxHeight = MediaQuery.of(context).size.height * 0.6;
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'calendarView.selectView'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  ...<CalendarView>[
                    CalendarView.day,
                    CalendarView.week,
                    CalendarView.workWeek,
                    CalendarView.month,
                    CalendarView.timelineDay,
                    CalendarView.timelineWeek,
                    CalendarView.timelineWorkWeek,
                    CalendarView.timelineMonth,
                  ].map(
                    (view) => ListTile(
                      leading: Icon(
                        Icons.calendar_month_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        'calendarView.${view.toString().split('.').last}'.tr(),
                        style: TextStyle(
                          fontWeight: _calendarView == view
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _calendarView == view
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      selected: _calendarView == view,
                      onTap: () {
                        Navigator.of(context).pop(view);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null && selected != _calendarView) {
      setState(() {
        _calendarView = selected;
      });
    }
  }
}

class GoogleCalendarDataSource extends CalendarDataSource {
  final Map<String, Color> calendarColors;

  GoogleCalendarDataSource(
    List<google_calendar.Event> source,
    this.calendarColors,
  ) {
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
