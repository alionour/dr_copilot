import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/core/injections.dart';
import 'firebase_options.dart';
import 'src/core/shorebird_updater.dart';
import 'src/core/app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await localization.EasyLocalization.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initInjections();
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // Shorebird: Automatically check for and apply updates on startup
  await ShorebirdCodePushHandler.checkAndApplyUpdate();

  runApp(
    localization.EasyLocalization(
      supportedLocales: const [
        Locale('en', ''),
        Locale('ar', ''),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', ''),
      startLocale: const Locale('en', ''),
      child: App(isDarkMode: isDarkMode),
    ),
  );
}
