import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';

class QwenService implements AIService {
  final String apiKey;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  QwenService(
    this.apiKey, {
    required QuotaService quotaService,
    required SubscriptionService subscriptionService,
  }) : _quotaService = quotaService,
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
    return getQwenResponse(
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
    // Qwen might not support image input directly via this endpoint or model
    // Mapping to existing implementation for now
    return getQwenResponseFromBytes(
      imageBytes,
      clinicId: clinicId,
      userId: userId,
    );
  }

  Future<String> getQwenResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    final url = Uri.parse(
      'https://dashscope.aliyuncs.com/api/v1/services/aigc/text-generation/generation',
    );

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

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'qwen-turbo',
        'input': {'messages': messages},
      }),
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

      return data['output']['text'];
    } else {
      throw Exception('Failed to get response from Qwen: ${response.body}');
    }
  }

  Future<String> getQwenResponseFromBytes(
    Uint8List fileBytes, {
    String? clinicId,
    String? userId,
  }) async {
    final url = Uri.parse('https://api.qwen.com/v1/query');
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
        // Fallback tracking
        await _quotaService.incrementUsage(
          clinicId,
          userId,
          LimitType.aiTokens,
          amount: 1000,
        );
      }

      return data['response'];
    } else {
      throw Exception('Failed to get response from Qwen');
    }
  }
}

