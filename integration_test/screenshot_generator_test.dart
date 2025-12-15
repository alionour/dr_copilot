import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dr_copilot/main.dart' as entry_point;
import 'package:dr_copilot/src/core/router/routing_config.dart';
import 'package:dr_copilot/src/features/auth/presentation/pages/login_page.dart';
import 'package:dr_copilot/src/features/home/presentation/pages/home_page.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('generate_store_screenshots', (tester) async {
    // 1. Launch the app
    entry_point.main();
    await tester.pumpAndSettle();

    // 2. Handling Login
    // If we are on the login page, we need to wait for the user to sign in manually,
    // because Google Sign-In usually requires native UI interaction.
    if (find.byType(LoginPage).evaluate().isNotEmpty) {
      debugPrint('--------------------------------------------------');
      debugPrint('Please sign in manually on the device/emulator...');
      debugPrint('Waiting for Home Page...');
      debugPrint('--------------------------------------------------');

      // Take a screenshot of the login page before we sign in
      await binding.takeScreenshot('01_login_screen');

      // Poll until HomePage appears (max wait 5 minutes)
      // We check every 2 seconds
      bool isLoggedIn = false;
      for (int i = 0; i < 150; i++) {
        await Future.delayed(const Duration(seconds: 2));
        await tester.pumpAndSettle();

        if (find.byType(HomePage).evaluate().isNotEmpty) {
          isLoggedIn = true;
          break;
        }
      }

      if (!isLoggedIn) {
        fail('Timed out waiting for manual login.');
      }
    } else {
      // Already logged in
      debugPrint('Already logged in, skipping login wait.');
    }

    // Short pause to ensure Home is fully loaded
    await Future.delayed(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('02_home_screen');

    // 3. Navigate to other pages and screenshot
    final routes = {
      '03_calendar_screen': '/calendar',
      '04_chat_screen': '/chat',
      '05_patients_screen': '/patients',
      '06_financials_screen': '/financials',
      '07_settings_screen': '/settings',
      '08_about_screen': '/about',
    };

    for (var entry in routes.entries) {
      final name = entry.key;
      final route = entry.value;

      debugPrint('Navigating to $route...');

      // Use the global router to navigate
      // We run this inside runAsync to ensure safe execution if needed,
      // though typically direct call works if on same isolate.
      RoutingConfig.router.go(route);

      // Pump and settle to wait for navigation animation
      await tester.pumpAndSettle();

      // Additional small delay for data loading/rendering
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      await binding.takeScreenshot(name);
    }

    debugPrint('--------------------------------------------------');
    debugPrint('All screenshots taken!');
    debugPrint('--------------------------------------------------');
  });
}
