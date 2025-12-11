import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';

class GPTService implements AIService {
  final FlutterSecureStorage _secureStorage;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  GPTService(
    this._secureStorage, {
    required QuotaService quotaService,
    required SubscriptionService subscriptionService,
  }) : _quotaService = quotaService,
       _subscriptionService = subscriptionService;

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
    final jsonStr = await _safeRead('openai_api_keys');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) keys = List<String>.from(decoded);
      } catch (e) {
        debugPrint('Error decoding openai keys: $e');
      }
    }

    // 2. Try single key
    if (keys.isEmpty) {
      String? key = await _safeRead('openai_api_key');
      if (key != null && key.isNotEmpty) keys.add(key);
    }

    // 3. Try legacy key
    if (keys.isEmpty) {
      String? key = await _safeRead('chatGptApiKey');
      if (key != null && key.isNotEmpty) keys.add(key);
    }

    // 4. Try env/helper key
    if (keys.isEmpty) {
      keys.add(ApiKeyHelper.gptKey);
    }

    return keys.where((k) => k.isNotEmpty).toSet().toList();
  }

  Future<void> _checkTokenLimit(String clinicId) async {
    final tier = await _subscriptionService.getCurrentTier(clinicId);
    final limit = tier.maxMonthlyTokens;

    // If usage tracking isn't critical or we want to allow overage for now,
    // we could skip throwing. But requirement implies enforcement.
    final usage = await _quotaService.getUsage(
      clinicId,
      null,
      LimitType.aiTokens,
    );

    if (usage >= limit) {
      throw Exception(
        'Monthly AI token limit exceeded. Please upgrade your plan.',
      );
    }
  }

  @override
  Future<String> generateResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    if (clinicId != null) {
      await _checkTokenLimit(clinicId);
    }
    return getGPTResponse(
      query,
      messageHistory: messageHistory,
      clinicId: clinicId,
      userId: userId,
    );
  }

  @override
  Future<String> generateResponseWithImage(
    String query,
    Uint8List imageBytes, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    if (clinicId != null) {
      await _checkTokenLimit(clinicId);
    }

    final keys = await _getApiKeys();
    if (keys.isEmpty) {
      throw Exception(
        'OpenAI API Key not found. Please configure it in settings.',
      );
    }

    // Using GPT-4o for vision capabilities
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final messages = <Map<String, dynamic>>[];
    messages.add({
      'role': 'user',
      'content': [
        {'type': 'text', 'text': query},
        {
          'type': 'image_url',
          'image_url': {
            'url': 'data:image/jpeg;base64,${base64Encode(imageBytes)}',
          },
        },
      ],
    });

    final body = jsonEncode({
      'model': 'gpt-4o',
      'messages': messages,
      'max_tokens': 500,
    });

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

          // Track tokens
          if (clinicId != null) {
            final usage = data['usage'];
            if (usage != null) {
              final totalTokens = usage['total_tokens'] as int?;
              if (totalTokens != null) {
                await _quotaService.incrementUsage(
                  clinicId,
                  userId,
                  LimitType.aiTokens,
                  amount: totalTokens,
                );
              }
            }
          }

          return data['choices'][0]['message']['content'];
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception('GPT error: ${errorData['error']['message']}');
        }
      } catch (e) {
        debugPrint('GPT key $i failed (Vision): $e');
        if (i == keys.length - 1) rethrow;
      }
    }
    throw Exception('All OpenAI keys failed.');
  }

  Future<String> getGPTResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    final keys = await _getApiKeys();
    if (keys.isEmpty) {
      throw Exception(
        'OpenAI API Key not found. Please configure it in settings.',
      );
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // Build messages array with history
    final List<Map<String, dynamic>> messages = [];

    // Add system message
    messages.add({
      'role': 'system',
      'content':
          'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals.',
    });

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
      'model': 'gpt-3.5-turbo',
      'messages': messages,
      'max_tokens': 500,
    });

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

          // Track tokens
          if (clinicId != null) {
            final usage = data['usage'];
            if (usage != null) {
              final totalTokens = usage['total_tokens'] as int?;
              if (totalTokens != null) {
                await _quotaService.incrementUsage(
                  clinicId,
                  userId,
                  LimitType.aiTokens,
                  amount: totalTokens,
                );
              }
            }
          }

          return data['choices'][0]['message']['content'];
        } else {
          final errorData = jsonDecode(response.body);
          throw Exception('GPT error: ${errorData['error']['message']}');
        }
      } catch (e) {
        debugPrint('GPT key $i failed: $e');
        if (i == keys.length - 1) rethrow;
      }
    }
    throw Exception('All OpenAI keys failed.');
  }
}
