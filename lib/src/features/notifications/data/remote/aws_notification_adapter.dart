import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Interface for triggering notifications via AWS Backend
abstract class AWSNotificationService {
  Future<void> sendNotification({
    required List<String> targetUserIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  });
}

/// Implementation of AWS Notification Service
///
/// This adapter is designed to communicate with your AWS backend to trigger
/// push notifications. You can implement the actual API call here.
class AWSNotificationAdapter implements AWSNotificationService {
  final String _baseUrl;
  final http.Client _client;

  AWSNotificationAdapter({String? baseUrl, http.Client? client})
    : _baseUrl = baseUrl ?? 'YOUR_AWS_API_ENDPOINT',
      _client = client ?? http.Client();

  @override
import 'dart:convert'; // Added for jsonEncode
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Interface for triggering notifications via AWS Backend
abstract class AWSNotificationService {
  Future<void> sendNotification({
    required List<String> targetUserIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  });
}

/// Implementation of AWS Notification Service
///
/// This adapter is designed to communicate with your AWS backend to trigger
/// push notifications. You can implement the actual API call here.
class AWSNotificationAdapter implements AWSNotificationService {
  final String _baseUrl;
  final http.Client _client;

  AWSNotificationAdapter({String? baseUrl, http.Client? client})
    : _baseUrl = baseUrl ?? 'YOUR_AWS_API_ENDPOINT',
      _client = client ?? http.Client();

  @override
  Future<void> sendNotification({
    required List<String> targetUserIds,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    const String endpoint = '$_baseUrl/notifications';
    debugPrint('[AWS] Sending notification to ${targetUserIds.length} users via $endpoint');
    
    // Iterate over targets because the current backend endpoint seems to accept single userId
    // according to FLUTTER_INTEGRATION.md: { "userId": "...", "title": "...", "message": "..." }
    // If the backend supports bulk, we should update this. For now, loop calls.
    
    for (final userId in targetUserIds) {
      try {
        final response = await _client.post(
          Uri.parse(endpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userId': userId,
            'title': title,
            'message': message,
            // 'data': data, // Backend doc doesn't explicitly mention extra data field yet, checking logic...
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('[AWS] Notification sent to $userId: ${response.body}');
        } else {
          debugPrint('[AWS] Failed to send to $userId: ${response.statusCode} ${response.body}');
        }
      } catch (e) {
        debugPrint('[AWS] Error triggering notification for $userId: $e');
      }
    }
  }
}
