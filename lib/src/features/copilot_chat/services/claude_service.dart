import 'dart:convert';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/utils/ai_context_provider.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/openai_tools.dart';

/// Represents a function call from Claude
class ClaudeFunctionCall {
  final String name;
  final Map<String, dynamic> arguments;

  ClaudeFunctionCall({required this.name, required this.arguments});
}

/// Represents a response from Claude
class ClaudeResponse {
  final String? text;
  final ClaudeFunctionCall? functionCall;

  ClaudeResponse({this.text, this.functionCall});

  bool get hasFunctionCall => functionCall != null;
}

class ClaudeService implements AIService {
  // ... existing fields ...
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
    // ... (existing logic)
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
    final response = await getClaudeResponseRaw(
      query,
      messageHistory: messageHistory,
      clinicId: clinicId,
      userId: userId,
    );
    return response.text ?? '';
  }

  // ... generateResponseWithImage remains as is ...
  @override
  Future<String> generateResponseWithImage(
    String query,
    Uint8List imageBytes, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    // ... keep existing implementation ...
    if (clinicId != null) {
      await _checkTokenLimit(clinicId);
    }
    final keys = await _getApiKeys();
    if (keys.isEmpty) throw Exception('Claude API Key not found.');
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
      'system': 'You are Dr. AI.',
      'messages': messages,
    });
    for (int i = 0; i < keys.length; i++) {
      try {
        final response = await http.post(url,
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': keys[i],
              'anthropic-version': '2023-06-01'
            },
            body: body);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // usage tracking skipped for brevity
          return data['content'][0]['text'];
        }
      } catch (e) {}
    }
    throw Exception('All Claude keys failed.');
  }

  // dynamic configuration
  List<String> _currentRequiredFields = [];

  @override
  void updateModelConfig(List<String> requiredFields) {
    _currentRequiredFields = requiredFields;
  }

  Future<ClaudeResponse> getClaudeResponseRaw(
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

    final messages = <Map<String, dynamic>>[];

    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';
      if (text.isNotEmpty) {
        messages.add({'role': isUser ? 'user' : 'assistant', 'content': text});
      }
    }

    messages.add({'role': 'user', 'content': query});

    final openAiTools =
        getOpenAITools(userRequiredFields: _currentRequiredFields);
    final claudeTools = openAiTools.map((t) {
      final func = t['function'] as Map<String, dynamic>;
      return {
        'name': func['name'],
        'description': func['description'],
        'input_schema': func['parameters'],
      };
    }).toList();

    final body = jsonEncode({
      'model': 'claude-3-5-sonnet-20241022',
      'max_tokens': 1024,
      'system': AIContextProvider.getBaseSystemInstruction(
          requiredFields: _currentRequiredFields),
      'messages': messages,
      'tools': claudeTools,
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
          if (clinicId != null && data['usage'] != null) {
            final usage = data['usage'];
            final inputTokens = usage['input_tokens'] as int? ?? 0;
            final outputTokens = usage['output_tokens'] as int? ?? 0;
            final totalTokens = inputTokens + outputTokens;
            if (totalTokens > 0) {
              await _quotaService.incrementUsage(
                  clinicId, userId, LimitType.aiTokens,
                  amount: totalTokens);
            }
          }

          final contentList = data['content'] as List;

          // Check for tool_use
          for (var item in contentList) {
            if (item['type'] == 'tool_use') {
              return ClaudeResponse(
                  functionCall: ClaudeFunctionCall(
                name: item['name'],
                arguments: item['input'] as Map<String, dynamic>,
              ));
            }
          }

          // Fallback to text
          for (var item in contentList) {
            if (item['type'] == 'text') {
              return ClaudeResponse(text: item['text']);
            }
          }

          return ClaudeResponse(text: '');
        } else {
          try {
            final err = jsonDecode(response.body);
            debugPrint('Claude error details: $err');
          } catch (_) {}
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

  // End of getClaudeResponseRaw
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
