import 'package:flutter/material.dart';
import 'package:dr_copilot/src/core/helper/screen_size_helper.dart';

/// A widget that builds different layouts based on the screen size.
class ResponsiveLayout extends StatelessWidget {
  /// The widget to display on mobile screens.
  final Widget mobile;

  /// The widget to display on tablet screens.
  /// If not provided, [mobile] will be used.
  final Widget? tablet;

  /// The widget to display on desktop screens.
  /// If not provided, [tablet] (if available) or [mobile] will be used.
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = ScreenSizeHelper.getScreenSize(context);

    if (screenSize == ScreenSize.large) {
      return desktop ?? tablet ?? mobile;
    } else if (screenSize == ScreenSize.medium) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}
