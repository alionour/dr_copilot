import 'package:dr_copilot/src/features/financials/presentation/widgets/dashboard_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/screenshot/mock_data/dashboard_mock_data.dart';
import '../test/screenshot/screenshot_test_harness.dart';
export 'package:dr_copilot/src/features/financials/presentation/widgets/dashboard_view.dart'
    show RecentTransaction;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = true;
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Generate Dashboard Screenshots', (WidgetTester tester) async {
    final harness = ScreenshotTestHarness(tester);
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T')[0];

    final dashboardWidget = DashboardView(
      userName: DashboardMockData.userName,
      sessionsThisMonth: DashboardMockData.sessionsThisMonth,
      sessionsThisYear: DashboardMockData.sessionsThisYear,
      evaluationsThisMonth: DashboardMockData.evaluationsThisMonth,
      evaluationsThisYear: DashboardMockData.evaluationsThisYear,
      totalRevenueThisMonth: DashboardMockData.totalRevenueThisMonth,
      totalExpensesThisMonth: DashboardMockData.totalExpensesThisMonth,
      recentTransactions: DashboardMockData.generateRecentTransactions(),
    );

    final devices = {
      'desktop': {
        '1920x1080': const Size(1920, 1080),
        '1366x768': const Size(1366, 768),
      },
      'mobile': {
        'iPhone14': const Size(390, 844),
      },
      'tablet': {
        'iPadPro': const Size(1024, 1366),
      },
    };

    for (final categoryEntry in devices.entries) {
      final categoryName = categoryEntry.key;
      final sizes = categoryEntry.value;

      for (final sizeEntry in sizes.entries) {
        final deviceName = sizeEntry.key;
        final size = sizeEntry.value;

        debugPrint('Capturing Dashboard for $categoryName - $deviceName...');
        final filename =
            '$categoryName/dashboard_screen/02_dashboard_screen_${dateStr}_$deviceName.png';

        try {
          await harness.captureWidgetScreenshot(
            widget: dashboardWidget,
            filename: filename,
            windowSize: size,
          );
        } catch (e) {
          debugPrint('Error capturing $filename: $e');
        }
      }
    }

    debugPrint('=== Dashboard Screenshots Generated Successfully ===');
  });
}
