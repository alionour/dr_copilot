import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

/// A [ChangeNotifier] that manages the application's theme mode (dark or light)
/// and color scheme.
///
/// The [ThemeNotifier] holds the current theme state and provides methods to
/// toggle between dark and light modes and change the color scheme. It uses
/// [FlexColorScheme] to generate the corresponding [ThemeData] based on the
/// selected mode and scheme.
///
/// - [isDarkMode]: Returns `true` if dark mode is enabled, otherwise `false`.
/// - [currentScheme]: Returns the current [FlexScheme] being used.
/// - [currentTheme]: Returns the current [ThemeData] based on the theme mode and scheme.
/// - [toggleTheme]: Switches between dark and light modes and notifies listeners.
/// - [updateScheme]: Changes the color scheme and notifies listeners.
///
/// Example usage:
/// ```dart
/// final themeNotifier = ThemeNotifier(
///   isDarkMode: false,
///   initialScheme: FlexScheme.blue,
/// );
/// themeNotifier.toggleTheme();
/// themeNotifier.updateScheme(FlexScheme.red);
/// ```
class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode;
  FlexScheme _currentScheme;
  String _fontSize;

  ThemeNotifier({
    required bool isDarkMode,
    FlexScheme initialScheme = FlexScheme.tealM3,
    String initialFontSize = 'medium',
  }) : _isDarkMode = isDarkMode,
       _currentScheme = initialScheme,
       _fontSize = initialFontSize;

  bool get isDarkMode => _isDarkMode;
  FlexScheme get currentScheme => _currentScheme;
  String get fontSize => _fontSize;

  double get textScaleFactor {
    switch (_fontSize) {
      case 'small':
        return 0.85;
      case 'large':
        return 1.15;
      case 'medium':
      default:
        return 1.0;
    }
  }

  ThemeData get currentTheme {
    return _isDarkMode
        ? FlexColorScheme.dark(scheme: _currentScheme).toTheme
        : FlexColorScheme.light(scheme: _currentScheme).toTheme;
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void updateScheme(FlexScheme scheme) {
    _currentScheme = scheme;
    notifyListeners();
  }

  void updateFontSize(String fontSize) {
    _fontSize = fontSize;
    notifyListeners();
  }
}

