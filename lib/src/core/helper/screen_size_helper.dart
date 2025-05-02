import 'package:flutter/material.dart';

enum ScreenSize { small, medium, large }

class ScreenSizeHelper {
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return ScreenSize.small;
    } else if (width < 1200) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }

  static bool isSmall(BuildContext context) =>
      getScreenSize(context) == ScreenSize.small;
  static bool isMedium(BuildContext context) =>
      getScreenSize(context) == ScreenSize.medium;
  static bool isLarge(BuildContext context) =>
      getScreenSize(context) == ScreenSize.large;
}
