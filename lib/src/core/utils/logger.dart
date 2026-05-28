import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Log levels for the application logger
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Custom logger for the Dr. AI application
///
/// Provides different log levels and proper formatting for development and production
class AppLogger {
  static const String _appName = 'DrAI';

  /// Log a debug message (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }

  /// Log an info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Log a warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Log an error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Log a critical error message
  static void critical(String message,
      [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }

  /// Internal logging method
  static void _log(LogLevel level, String message,
      [Object? error, StackTrace? stackTrace]) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(8);
    final logMessage = '[$timestamp] [$levelStr] $_appName: $message';

    // Use developer.log for better integration with Flutter DevTools
    developer.log(
      message,
      time: DateTime.now(),
      level: _getLevelValue(level),
      name: _appName,
      error: error,
      stackTrace: stackTrace,
    );

    // Also print to console in debug mode for immediate visibility
    if (kDebugMode) {
      // ignore: avoid_print
      print(logMessage);
      if (error != null) {
        // ignore: avoid_print
        print('Error: $error');
      }
      if (stackTrace != null) {
        // ignore: avoid_print
        print('Stack trace: $stackTrace');
      }
    }
  }

  /// Convert log level to numeric value for developer.log
  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.critical:
        return 1200;
    }
  }

  /// Log test execution steps (for test runner)
  static void testStep(String step) {
    if (kDebugMode) {
      final message = '🧪 $step';
      developer.log(
        step,
        time: DateTime.now(),
        level: 800,
        name: '$_appName-Test',
      );
      // ignore: avoid_print
      print(message);
    }
  }

  /// Log test results (for test runner)
  static void testResult(String result, {bool success = true}) {
    if (kDebugMode) {
      final emoji = success ? '✅' : '❌';
      final message = '$emoji $result';
      developer.log(
        result,
        time: DateTime.now(),
        level: success ? 800 : 1000,
        name: '$_appName-Test',
      );
      // ignore: avoid_print
      print(message);
    }
  }

  /// Log performance metrics
  static void performance(String operation, Duration duration) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    developer.log(
      message,
      time: DateTime.now(),
      level: 800,
      name: '$_appName-Performance',
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('⚡ $message');
    }
  }

  /// Log network requests
  static void network(String method, String url,
      {int? statusCode, Duration? duration}) {
    final durationStr =
        duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    final statusStr = statusCode != null ? ' [$statusCode]' : '';
    final message = 'Network: $method $url$statusStr$durationStr';

    developer.log(
      message,
      time: DateTime.now(),
      level: 800,
      name: '$_appName-Network',
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('🌐 $message');
    }
  }

  /// Log user actions for analytics
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    final paramStr = parameters != null ? ' with $parameters' : '';
    final message = 'User Action: $action$paramStr';

    developer.log(
      message,
      time: DateTime.now(),
      level: 800,
      name: '$_appName-UserAction',
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('👤 $message');
    }
  }

  /// Log Firebase operations
  static void firebase(String operation,
      {String? collection, String? documentId}) {
    final collectionStr = collection != null ? ' in $collection' : '';
    final docStr = documentId != null ? ' (doc: $documentId)' : '';
    final message = 'Firebase: $operation$collectionStr$docStr';

    developer.log(
      message,
      time: DateTime.now(),
      level: 800,
      name: '$_appName-Firebase',
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('🔥 $message');
    }
  }

  /// Log bloc state changes
  static void bloc(String blocName, String event, String state) {
    final message = 'Bloc: $blocName -> $event -> $state';

    developer.log(
      message,
      time: DateTime.now(),
      level: 500,
      name: '$_appName-Bloc',
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('🔄 $message');
    }
  }
}

