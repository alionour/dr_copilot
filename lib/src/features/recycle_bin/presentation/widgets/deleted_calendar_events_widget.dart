import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';

import 'package:dr_copilot/src/features/recycle_bin/presentation/widgets/recycle_bin_item_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DeletedCalendarEventsWidget extends StatelessWidget {
  final List<CalendarEventModel> calendarEvents;

  const DeletedCalendarEventsWidget({
    super.key,
    required this.calendarEvents,
  });

  @override
  Widget build(BuildContext context) {
    if (calendarEvents.isEmpty) {
      return Center(
        child: Text(
          'noDeletedCalendarEvents'.tr(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: calendarEvents.length,
      itemBuilder: (context, index) {
        final event = calendarEvents[index];
        return CalendarEventItemTile(event: event);
      },
    );
  }
}
