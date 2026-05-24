import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

// List of supported locales
const locales = [
  Locale('en', ''),
  Locale('ar', ''),
  Locale('es', ''),
  Locale('fr', ''),
  Locale('de', '')
];

/// A widget that wraps [child] with EasyLocalization configuration for the app.
class AppLocalization extends StatelessWidget {
  final Widget child;
  final Locale? startLocale;

  const AppLocalization({
    super.key,
    required this.child,
    this.startLocale,
  });

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: locales,
      path: 'assets/translations', // <-- translations directory
      fallbackLocale: const Locale('en'),
      startLocale: startLocale ?? const Locale('en'),
      child: child,
    );
  }
}

