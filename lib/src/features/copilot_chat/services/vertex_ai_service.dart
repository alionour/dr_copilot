import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:http/http.dart' as http;
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/utils/ai_context_provider.dart';

class VertexAIService implements AIService {
  final String apiKey;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  VertexAIService(
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
    return getMedPaLMResponse(
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
    // Vertex AI (MedPaLM) might handle images differently, but for now we map to the existing byte method
    return getMedPaLMResponseFromBytes(
      imageBytes,
      clinicId: clinicId,
      userId: userId,
    );
  }

  // dynamic configuration
  List<String> _currentRequiredFields = [];

  @override
  void updateModelConfig(List<String> requiredFields) {
    _currentRequiredFields = requiredFields;
  }

  Future<String> getMedPaLMResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    final url = Uri.parse(
      'https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/models/YOUR_MODEL_ID:predict',
    );

    // Build context from message history
    String context = '';
    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';

      if (text.isNotEmpty) {
        context += '${isUser ? "User" : "Assistant"}: $text\n';
      }
    }

    // Combine context with current query and system instruction
    final systemInstruction = AIContextProvider.getBaseSystemInstruction(
        requiredFields: _currentRequiredFields);

    final fullPrompt = context.isNotEmpty
        ? '$systemInstruction\n\n$context\nUser: $query\nAssistant:'
        : '$systemInstruction\n\nUser: $query\nAssistant:';

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'instances': [
          {'content': fullPrompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Attempt to track tokens from metadata if available, otherwise estimate
      if (clinicId != null) {
        int estimatedTokens = 0;
        if (data['metadata'] != null &&
            data['metadata']['tokenCount'] != null) {
          estimatedTokens = data['metadata']['tokenCount'] as int;
        } else {
          // Rough estimation: 4 chars per token for input + output
          estimatedTokens = (fullPrompt.length +
                  (data['predictions'][0]['content'] as String).length) ~/
              4;
        }

        if (estimatedTokens > 0) {
          await _quotaService.incrementUsage(
            clinicId,
            userId,
            LimitType.aiTokens,
            amount: estimatedTokens,
          );
        }
      }

      return data['predictions'][0]['content'];
    } else {
      throw Exception(
        'Failed to get response from Vertex AI: ${response.body}',
      );
    }
  }

  Future<String> getMedPaLMResponseFromBytes(
    Uint8List fileBytes, {
    String? clinicId,
    String? userId,
  }) async {
    final url = Uri.parse(
      'https://us-central1-aiplatform.googleapis.com/v1/projects/YOUR_PROJECT_ID/locations/us-central1/models/YOUR_MODEL_ID:predict',
    );
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'instances': [
          {'content': base64Encode(fileBytes)},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (clinicId != null) {
        // Token logic for images is complex, specific to model.
        // Using a flat rate for image requests if not provided by API
        await _quotaService.incrementUsage(
          clinicId,
          userId,
          LimitType.aiTokens,
          amount: 1000,
        );
      }

      return data['predictions'][0]['content'];
    } else {
      throw Exception('Failed to get response from Vertex AI');
    }
  }
}
