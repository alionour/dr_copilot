import 'dart:async';
import 'package:dr_copilot/src/core/services/error_reporting_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/code_pusher/shorebird_updater.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/core/localization/app_localization.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dr_copilot/src/core/services/remote_config_service.dart';
import 'src/core/injections.dart';
import 'src/core/services/fcm_service.dart';
import 'firebase_options.dart';
import 'src/core/app/app.dart';

// ... imports
import 'dart:convert';
import 'package:dr_copilot/src/features/presentation/presentation_app.dart';

/// The entry point of the application.
///
/// This asynchronous `main` function initializes and starts the app.
/// Place any necessary setup or initialization logic here before running the app.
void main(List<String> args) async {
  if (args.firstOrNull == 'multi_window') {
    WidgetsFlutterBinding.ensureInitialized();
    await localization.EasyLocalization.ensureInitialized();

    final windowId = args[1];
    final argument = args[2].isEmpty
        ? const <String, dynamic>{}
        : jsonDecode(args[2]) as Map<String, dynamic>;
    final localeCode = argument['localeCode'] as String?;
    runApp(
      AppLocalization(
        startLocale: localeCode == null ? null : Locale(localeCode),
        child: PresentationApp(windowId: windowId, arguments: argument),
      ),
    );
    return;
  }

  runZonedGuarded<Future<void>>(() async {
    // ... existing initialization logic
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.black,
      ),
    );

    // ... rest of main function remains the same
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // Fix for "Platform channel messages must be sent on the platform thread" error on Windows
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false,
      );
    }

    // Set background message handler for FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialize dependency injections for the app
    // This is where you set up your service locator (GetIt) and register all the necessary services.
    await initInjections();

    // Initialize Remote Config (Feature Flags)
    try {
      await sl<RemoteConfigService>().initialize();
    } catch (e) {
      debugPrint('Warning: Remote Config initialization failed: $e');
    }

    // await OwnerNotifier().loadOwnerIdAndClinicId(); // Removed: Handled by App BlocListener
    final secureStorage = FlutterSecureStorage();

    final isDarkModeStr = await secureStorage.read(key: 'isDarkMode');
    final isDarkMode = isDarkModeStr == null ? false : isDarkModeStr == 'true';

    // Load saved color scheme
    final schemeStr = await secureStorage.read(key: 'themeScheme');
    FlexScheme initialScheme = FlexScheme.tealM3; // Default
    if (schemeStr != null) {
      try {
        initialScheme = FlexScheme.values.firstWhere(
          (e) => e.name == schemeStr,
          orElse: () => FlexScheme.tealM3,
        );
      } catch (e) {
        debugPrint('Error parsing theme scheme: $e');
      }
    }

    // Load saved font size
    final fontSize = await secureStorage.read(key: 'fontSize') ?? 'medium';

    // Shorebird: Automatically check for and apply updates on startup
    await ShorebirdCodePushHandler.checkAndApplyUpdate();

    // MIGRATION: Convert Quill Delta to HTML
    try {
      debugPrint('Running migration...');
      await ClinicalReportService().migrateAllReportsToHtml();
      debugPrint('Migration finished.');
    } catch (e) {
      debugPrint('Migration error: $e');
    }

    /// Initializes the EasyLocalization package to support multiple locales in the app.
    // Initialize EasyLocalization with supported locales
    await localization.EasyLocalization.ensureInitialized();

    // Set up global error handling for Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _reportError(details.exception, details.stack);
    };

    runApp(
      /// A widget that provides localization support for the application,
      /// enabling translation and locale management throughout the widget tree.
      AppLocalization(
        child: App(
          isDarkMode: isDarkMode,
          initialScheme: initialScheme,
          initialFontSize: fontSize,
        ),
      ),
    );
  }, (error, stack) {
    _reportError(error, stack);
  });
}

void _reportError(Object error, StackTrace? stack) {
  debugPrint('Caught error: $error');
  if (stack != null) {
    debugPrint('Stack trace:\n$stack');
  }

  // Report all errors to custom backend
  ErrorReportingService.reportError(error, stack);
}

// ErrorReportingService moved to lib/src/core/services/error_reporting_service.dart
