import 'package:dr_copilot/src/core/app/providers/providers.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../router/routing_config.dart';
import 'notifiers/locale_notifier.dart';
import 'notifiers/theme_notifier.dart';
import 'providers/bloc_providers.dart';

/// The [App] widget is the root of the application, responsible for setting up
/// global providers and configuring the main [MaterialApp.router].
///
/// It initializes theme and locale management using [ThemeNotifier] and [LocaleNotifier]
/// via [ChangeNotifierProvider], and injects BLoC providers through [MultiBlocProvider].
///
/// The widget dynamically applies the theme and text styles based on the current
/// locale (e.g., using Tajawal for Arabic and Roboto for other languages), and
/// configures the application's routing, localization, and scroll bar appearance.
///
/// The [isDarkMode] parameter determines the initial theme mode of the app.
///
/// Example usage:
/// ```dart
/// App(isDarkMode: true)
/// ```
class App extends StatelessWidget {
  /// Indicates whether the application is running in dark mode.
  ///
  /// If `true`, the app will use a dark color scheme; otherwise, it will use a light color scheme.
  final bool isDarkMode;

  /// Creates an instance of the [App] widget.
  ///
  /// The [isDarkMode] parameter is required to determine the initial theme mode.
  ///
  /// Example:
  /// ```dart
  /// const App(isDarkMode: true);
  /// ```
  const App({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    /// Returns a [MultiProvider] widget that supplies multiple providers to the widget tree.
    ///
    /// This is typically used to inject dependencies or state management objects
    /// into the widget subtree, making them accessible to descendant widgets.
    ///
    /// Example usage:
    /// ```dart
    /// return MultiProvider(
    ///   providers: [
    ///     Provider<SomeService>(create: (_) => SomeService()),
    ///     ChangeNotifierProvider(create: (_) => SomeNotifier()),
    ///   ],
    ///   child: MyApp(),
    /// );
    /// ```
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => ThemeNotifier(isDarkMode: isDarkMode)),
        ChangeNotifierProvider(create: (_) => LocaleNotifier()),
      ],

      /// Wraps the widget tree with a [Consumer] that listens to changes in [ThemeNotifier].
      /// This allows the UI to reactively update when the app's theme changes.
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, child) {
          /// Returns a [Consumer] widget that listens to changes in the [LocaleNotifier].
          ///
          /// This allows the widget subtree to rebuild whenever the locale changes,
          /// enabling dynamic localization updates throughout the app.
          return Consumer<LocaleNotifier>(
            builder: (context, localeNotifier, child) {
              /// Returns a [MultiBlocProvider] widget that allows multiple BLoC providers
              /// to be supplied to the widget subtree. This is typically used to provide
              /// multiple BLoC or Cubit instances to descendant widgets in the widget tree,
              /// enabling state management and event handling across the application.
              return MultiBlocProvider(
                /// Configures the main application widget with the following features:
                ///
                /// - Provides application-wide BLoC providers via `appBlocProviders`.
                /// - Uses `MaterialApp.router` for declarative routing with `RoutingConfig.router`.
                /// - Sets the application title to 'Dr Copilot'.
                /// - Applies a dynamic theme from `themeNotifier.currentTheme`, customizing the scrollbar
                ///   appearance and selecting a text theme based on the current locale (Tajawal for Arabic, Roboto otherwise).
                /// - Disables the debug banner.
                /// - Sets the locale, supported locales, and localization delegates from the current context.
                /// - Uses a custom `builder` to print the current locale for debugging and wraps the child widget in a `Stack`.
                providers: appProviders,
                child: MaterialApp.router(
                  /// Sets the application's router configuration using the predefined
                  /// `router` from the `RoutingConfig` class. This determines how
                  /// navigation and route management are handled within the app.
                  routerConfig: RoutingConfig.router,

                  /// The title of the application displayed in the app bar or window.
                  ///
                  /// In this case, it is set to 'Dr Copilot'.
                  title: 'Dr Copilot',

                  /// Applies the current theme from the [themeNotifier] and allows for further customization
                  /// by creating a copy of the theme with additional modifications.
                  ///
                  /// This is typically used to dynamically update the app's theme based on user preferences
                  /// or system settings.
                  theme: themeNotifier.currentTheme.copyWith(
                    /// Defines the visual properties of scrollbars in the application, such as thickness, radius, and color.
                    /// Customize this theme to match the overall look and feel of your app's scrollable widgets.
                    scrollbarTheme: ScrollbarThemeData(
                      thumbVisibility: WidgetStateProperty.all(true),
                      thickness: WidgetStateProperty.all(12.0),
                    ),

                    /// Sets the [textTheme] based on the current locale's language code.
                    /// If the language code is 'ar' (Arabic), applies specific text theme settings
                    /// suitable for Arabic localization.
                    textTheme: context.locale.languageCode == 'ar'
                        ? GoogleFonts.tajawalTextTheme()
                        : GoogleFonts.robotoTextTheme(),
                  ),
                  debugShowCheckedModeBanner: false,

                  /// Specifies the current locale for the application, typically used to determine
                  /// the language and regional settings for localization. The value is obtained
                  /// from the current build context using `context.locale`.
                  locale: context.locale,

                  /// A list of locales that the application supports, typically used for internationalization.
                  /// This value is retrieved from the current [BuildContext] using an extension or helper
                  /// that provides the supported locales for the app.
                  ///
                  /// Example usage:
                  /// ```dart
                  /// supportedLocales: context.supportedLocales,
                  /// ```
                  supportedLocales: context.supportedLocales,

                  /// A list of localization delegates used by the application to provide
                  /// localized resources and translations. This is typically passed to
                  /// the `localizationsDelegates` parameter of a `MaterialApp` or `CupertinoApp`
                  /// to enable internationalization support based on the current context.
                  localizationsDelegates: context.localizationDelegates,

                  /// A builder function that takes the current [BuildContext] and an optional [child] widget,
                  /// and returns a widget to be rendered. This is typically used to rebuild parts of the widget
                  /// tree in response to changes in the application state or inherited widgets.
                  builder: (context, child) {
                    debugPrint(
                        '2 Current Locale: \\${Localizations.localeOf(context).languageCode}');
                    return Stack(
                      children: [
                        child!,
                      ],
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
