import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:dr_copilot/src/core/code_pusher/shorebird_updater.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/core/app/notifiers/owner_notifier.dart';
import 'src/core/injections.dart';
import 'src/core/services/fcm_service.dart';
import 'firebase_options.dart';
import 'src/core/app/app.dart';

/// The entry point of the application.
///
/// This asynchronous `main` function initializes and starts the app.
/// Place any necessary setup or initialization logic here before running the app.
void main() async {
  // Initialize Flutter bindings and Firebase
  // This is necessary for plugins that require platform channels to be set up
  // before the app starts running.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set background message handler for FCM
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize dependency injections for the app
  // This is where you set up your service locator (GetIt) and register all the necessary services.
  await initInjections();
  await OwnerNotifier().loadOwnerIdAndClinicId();
  final secureStorage = FlutterSecureStorage();
  final isDarkModeStr = await secureStorage.read(key: 'isDarkMode');
  final isDarkMode = isDarkModeStr == null ? false : isDarkModeStr == 'true';

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
  ///
  /// - Ensures EasyLocalization is initialized before running the app.
  /// - Wraps the root [App] widget with [EasyLocalization] to provide localization support.
  /// - Specifies the list of supported locales via [supportedLocales].
  /// - Sets the path to the translation files with [path].
  /// - Defines a fallback locale and a starting locale, both set to English.
  /// - Passes [isDarkMode] to the [App] widget to configure the theme.
  // Initialize EasyLocalization with supported locales
  await localization.EasyLocalization.ensureInitialized();

  runApp(
    /// A widget that provides localization support for the application,
    /// enabling translation and locale management throughout the widget tree.
    AppLocalization(child: App(isDarkMode: isDarkMode)),
  );
}
