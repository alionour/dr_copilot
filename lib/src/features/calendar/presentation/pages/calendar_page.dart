import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/presentation/bloc/calendar_events_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/add_calendar_event_page.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<DateTime> _visibleDates = [];
  CalendarView _calendarView = CalendarView.month;
  final CalendarController _calendarController = CalendarController();
  String _headerDate = '';

  @override
  void initState() {
    super.initState();
    // Initial load will happen in onViewChanged or we can trigger one here if needed
    // But better to rely on onViewChanged which fires on processing
  }

  Future<void> _navigateToAddEvent(BuildContext context) async {
    final result = await Navigator.of(context).push<CalendarEventModel>(
      MaterialPageRoute(builder: (_) => const AddCalendarEventPage()),
    );
    if (result != null && context.mounted) {
      context.read<CalendarEventsBloc>().add(AddCalendarEvent(result));
    }
  }

  Future<void> _navigateToEditEvent(
    BuildContext context,
    CalendarEventModel event,
  ) async {
    final result = await Navigator.of(context).push<CalendarEventModel>(
      MaterialPageRoute(
        builder: (_) => AddCalendarEventPage(eventToEdit: event),
      ),
    );
    if (result != null && context.mounted) {
      if (result.id.isNotEmpty) {
        context.read<CalendarEventsBloc>().add(
          UpdateCalendarEvent(result.id, result),
        );
      } else {
        context.read<CalendarEventsBloc>().add(AddCalendarEvent(result));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);

    return BlocProvider<CalendarEventsBloc>(
      create: (context) => sl<CalendarEventsBloc>(), // Use DI
      child: Scaffold(
        appBar: AppBar(
          title: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _showCalendarViewSelection(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _headerDate.isEmpty ? 'calendarTitle'.tr() : _headerDate,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
          leading: const Icon(Icons.calendar_month_outlined),
          actions: [
            if (navMenuButton != null) navMenuButton,
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToAddEvent(context),
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            return BlocConsumer<CalendarEventsBloc, CalendarEventsState>(
              listener: (context, state) {
                if (state is CalendarEventsError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                }
              },
              builder: (context, state) {
                List<CalendarEventModel> events = [];
                bool isLoading = false;

                if (state is CalendarEventsLoading) {
                  isLoading = true;
                } else if (state is CalendarEventsLoaded) {
                  events = state.events;
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: DefaultTextStyle(
                        style:
                            Theme.of(context).textTheme.bodyMedium ??
                            const TextStyle(),
                        child: SelectionContainer.disabled(
                          child: SfCalendar(
                            key: ValueKey(_calendarView),
                            controller: _calendarController,
                            view: _calendarView,
                            headerHeight:
                                0, // Disable default header to prevent crash
                            dataSource: InternalCalendarDataSource(events),
                            onTap: (calendarTapDetails) {
                              if (calendarTapDetails.targetElement ==
                                  CalendarElement.header) {
                                _showCalendarViewSelection(context);
                              } else if (calendarTapDetails.targetElement ==
                                  CalendarElement.appointment) {
                                final appointment =
                                    calendarTapDetails.appointments!.first;
                                if (appointment is CalendarEventModel) {
                                  // Show details
                                  _showEventDetails(context, appointment);
                                }
                              }
                            },
                            allowAppointmentResize:
                                false, // Read only for now unless logic added
                            allowDragAndDrop: false,
                            onViewChanged: (ViewChangedDetails details) {
                              _visibleDates = details.visibleDates;
                              if (_visibleDates.isNotEmpty) {
                                final startDate = _visibleDates.first;
                                final endDate = _visibleDates.last;
                                final midDate =
                                    _visibleDates[_visibleDates.length ~/ 2];

                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (mounted) {
                                    setState(() {
                                      _headerDate = DateFormat(
                                        'MMMM yyyy',
                                      ).format(midDate);
                                    });
                                  }
                                });

                                context.read<CalendarEventsBloc>().add(
                                  LoadEventsByDateRange(startDate, endDate),
                                );
                              }
                            },
                            monthViewSettings: const MonthViewSettings(
                              appointmentDisplayMode:
                                  MonthAppointmentDisplayMode.appointment,
                              showAgenda: true,
                            ),
                            timeSlotViewSettings: const TimeSlotViewSettings(
                              startHour: 7,
                              endHour: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (isLoading)
                      const Center(child: CircularProgressIndicator.adaptive()),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showCalendarViewSelection(BuildContext context) async {
    final selected = await showModalBottomSheet<CalendarView>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                CalendarView.schedule,
              ].map(
                (view) => ListTile(
                  leading: Icon(
                    Icons.calendar_view_day, // Generic icon
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    view.toString().split('.').last, // Simple label for now
                    style: TextStyle(
                      fontWeight: _calendarView == view
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _calendarView == view
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop(view);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null && selected != _calendarView) {
      setState(() {
        _calendarView = selected;
        _calendarController.view = selected;
      });
    }
  }

  void _showEventDetails(BuildContext context, CalendarEventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'type'.tr()}: ${'eventType.${event.eventType}'.tr()}'),
            if (event.description != null)
              Text('${'description'.tr()}: ${event.description}'),
            const SizedBox(height: 8),
            Text(
              '${'startDateTime'.tr()}: ${DateFormat('yyyy-MM-dd HH:mm').format(event.startDateTime.toDate())}',
            ),
            Text(
              '${'endDateTime'.tr()}: ${DateFormat('yyyy-MM-dd HH:mm').format(event.endDateTime.toDate())}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Delete confirmation
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('deleteEvent'.tr()),
                  content: Text(
                    'deleteReportConfirmation'.tr(),
                  ), // Reuse or add generic confirm
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<CalendarEventsBloc>().add(
                          DeleteCalendarEvent(event.id),
                        );
                        Navigator.of(context).pop(); // Close confirm
                        Navigator.of(context).pop(); // Close details
                      },
                      child: Text(
                        'delete'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToEditEvent(context, event);
            },
            child: Text('edit'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'close'.tr(),
            ), // Assuming 'close' exists or use 'cancel'
          ),
        ],
      ),
    );
  }
}

class InternalCalendarDataSource extends CalendarDataSource {
  InternalCalendarDataSource(List<CalendarEventModel> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as CalendarEventModel).startDateTime.toDate();
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as CalendarEventModel).endDateTime.toDate();
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as CalendarEventModel).title;
  }

  @override
  Color getColor(int index) {
    final event = appointments![index] as CalendarEventModel;
    if (event.color != null) {
      try {
        return Color(int.parse(event.color!.replaceAll('#', '0xFF')));
      } catch (_) {}
    }

    // Type-based colors
    switch (event.type) {
      case CalendarEventType.session:
        return Colors.blue;
      case CalendarEventType.evaluation:
        return Colors.purple;
      case CalendarEventType.appointment:
        return Colors.green;
      case CalendarEventType.holiday:
        return Colors.red;
      case CalendarEventType.vacation:
        return Colors.orange;
      case CalendarEventType.clinicClosure:
        return Colors.red.shade900;
      case CalendarEventType.unavailable:
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  bool isAllDay(int index) {
    // Can implement logic if needed, e.g. for holidays
    final event = appointments![index] as CalendarEventModel;
    return event.type == CalendarEventType.holiday ||
        event.type == CalendarEventType.vacation;
  }
}
