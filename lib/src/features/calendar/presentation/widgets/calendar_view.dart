import 'package:dr_copilot/src/features/booking/presentation/pages/booking_management_page.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart'
    as sf; // Alias to avoid conflict

class CalendarView extends StatefulWidget {
  final List<CalendarEventModel> events;
  final sf.CalendarView currentView;
  final sf.CalendarController? controller;
  final ValueChanged<sf.CalendarView> onViewChanged;
  final Function(CalendarEventModel) onEventTap;
  final Function(DateTime, DateTime) onDateRangeChanged;
  final VoidCallback onAddEvent;
  final VoidCallback? onToggleSidebar; // If we add sidebar later
  final Widget? navMenuButton;
  final List<int>? nonWorkingDays;

  const CalendarView({
    super.key,
    required this.events,
    required this.currentView,
    this.controller,
    required this.onViewChanged,
    required this.onEventTap,
    required this.onDateRangeChanged,
    required this.onAddEvent,
    this.onToggleSidebar,
    this.navMenuButton,
    this.nonWorkingDays,
  });

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  // We can keep some transient UI state here if needed, but primary state comes from parent
  String _headerDate = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          IconButton(
            icon: const Icon(Icons.assignment_ind),
            tooltip: 'bookingRequests'.tr(),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BookingManagementPage(),
                ),
              );
            },
          ),
          if (widget.navMenuButton != null) widget.navMenuButton!,
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.onAddEvent,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DefaultTextStyle(
              style:
                  Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
              child: SelectionContainer.disabled(
                child: sf.SfCalendar(
                  key: ValueKey(widget.currentView),
                  controller: widget.controller,
                  view: widget.currentView,
                  headerHeight:
                      0, // Disable default header to prevent crash/custom header
                  dataSource: InternalCalendarDataSource(widget.events),
                  onTap: (calendarTapDetails) {
                    if (calendarTapDetails.targetElement ==
                        sf.CalendarElement.header) {
                      _showCalendarViewSelection(context);
                    } else if (calendarTapDetails.targetElement ==
                        sf.CalendarElement.appointment) {
                      final appointment =
                          calendarTapDetails.appointments!.first;
                      if (appointment is CalendarEventModel) {
                        widget.onEventTap(appointment);
                      }
                    }
                  },
                  allowAppointmentResize: false,
                  allowDragAndDrop: false,
                  onViewChanged: (sf.ViewChangedDetails details) {
                    final visibleDates = details.visibleDates;
                    if (visibleDates.isNotEmpty) {
                      // Add buffer to ensure we cover Schedule/WorkWeek views and scrolling
                      // 14 days buffer ensures we don't miss events near boundaries
                      final startDate =
                          visibleDates.first.subtract(const Duration(days: 14));
                      final endDate = visibleDates.last
                          .add(const Duration(
                              days: 15)) // 1 day for full day + 14 days buffer
                          .subtract(const Duration(milliseconds: 1));
                      final midDate = visibleDates[visibleDates.length ~/ 2];

                      // Update local header date state
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _headerDate = DateFormat(
                              'MMMM yyyy',
                            ).format(midDate);
                          });
                        }
                      });

                      // Notify parent of range change
                      widget.onDateRangeChanged(startDate, endDate);
                    }
                  },
                  monthViewSettings: const sf.MonthViewSettings(
                    appointmentDisplayMode:
                        sf.MonthAppointmentDisplayMode.appointment,
                    showAgenda: true,
                  ),
                  timeSlotViewSettings: sf.TimeSlotViewSettings(
                    startHour: 7,
                    endHour: 22,
                    nonWorkingDays: widget.nonWorkingDays ??
                        <int>[DateTime.saturday, DateTime.sunday],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalendarViewSelection(BuildContext context) async {
    final selected = await showModalBottomSheet<sf.CalendarView>(
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
              ...<sf.CalendarView>[
                sf.CalendarView.day,
                sf.CalendarView.week,
                sf.CalendarView.workWeek,
                sf.CalendarView.month,
                sf.CalendarView.schedule,
              ].map(
                (view) => ListTile(
                  leading: Icon(
                    Icons.calendar_view_day, // Generic icon
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    _getViewLabel(view),
                    style: TextStyle(
                      fontWeight: widget.currentView == view
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: widget.currentView == view
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
    if (selected != null && selected != widget.currentView) {
      widget.onViewChanged(selected);
    }
  }
}

class InternalCalendarDataSource extends sf.CalendarDataSource {
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
    final event = appointments![index] as CalendarEventModel;
    return event.type == CalendarEventType.holiday ||
        event.type == CalendarEventType.vacation;
  }
}
{
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
    final event = appointments![index] as CalendarEventModel;
    return event.type == CalendarEventType.holiday ||
        event.type == CalendarEventType.vacation;
  }
}
