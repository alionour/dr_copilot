import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

/// A [ChangeNotifier] that manages the application's theme mode (dark or light).
///
/// The [ThemeNotifier] holds the current theme state and provides methods to
/// toggle between dark and light modes. It uses [FlexColorScheme] to generate
/// the corresponding [ThemeData] based on the selected mode.
///
/// - [isDarkMode]: Returns `true` if dark mode is enabled, otherwise `false`.
/// - [currentTheme]: Returns the current [ThemeData] based on the theme mode.
/// - [toggleTheme]: Switches between dark and light modes and notifies listeners.
///
/// Example usage:
/// ```dart
/// final themeNotifier = ThemeNotifier(isDarkMode: false);
/// themeNotifier.toggleTheme();
/// ```
class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode;

  ThemeNotifier({required bool isDarkMode}) : _isDarkMode = isDarkMode;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme {
    return _isDarkMode
        ? FlexColorScheme.dark(scheme: FlexScheme.mandyRed).toTheme
        : FlexColorScheme.light(scheme: FlexScheme.mandyRed).toTheme;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
