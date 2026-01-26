import 'dart:convert';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/openai_tools.dart';
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/utils/ai_context_provider.dart';
import 'package:flutter/foundation.dart';

/// Represents a function call from the AI
class GroqFunctionCall {
  final String name;
  final Map<String, dynamic> arguments;

  GroqFunctionCall({required this.name, required this.arguments});
}

/// Represents a response from Groq that may contain either text or a function call
class GroqResponse {
  final String? text;
  final GroqFunctionCall? functionCall;

  GroqResponse({this.text, this.functionCall});

  bool get hasFunctionCall => functionCall != null;
}

/// Groq Service - Uses Groq's ultra-fast inference with Llama models
/// Free tier: 500k+ tokens/day, 1000+ requests/day, no credit card required
/// Supports function calling for database operations
class GroqService implements AIService {
  final String apiKey;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  GroqService(
    this.apiKey, {
    required QuotaService quotaService,
    required SubscriptionService subscriptionService,
  })  : _quotaService = quotaService,
        _subscriptionService = subscriptionService;

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

  // dynamic configuration
  List<String> _currentRequiredFields = [];

  @override
  void updateModelConfig(List<String> requiredFields) {
    _currentRequiredFields = requiredFields;
    debugPrint('[GroqService] Updated model config: $requiredFields');
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
    final response = await getGroqResponse(
      query,
      messageHistory: messageHistory,
      clinicId: clinicId,
      userId: userId,
    );
    return response.text ?? '';
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
    // Groq doesn't support image input directly, fall back to text-only
    debugPrint('[GroqService] Image input not supported, processing text only');
    final response = await getGroqResponse(
      query,
      messageHistory: messageHistory,
      clinicId: clinicId,
      userId: userId,
    );
    return response.text ?? '';
  }

  /// Gets a response from Groq with function calling support
  Future<GroqResponse> getGroqResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    // Build messages array with history
    final List<Map<String, dynamic>> messages = [];

    // Add dynamic system message
    messages.add({
      'role': 'system',
      'content': AIContextProvider.getBaseSystemInstruction(
          requiredFields: _currentRequiredFields),
    });

    // Add message history
    // Add message history
    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';

      // Only include text messages in history to avoid tool validation issues
      // Groq specifically validates historical tool calls against current tools
      if (text.isNotEmpty) {
        messages.add({'role': isUser ? 'user' : 'assistant', 'content': text});
      }
    }

    // Add current query
    messages.add({'role': 'user', 'content': query});

    debugPrint(
        '[GroqService] Sending request to Groq API with function calling...');
    debugPrint('[GroqService] Messages payload: ${jsonEncode(messages)}');

    final tools = getOpenAITools(userRequiredFields: _currentRequiredFields);

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model':
              'llama-3.3-70b-versatile', // Best free model with tool support
          'messages': messages,
          'tools': tools,
          'tool_choice': 'auto', // Let model decide when to use tools
          'parallel_tool_calls':
              true, // Allow model to use its default parallel structure
          'temperature': 0.7,
          'max_tokens': 4096,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
            'Request timed out. Please check your internet connection or try again.',
          );
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Track tokens
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

        // Check if there's a tool call
        if (message['tool_calls'] != null &&
            (message['tool_calls'] as List).isNotEmpty) {
          final toolCall = message['tool_calls'][0];
          final functionName = toolCall['function']['name'] as String;

          // Safely parse arguments with null check
          final argsString = toolCall['function']['arguments'] as String?;
          Map<String, dynamic> functionArgs = {};
          if (argsString != null && argsString.isNotEmpty) {
            final decoded = jsonDecode(argsString);
            if (decoded is Map<String, dynamic>) {
              functionArgs = decoded;
            } else if (decoded is Map) {
              functionArgs = Map<String, dynamic>.from(decoded);
            }
          }

          debugPrint('[GroqService] Function call detected: $functionName');
          debugPrint('[GroqService] Arguments: $functionArgs');

          return GroqResponse(
            functionCall: GroqFunctionCall(
              name: functionName,
              arguments: functionArgs,
            ),
          );
        }

        // Regular text response
        debugPrint('[GroqService] Text response received');
        return GroqResponse(text: message['content'] as String?);
      } else {
        debugPrint(
            '[GroqService] Error: ${response.statusCode} ${response.body}');
        throw Exception('Failed to get response from Groq: ${response.body}');
      }
    } catch (e) {
      debugPrint('[GroqService] Exception: $e');
      rethrow;
    }
  }
}
