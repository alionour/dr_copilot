import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

class PresentationService {
  /// Sends the current queue of patients to all active presentation windows.
  Future<void> updateQueue(List<PatientModel> patients) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.windows &&
            defaultTargetPlatform != TargetPlatform.linux &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return;
    }

    try {
      final windows = await WindowController.getAll();

      // Serialize only necessary data for the display
      final queueData = patients
          .take(5)
          .map((p) => {
                'id': p.id,
                'name': p.name,
                // Add other fields if needed for display
              })
          .toList();

      for (final window in windows) {
        // We could filter by specific arguments if we needed to differentiate windows
        // For now, we broadcast to all sub-windows we own.
        // Note: getAll() returns controllers for windows created by this app.

        // Check if this is likely our presentation window (optional, based on your architecture)
        // For now, safely try invoke.
        try {
          await window.invokeMethod('update_queue', queueData);
        } catch (e) {
          debugPrint('Failed to update window ${window.windowId}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating presentation queue: $e');
    }
  }

  /// Sends the current schedule to all active presentation windows.
  Future<void> updateSchedule(List<CalendarEventModel> events) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.windows &&
            defaultTargetPlatform != TargetPlatform.linux &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return;
    }

    try {
      final windows = await WindowController.getAll();

      // Serialize necessary data for the display (Time and Title/Patient Name)
      final scheduleData = events
          .map((e) => {
                'id': e.id,
                'title': e.title,
                'startTime': e.startDateTime.toDate().toIso8601String(),
                'endTime': e.endDateTime.toDate().toIso8601String(),
                'eventType': e.eventType,
              })
          .toList();

      for (final window in windows) {
        try {
          await window.invokeMethod('update_schedule', scheduleData);
        } catch (e) {
          debugPrint('Failed to update window ${window.windowId}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error updating presentation schedule: $e');
    }
  }
}
