import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/presentation/presentation/widgets/presentation_screen.dart';

import 'package:flex_color_scheme/flex_color_scheme.dart';

class PresentationApp extends StatelessWidget {
  final String windowId;
  final Map<String, dynamic>? arguments;

  const PresentationApp({
    super.key,
    required this.windowId,
    this.arguments,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure localization is initialized for this window/isolate if needed
    // For now, we wrap in MaterialApp with basic config
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dr. Copilot - Presentation',
      theme: FlexThemeData.light(scheme: FlexScheme.tealM3),
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.tealM3),
      themeMode: ThemeMode.system, // Or pass from arguments
      home: PresentationScreen(windowId: windowId, arguments: arguments),
    );
  }
}
