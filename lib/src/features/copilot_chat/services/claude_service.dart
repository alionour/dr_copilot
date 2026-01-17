import 'dart:convert';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/utils/ai_context_provider.dart';

class ClaudeService implements AIService {
  final String apiKey;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  ClaudeService(
    this.apiKey, {
    required QuotaService quotaService,
    required SubscriptionService subscriptionService,
  })  : _quotaService = quotaService,
        _subscriptionService = subscriptionService;

  Future<List<String>> _getApiKeys() async {
    if (apiKey.isNotEmpty) return [apiKey];
    return [];
  }

  Future<void> _checkTokenLimit(String clinicId) async {
    final tier = await _subscriptionService.getCurrentTier(clinicId);
    final limit = tier.maxMonthlyTokens;
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
    return getClaudeResponse(
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

          // Track tokens
          if (clinicId != null) {
            final usage = data['usage'];
            if (usage != null) {
              final inputTokens = usage['input_tokens'] as int? ?? 0;
              final outputTokens = usage['output_tokens'] as int? ?? 0;
              final totalTokens = inputTokens + outputTokens;

              if (totalTokens > 0) {
                await _quotaService.incrementUsage(
                  clinicId,
                  userId,
                  LimitType.aiTokens,
                  amount: totalTokens,
                );
              }
            }
          }

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

  // dynamic configuration
  List<String> _currentRequiredFields = [];

  @override
  void updateModelConfig(List<String> requiredFields) {
    _currentRequiredFields = requiredFields;
  }

  Future<String> getClaudeResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
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
      'system': AIContextProvider.getBaseSystemInstruction(
          requiredFields: _currentRequiredFields),
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

          // Track tokens
          if (clinicId != null) {
            final usage = data['usage'];
            if (usage != null) {
              final inputTokens = usage['input_tokens'] as int? ?? 0;
              final outputTokens = usage['output_tokens'] as int? ?? 0;
              final totalTokens = inputTokens + outputTokens;

              if (totalTokens > 0) {
                await _quotaService.incrementUsage(
                  clinicId,
                  userId,
                  LimitType.aiTokens,
                  amount: totalTokens,
                );
              }
            }
          }

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
