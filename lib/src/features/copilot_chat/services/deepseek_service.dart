import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/utils/ai_context_provider.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/openai_tools.dart';

/// Represents a function call from DeepSeek
class DeepSeekFunctionCall {
  final String name;
  final Map<String, dynamic> arguments;

  DeepSeekFunctionCall({required this.name, required this.arguments});
}

/// Represents a response from DeepSeek
class DeepSeekResponse {
  final String? text;
  final DeepSeekFunctionCall? functionCall;

  DeepSeekResponse({this.text, this.functionCall});

  bool get hasFunctionCall => functionCall != null;
}

class DeepSeekService implements AIService {
  // ... existing fields ...
  final String apiKey;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  DeepSeekService(
    this.apiKey, {
    required QuotaService quotaService,
    required SubscriptionService subscriptionService,
  })  : _quotaService = quotaService,
        _subscriptionService = subscriptionService;

  // ... (keep helper methods like _checkTokenLimit)
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
    final response = await getDeepSeekResponseRaw(
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
    if (clinicId != null) {
      await _checkTokenLimit(clinicId);
    }
    // DeepSeek might not support image input directly via this endpoint or model
    return getDeepSeekResponseFromBytes(
      imageBytes,
      clinicId: clinicId,
      userId: userId,
    );
  }

  List<String> _currentRequiredFields = [];

  @override
  void updateModelConfig(List<String> requiredFields) {
    _currentRequiredFields = requiredFields;
  }

  Future<DeepSeekResponse> getDeepSeekResponseRaw(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    final url = Uri.parse('https://api.deepseek.com/chat/completions');

    final messages = <Map<String, dynamic>>[];
    messages.add({
      'role': 'system',
      'content': AIContextProvider.getBaseSystemInstruction(
          requiredFields: _currentRequiredFields),
    });

    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';
      if (text.isNotEmpty) {
        messages.add({'role': isUser ? 'user' : 'assistant', 'content': text});
      }
    }

    messages.add({'role': 'user', 'content': query});

    final tools = getOpenAITools(userRequiredFields: _currentRequiredFields);

    final body = jsonEncode({
      'model': 'deepseek-chat',
      'messages': messages,
      'tools': tools,
      'tool_choice': 'auto',
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (clinicId != null && data['usage'] != null) {
        final totalTokens = data['usage']['total_tokens'] as int?;
        if (totalTokens != null) {
          await _quotaService.incrementUsage(
            clinicId,
            userId,
            LimitType.aiTokens,
            amount: totalTokens,
          );
        }
      }

      final message = data['choices'][0]['message'];

      // Handle Tool Calls
      if (message['tool_calls'] != null) {
        final toolCalls = message['tool_calls'] as List;
        if (toolCalls.isNotEmpty) {
          final call = toolCalls[0];
          final function = call['function'];
          final args = jsonDecode(function['arguments']);
          return DeepSeekResponse(
            functionCall: DeepSeekFunctionCall(
              name: function['name'],
              arguments: args is Map<String, dynamic>
                  ? args
                  : Map<String, dynamic>.from(args),
            ),
          );
        }
      }
      return DeepSeekResponse(text: message['content']);
    } else {
      throw Exception('Failed to get response from DeepSeek: ${response.body}');
    }
  }

  Future<String> getDeepSeekResponseFromBytes(
    Uint8List fileBytes, {
    String? clinicId,
    String? userId,
  }) async {
    final url = Uri.parse('https://api.deepseek.com/v1/query');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({'query': base64Encode(fileBytes)}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (clinicId != null) {
        // Fallback tracking if usage not provided
        await _quotaService.incrementUsage(
          clinicId,
          userId,
          LimitType.aiTokens,
          amount: 1000,
        );
      }

      return data['response'];
    } else {
      throw Exception('Failed to get response from DeepSeek');
    }
  }
}
