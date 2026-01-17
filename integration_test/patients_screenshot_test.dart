import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patients_view.dart';
// Import the harness from the test directory
import '../test/screenshot/screenshot_test_harness.dart';
import '../test/screenshot/mock_data/patient_mock_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Enable runtime fetching - integration tests on Windows usually have network access or can load assets
    GoogleFonts.config.allowRuntimeFetching = true;

    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Capture Patients View Screenshot (Integration)',
      (WidgetTester tester) async {
    // Create the test harness
    final harness = ScreenshotTestHarness(tester);

    // Generate mock patient data
    final mockPatients = PatientMockData.generateMockPatients(count: 18);

    // Create the PatientsView widget with mock data
    final patientsView = PatientsView(
      patients: mockPatients,
      totalCount: mockPatients.length,
      isLoading: false,
      isLoadingMore: false,
      errorMessage: null,
      onSearch: null,
      onRefresh: null,
      onLoadMore: null,
      onAddPatient: null,
      onFilterDate: null,
      onFilterGender: null,
      onFilterAge: null,
      onFilterAddress: null,
    );

    // Define screen sizes by category
    final devices = {
      'desktop': {
        '1920x1080': const Size(1920, 1080),
        '1366x768': const Size(1366, 768),
      },
      'tablet': {
        'iPadPro': const Size(1024, 1366),
        'GalaxyTabS7': const Size(1600, 2560),
      },
      'mobile': {
        'iPhone14': const Size(390, 844),
        'Pixel7': const Size(412, 915),
      },
    };

    // Get current date for filenames
    final now = DateTime.now();
    // Simple YYYY-MM-DD format using ISO string, avoids intl initialization issues
    final dateStr = now.toIso8601String().split('T')[0];

    for (final categoryEntry in devices.entries) {
      final categoryName = categoryEntry.key;
      final sizes = categoryEntry.value;

      for (final sizeEntry in sizes.entries) {
        final deviceName = sizeEntry.key;
        final size = sizeEntry.value;

        debugPrint('Capturing screenshot for $categoryName - $deviceName...');

        try {
          // Format: category/patients_screen/05_patients_screen_YYYY-MM-DD_deviceName.png
          final filename =
              '$categoryName/patients_screen/05_patients_screen_${dateStr}_$deviceName.png';

          await harness.captureWidgetScreenshot(
            widget: patientsView,
            filename: filename,
            windowSize: size,
          );
        } catch (e) {
          debugPrint('Error capturing screenshot for $deviceName: $e');
        }
      }
    }
  });
}
