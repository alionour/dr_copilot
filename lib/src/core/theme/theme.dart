import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

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
