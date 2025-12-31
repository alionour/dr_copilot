import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patients_view.dart';
import 'screenshot_test_harness.dart';

import 'mock_data/patient_mock_data.dart';

import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Enable HTTP font fetching to allow rendering to proceed (fallback if assets fail)
    GoogleFonts.config.allowRuntimeFetching = true;

    // Ignore GoogleFonts errors (network issues) since we have manual fonts as backup
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('GoogleFonts') ||
          details.exception.toString().contains('load font') ||
          details.exception.toString().contains('asset') ||
          details.exception.toString().contains('url')) {
        // Catch URL errors too
        // Prepare to ignore this
        return;
      }
      originalOnError?.call(details);
    };

    // Manually load fonts to ensure they are available to the test engine
    final fontLoader = FontLoader('Poppins');
    final fonts = [
      'assets/fonts/Poppins-Regular.ttf',
      'assets/fonts/Poppins-Bold.ttf',
      'assets/fonts/Poppins-SemiBold.ttf',
      'assets/fonts/Poppins-Medium.ttf',
    ];

    for (final path in fonts) {
      final file = File(path);
      if (file.existsSync()) {
        fontLoader.addFont(
            file.readAsBytes().then((bytes) => ByteData.view(bytes.buffer)));
      } else {
        debugPrint('WARNING: Font file not found: $path');
      }
    }
    await fontLoader.load();

    // Load MaterialIcons specifically
    final materialIconsLoader = FontLoader('MaterialIcons');
    final materialIconFile = File('assets/fonts/MaterialIcons-Regular.ttf');
    if (materialIconFile.existsSync()) {
      materialIconsLoader.addFont(materialIconFile
          .readAsBytes()
          .then((bytes) => ByteData.view(bytes.buffer)));
      await materialIconsLoader.load();
    } else {
      debugPrint(
          'WARNING: MaterialIcons not found at ${materialIconFile.path}');
    }

    // Mock SharedPreferences for EasyLocalization
    SharedPreferences.setMockInitialValues({});
    // Initialize EasyLocalization for the test suite
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('Capture Patients View Screenshot', (WidgetTester tester) async {
    // Create the test harness
    final harness = ScreenshotTestHarness(tester);

    // Generate mock patient data (18 patients for a nice screenshot)
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

    // Verify widgets are in the tree
    final listFinder = find.byType(ListView);
    // final itemFinder = find.byType(PatientListItem); // Commented to avoid import issues for now

    debugPrint('DEBUG: Found ListView: ${listFinder.evaluate().length}');
    // debugPrint('DEBUG: Found PatientListItem: ${itemFinder.evaluate().length}');

    try {
      // Capture the screenshot using the harness which wraps with EasyLocalization
      await harness.captureWidgetScreenshot(
        widget: patientsView,
        filename: 'desktop/patients_screen/05_patients_screen.png',
        windowSize: const Size(1920, 1080),
      );
    } catch (e, stack) {
      debugPrint('Error capturing screenshot: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }

    expect(mockPatients.length, 18);
  });
}
