import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Custom error reporting service
class ErrorReportingService {
  /// TODO: Replace with your actual backend error reporting endpoint
  static const String _errorEndpoint =
      'https://hg4orotvf0.execute-api.us-east-1.amazonaws.com/errors';

  static Future<void> reportError(Object error, StackTrace? stack) async {
    try {
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
        'appVersion': '1.0.1', // TODO: Get from package_info_plus
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
