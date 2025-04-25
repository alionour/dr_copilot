import 'package:flutter/material.dart';

/// A [ChangeNotifier] that manages the application's current [Locale].
///
/// This class provides a way to get and set the current locale, notifying
/// listeners whenever the locale changes. Useful for implementing dynamic
/// localization in a Flutter app.
///
/// Example usage:
/// ```dart
/// final localeNotifier = LocaleNotifier();
/// localeNotifier.setLocale(const Locale('ar'));
/// ```
class LocaleNotifier extends ChangeNotifier {
  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  void setLocale(Locale locale) {
    _currentLocale = locale;
    notifyListeners();
  }
}
