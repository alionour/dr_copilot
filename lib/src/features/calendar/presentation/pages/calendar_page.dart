import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/calendar/presentation/widgets/calendar_view.dart'; // Import dumb view
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/presentation/bloc/calendar_events_bloc.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:dr_copilot/src/features/calendar/presentation/pages/add_calendar_event_page.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;
import 'dart:ui';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  // Page manages the state variables that drive the view
  sf.CalendarView _currentView = sf.CalendarView.day;
  final sf.CalendarController _calendarController = sf.CalendarController();

  Widget _buildBeautifulLoadingIndicator() {
    return Positioned.fill(
      child: Stack(
        children: [
          // Backdrop blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withValues(alpha: 0.05), // Subtle dark tint
              ),
            ),
          ),
          // Loading Card
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 0,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      backgroundColor:
                          Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'loading'.tr(),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).hintColor,
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  void _deleteEvent(BuildContext context, CalendarEventModel event) {
    context.read<CalendarEventsBloc>().add(DeleteCalendarEvent(event.id));
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
              // Verify Delete
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('deleteEvent'.tr()),
                  content: Text('deleteReportConfirmation'.tr()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () {
                        _deleteEvent(context, event);
                        Navigator.of(context).pop(); // dialog
                        Navigator.of(context).pop(); // details
                      },
                      child: Text('delete'.tr(),
                          style: const TextStyle(color: Colors.red)),
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
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);

    return BlocProvider<CalendarEventsBloc>(
      create: (context) => sl<CalendarEventsBloc>(),
      child: BlocConsumer<CalendarEventsBloc, CalendarEventsState>(
        listener: (context, state) {
          if (state is CalendarEventsError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          List<CalendarEventModel> events = [];
          if (state is CalendarEventsLoaded) {
            events = state.events;
          }

          return BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              // Calculate non working days
              final allDays = [1, 2, 3, 4, 5, 6, 7];
              final workingDays = settingsState.workingDays;
              final nonWorkingDays =
                  allDays.where((d) => !workingDays.contains(d)).toList();

              return Stack(
                children: [
                  CalendarView(
                    events: events,
                    currentView: _currentView,
                    controller: _calendarController,
                    navMenuButton: navMenuButton,
                    nonWorkingDays: nonWorkingDays,
                    onViewChanged: (newView) {
                      setState(() {
                        _currentView = newView;
                        _calendarController.view = newView;
                      });
                    },
                    onDateRangeChanged: (start, end) {
                      context.read<CalendarEventsBloc>().add(
                            LoadEventsByDateRange(start, end),
                          );
                    },
                    onEventTap: (event) => _showEventDetails(context, event),
                    onAddEvent: () => _navigateToAddEvent(context),
                  ),
                  if (state is CalendarEventsLoading)
                    _buildBeautifulLoadingIndicator(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
