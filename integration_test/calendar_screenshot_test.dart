import 'package:dr_copilot/src/features/calendar/presentation/widgets/calendar_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart' as sf;

import '../test/screenshot/mock_data/calendar_event_mock_data.dart';
import '../test/screenshot/screenshot_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Capture Calendar View Screenshots', (WidgetTester tester) async {
    // 1. Setup harness and mock data
    final harness = ScreenshotTestHarness(tester);
    final mockEvents = CalendarEventMockData.generateMockEvents();

    // We render the "Dumb View" directly, bypassing Bloc entirely
    final calendarWidget = CalendarView(
      events: mockEvents,
      currentView: sf.CalendarView.day, // Start with Day view
      onViewChanged: (_) {},
      onEventTap: (_) {},
      onDateRangeChanged: (_, __) {},
      onAddEvent: () {},
    );

    // 2. define devices and categories
    final devices = {
      'desktop': {
        '1920x1080': const Size(1920, 1080),
        '1366x768': const Size(1366, 768),
      },
      'mobile': {
        'iPhone14': const Size(390, 844),
        'Pixel7': const Size(412, 915),
      },
      'tablet': {
        'iPadPro': const Size(1024, 1366),
        'GalaxyTabS7': const Size(1600, 2560),
      },
    };

    // 3. Get current date for directory targeting
    final now = DateTime.now();
    // Use simple date string
    final dateStr = now.toIso8601String().split('T')[0];

    // 4. Loop and capture
    for (final categoryEntry in devices.entries) {
      final categoryName = categoryEntry.key;
      final sizes = categoryEntry.value;

      for (final sizeEntry in sizes.entries) {
        final deviceName = sizeEntry.key;
        final size = sizeEntry.value;

        debugPrint('Capturing Calendar for $categoryName - $deviceName...');

        final filename =
            '$categoryName/calendar_screen/06_calendar_screen_${dateStr}_$deviceName.png';

        try {
          // Harness handles App wrapping and Localization
          await harness.captureWidgetScreenshot(
            widget: calendarWidget,
            filename: filename,
            windowSize: size,
          );
        } catch (e) {
          debugPrint('Error capturing $filename: $e');
        }
      }
    }
  });
}
