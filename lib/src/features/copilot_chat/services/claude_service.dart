import 'dart:convert';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';

class ClaudeService implements AIService {
  final FlutterSecureStorage _secureStorage;

  ClaudeService(this._secureStorage);

  Future<String?> _safeRead(String key) async {
    int retries = 0;
    while (true) {
      try {
        return await _secureStorage.read(key: key);
      } catch (e) {
        if (retries >= 3) rethrow;
        retries++;
        await Future.delayed(Duration(milliseconds: 200 * retries));
      }
    }
  }

  Future<List<String>> _getApiKeys() async {
    List<String> keys = [];

    // 1. Try new list format
    final jsonStr = await _safeRead('claude_api_keys');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) keys = List<String>.from(decoded);
      } catch (e) {
        debugPrint('Error decoding claude keys: $e');
      }
    }

    // 2. Try single key
    if (keys.isEmpty) {
      String? key = await _safeRead('claude_api_key');
      if (key != null && key.isNotEmpty) keys.add(key);
    }

    // 3. Try env/helper key
    if (keys.isEmpty) {
      keys.add(ApiKeyHelper.claudeKey);
    }

    return keys.where((k) => k.isNotEmpty).toSet().toList();
  }

  @override
  Future<String> generateResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    return getClaudeResponse(query, messageHistory: messageHistory);
  }

  @override
  Future<String> generateResponseWithImage(
    String query,
    Uint8List imageBytes, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final keys = await _getApiKeys();
    if (keys.isEmpty) {
      throw Exception(
        'Claude API Key not found. Please configure it in settings.',
      );
    }

    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final messages = <Map<String, dynamic>>[];
    messages.add({
      'role': 'user',
      'content': [
        {
          'type': 'image',
          'source': {
            'type': 'base64',
            'media_type': 'image/jpeg',
            'data': base64Encode(imageBytes),
          },
        },
        {'type': 'text', 'text': query},
      ],
    });

    final body = jsonEncode({
      'model': 'claude-3-5-sonnet-20241022',
      'max_tokens': 1024,
      'system':
          'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals.',
      'messages': messages,
    });

    for (int i = 0; i < keys.length; i++) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': keys[i],
            'anthropic-version': '2023-06-01',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['content'][0]['text'];
        } else {
          throw Exception(
            'Failed to get response from Claude: ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('Claude key $i failed (Vision): $e');
        if (i == keys.length - 1) rethrow;
      }
    }
    throw Exception('All Claude keys failed.');
  }

  Future<String> getClaudeResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final keys = await _getApiKeys();
    if (keys.isEmpty) {
      throw Exception(
        'Claude API Key not found. Please configure it in settings.',
      );
    }

    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    // Build messages array with history
    final List<Map<String, dynamic>> messages = [];

    // Add message history
    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';

      if (text.isNotEmpty) {
        messages.add({'role': isUser ? 'user' : 'assistant', 'content': text});
      }
    }

    // Add current query
    messages.add({'role': 'user', 'content': query});

    final body = jsonEncode({
      'model': 'claude-3-5-sonnet-20241022',
      'max_tokens': 1024,
      'system':
          'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals.',
      'messages': messages,
    });

    for (int i = 0; i < keys.length; i++) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': keys[i],
            'anthropic-version': '2023-06-01',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['content'][0]['text'];
        } else {
          throw Exception(
            'Failed to get response from Claude: ${response.body}',
          );
        }
      } catch (e) {
        debugPrint('Claude key $i failed: $e');
        if (i == keys.length - 1) rethrow;
      }
    }
    throw Exception('All Claude keys failed.');
  }

  Future<String> getClaudeResponseFromBytes(Uint8List fileBytes) async {
    // This method seems deprecated or using incorrect endpoint, but keeping for compatibility if needed.
    // Refactoring to use multi-key logic just in case.
    final keys = await _getApiKeys();
    if (keys.isEmpty) {
      throw Exception(
        'Claude API Key not found. Please configure it in settings.',
      );
    }

    final url = Uri.parse('https://api.claude.com/v1/query');
    final body = jsonEncode({'query': base64Encode(fileBytes)});

    for (int i = 0; i < keys.length; i++) {
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${keys[i]}',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['response'];
        } else {
          // throw Exception('Failed to get response from Claude');
          // try next key
        }
      } catch (e) {
        if (i == keys.length - 1) rethrow;
      }
    }
    throw Exception('Failed to get response from Claude');
  }
}
