import 'package:dr_copilot/src/core/app/providers/bloc_providers.dart';
import 'package:provider/provider.dart';
import '../notifiers/theme_notifier.dart';
import '../notifiers/locale_notifier.dart';
import '../notifiers/owner_notifier.dart';
import '../../services/connectivity_service.dart';

/// A list of global providers used throughout the application.
///
/// - `ThemeNotifier`: Manages the application's theme state (light/dark mode).
/// - `LocaleNotifier`: Handles the application's locale and language settings.
///
/// These providers are intended to be registered at the root of the widget tree
/// to ensure their state is accessible across the entire app.
final appProviders = [
  /// Provides an instance of [ThemeNotifier] to the widget tree, initializing it with `isDarkMode` set to `false`.
  ///
  /// This allows descendant widgets to listen for theme changes and update accordingly.
  ///
  /// Example usage:
  /// ```dart
  /// ChangeNotifierProvider(
  ///   create: (context) => ThemeNotifier(isDarkMode: false),
  ///   child: MyApp(),
  /// )
  /// ```
  ChangeNotifierProvider(create: (context) => ThemeNotifier(isDarkMode: false)),

  /// Provides an instance of [LocaleNotifier] to the widget tree using [ChangeNotifierProvider].
  ///
  /// This allows descendant widgets to listen for locale changes and rebuild accordingly.
  /// The [LocaleNotifier] manages the application's locale state.
  ChangeNotifierProvider(create: (context) => LocaleNotifier()),

  /// Provides an instance of [OwnerNotifier] to the widget tree using [ChangeNotifierProvider].
  ///
  /// This allows descendant widgets to access the global ownerId for Firestore queries.
  ChangeNotifierProvider(create: (context) => OwnerNotifier()),

  /// Provides an instance of [ConnectivityService] to the widget tree using [ChangeNotifierProvider].
  ///
  /// This allows descendant widgets to listen for connectivity changes.
  ChangeNotifierProvider(create: (context) => ConnectivityService()),

  ...appBlocProviders,
];

