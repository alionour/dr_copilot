import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// Custom error reporting service
class ErrorReportingService {
  /// The backend endpoint for error reporting.
  static const String _errorEndpoint =
      'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/errors';

  /// Cached app version to avoid repeated async calls.
  static String? _cachedAppVersion;

  /// Gets the app version, caching it for subsequent calls.
  static Future<String> _getAppVersion() async {
    if (_cachedAppVersion != null) {
      return _cachedAppVersion!;
    }
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _cachedAppVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
      return _cachedAppVersion!;
    } catch (e) {
      debugPrint('Failed to get package info: $e');
      return 'unknown';
    }
  }

  static Future<void> reportError(Object error, StackTrace? stack) async {
    try {
      final appVersion = await _getAppVersion();

      final errorData = {
        'error': error.toString(),
        'stackTrace': stack?.toString() ?? 'No stack trace available',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': kIsWeb
            ? 'web'
            : (Platform.isAndroid ||
                    Platform.isIOS ||
                    Platform.isMacOS ||
                    Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isFuchsia)
                ? Platform.operatingSystem
                : 'unknown',
        'platformVersion': kIsWeb
            ? 'web'
            : (Platform.isAndroid ||
                    Platform.isIOS ||
                    Platform.isMacOS ||
                    Platform.isWindows ||
                    Platform.isLinux ||
                    Platform.isFuchsia)
                ? Platform.operatingSystemVersion
                : 'unknown',
        'appVersion': appVersion,
      };

      await http
          .post(
        Uri.parse(_errorEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(errorData),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Error reporting timeout');
          return http.Response('Timeout', 408);
        },
      );
    } catch (e) {
      // Silent fail - don't crash because error reporting failed
      debugPrint('Failed to report error to backend: $e');
    }
  }
}
