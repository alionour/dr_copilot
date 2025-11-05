import 'package:dr_copilot/src/core/code_pusher/shorebird_updater.dart';
import 'package:dr_copilot/src/core/localization/app_localization.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'src/core/app/notifiers/owner_notifier.dart';
import 'src/core/injections.dart';
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

  /// Initializes Firebase with platform-specific options, sets up dependency injections,
  /// retrieves shared preferences, and determines if dark mode is enabled by reading
  /// the 'isDarkMode' flag from persistent storage. If the flag is not set, defaults to false.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize dependency injections for the app
  // This is where you set up your service locator (GetIt) and register all the necessary services.
  await initInjections();
  await OwnerNotifier().loadOwnerIdAndClinicId();
  final secureStorage = FlutterSecureStorage();
  final isDarkModeStr = await secureStorage.read(key: 'isDarkMode');
  final isDarkMode = isDarkModeStr == null ? false : isDarkModeStr == 'true';

  // Shorebird: Automatically check for and apply updates on startup
  await ShorebirdCodePushHandler.checkAndApplyUpdate();

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
    AppLocalization(
      child: App(isDarkMode: isDarkMode),
    ),
  );
}
