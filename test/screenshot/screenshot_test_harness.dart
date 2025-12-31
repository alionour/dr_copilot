// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/features/patients/presentation/widgets/patient_list_item.dart';
import 'package:dr_copilot/src/core/presentation/widgets/empty_state_widget.dart';
// ignore: depend_on_referenced_packages
import 'package:path/path.dart' as path;

/// Test harness for capturing screenshots of widgets in isolation.
/// Provides utilities for wrapping widgets with MaterialApp, theme, and localization.
class ScreenshotTestHarness {
  /// The test widget binding for screenshot capture.
  final WidgetTester tester;

  ScreenshotTestHarness(this.tester);

  /// Captures a screenshot of the given widget and saves it to the screenshots directory.
  ///
  /// [widget] - The widget to capture
  /// [filename] - The filename for the screenshot (e.g., '05_patients_screen.png')
  /// [windowSize] - Optional custom window size. Defaults to 1920x1080.
  final GlobalKey _containerKey = GlobalKey();

  Future<void> captureWidgetScreenshot({
    required Widget widget,
    required String filename,
    Size windowSize = const Size(1920, 1080),
  }) async {
    // Set the window size for consistent screenshots using modern API
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;

    // Reset view on disposal
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Build the widget wrapped with necessary providers and the RepaintBoundary
    try {
      await tester.pumpWidget(
        _wrapWithApp(widget),
      );
    } catch (e) {
      if (!e.toString().contains('GoogleFonts') &&
          !e.toString().contains('load font')) {
        rethrow;
      }
      // If font error, we might still be okay, but verify state
      print('DEBUG: Suppressed error in pumpWidget: $e');
    }

    // Wait for all animations and frames to complete
    try {
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } catch (e) {
      if (!e.toString().contains('GoogleFonts') &&
          !e.toString().contains('load font')) {
        rethrow;
      }
      // Use pump() to ensure we advance if settle failed
      await tester.pump();
    }

    // Additional pump to ensure everything is rendered
    await tester.pump();

    // Debug: Check if expected widgets are present
    final patientItems = find.byType(PatientListItem);
    final listView = find.byType(ListView);
    print(
        'DEBUG: Found ${patientItems.evaluate().length} PatientListItem widgets');
    print('DEBUG: Found ${listView.evaluate().length} ListView widgets');
    if (patientItems.evaluate().isEmpty) {
      print('DEBUG: No patient items found! Checking for EmptyStateWidget...');
      final emptyState = find.byType(EmptyStateWidget);
      print(
          'DEBUG: Found EmptyStateWidget: ${emptyState.evaluate().isNotEmpty}');
    }

    Uint8List? screenshot;

    await tester.runAsync(() async {
      try {
        // Find the render object by key
        final renderObject = _containerKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;

        if (renderObject == null) {
          throw Exception('RenderRepaintBoundary not found for the key');
        }

        final image = await renderObject.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        screenshot = byteData!.buffer.asUint8List();
      } catch (e) {
        rethrow;
      }
    });

    if (screenshot == null) {
      throw Exception('Failed to capture screenshot');
    }

    // Save to screenshots directory at project root
    await _saveScreenshot(screenshot!, filename);
  }

  /// Captures a screenshot without wrapping the widget (assumes it's already in a MaterialApp context).
  /// Note: This might not work if the RepaintBoundary isn't injected.
  /// For direct capture, we might need to rely on finding the widget by type or key passed in.
  Future<void> captureWidgetScreenshotDirect({
    required Widget widget,
    required String filename,
    Size windowSize = const Size(1920, 1080),
  }) async {
    // Re-use the main logic but wrap locally if needed, or assume widget has boundary
    // For simplicity, let's just delegate to the main one which wraps it,
    // or if we really need direct, we need to wrap 'widget' in RepaintBoundary here too.

    // Let's implement a safe wrap for direct capture
    tester.view.physicalSize = windowSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(RepaintBoundary(
      key: _containerKey,
      child: widget,
    ));

    await tester.pumpAndSettle();

    // Reuse extraction logic... (duplicated for now for safety)
    Uint8List? screenshot;
    await tester.runAsync(() async {
      final renderObject = _containerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      final image = await renderObject!.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      screenshot = byteData!.buffer.asUint8List();
    });

    await _saveScreenshot(screenshot!, filename);
  }

  /// Wraps the widget with MaterialApp, theme, and localization.
  Widget _wrapWithApp(Widget child) {
    // Initialize EasyLocalization for test environment with mock loader
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const MockAssetLoader(),
      fallbackLocale: const Locale('en'),
      child: Builder(
        builder: (context) {
          return MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: _createTheme(),
            home: RepaintBoundary(
              key: _containerKey,
              child: child,
            ),
          );
        },
      ),
    );
  }

  /// Creates a theme for the screenshot.
  ThemeData _createTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
    );
  }

  /// Saves the screenshot to the screenshots directory.
  Future<void> _saveScreenshot(Uint8List screenshot, String filename) async {
    // Get the project root directory
    final projectRoot = Directory.current.path;

    // Create the full path to the file
    // If filename implies subdirectories (e.g. '2024-12-22/mobile/file.png'), join will handle it
    final fullPath = path.join(projectRoot, 'screenshots', filename);

    // Ensure the parent directory exists
    final file = File(fullPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }

    // Save the screenshot synchronously to ensure it's written even if the test crashes
    file.writeAsBytesSync(screenshot, flush: true);

    print('Screenshot saved to: ${file.path}');
  }
}

/// Mock asset loader for EasyLocalization to avoid file IO dependencies
class MockAssetLoader extends AssetLoader {
  const MockAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return {
      'calendarTitle': 'Calendar',
      'searchPatients': 'Search Patients',
      'loaded': 'loaded',
      'stored': 'stored',
      'today': 'Today',
      'yesterday': 'Yesterday',
      'noPatientsMatchsMatch': 'No patients match',
      'noResultsFound': 'No results found',
      'addPatient': 'Add Patient',
      'age': 'Age',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'copilotChat': 'Copilot Chat',
      'messageDrCopilot': 'Message Dr. Copilot...',
      'calendarView.selectView': 'Select View',
    };
  }
}
