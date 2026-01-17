import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_tools.dart';
import 'package:dr_copilot/src/features/copilot_chat/utils/ai_context_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  GeminiService(
    this.apiKey, {
    required QuotaService quotaService,
    required SubscriptionService subscriptionService,
  })  : _quotaService = quotaService,
        _subscriptionService = subscriptionService;

  Future<List<String>> _getApiKeys() async {
    if (apiKey.isNotEmpty) return [apiKey];
    return [];
  }

  // User preferences for tool validation
  List<String> _currentRequiredFields = [];

  @override
  void updateModelConfig(List<String> requiredFields) {
    _currentRequiredFields = requiredFields;
    debugPrint('[GeminiService] Updated model config: $requiredFields');
  }

  GenerativeModel _getModel(String apiKey) {
    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API Key not found. Please configure it in settings.',
      );
    }

    return GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      tools: getGeminiTools(userRequiredFields: _currentRequiredFields),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
      systemInstruction: Content.text(
        () {
          final instruction = AIContextProvider.getBaseSystemInstruction();
          debugPrint('[GeminiService] System Instruction: $instruction');
          return instruction;
        }(),
      ),
    );
  }

  GenerativeModel _getVisionModel(String apiKey) {
    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API Key not found. Please configure it in settings.',
      );
    }
    // gemini-2.5-flash is multimodal
    return GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
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

    final response = await getGeminiResponse(
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

    final keys = await _getApiKeys();
    if (keys.isEmpty) throw Exception('No Gemini API keys found.');

    final content = [
      Content.multi([TextPart(query), DataPart('image/jpeg', imageBytes)]),
    ];

    List<String> errors = [];

    for (int i = 0; i < keys.length; i++) {
      try {
        debugPrint(
            '[GeminiService] Attempting with Key ${i + 1} of ${keys.length}...');
        final model = _getVisionModel(keys[i]);
        final response = await model.generateContent(content);

        // Track usage
        if (clinicId != null) {
          final totalTokens = response.usageMetadata?.totalTokenCount;
          if (totalTokens != null) {
            await _quotaService.incrementUsage(
              clinicId,
              userId,
              LimitType.aiTokens,
              amount: totalTokens,
            );
          }
        }

        return response.text ?? '';
      } catch (e) {
        final errorMsg = 'Key ${i + 1} error: $e';
        debugPrint('[GeminiService] $errorMsg');
        errors.add(errorMsg);
      }
    }
    throw Exception(
        'All ${keys.length} Gemini keys failed. Details:\n${errors.join("\n")}');
  }

  Future<GenerateContentResponse> getGeminiResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
    String? clinicId,
    String? userId,
  }) async {
    final keys = await _getApiKeys();
    if (keys.isEmpty) throw Exception('No Gemini API keys found.');

    final List<Content> contents = [];

    // Add message history (last 8 messages for context)
    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';

      if (text.isNotEmpty) {
        contents.add(Content(isUser ? 'user' : 'model', [TextPart(text)]));
      }
    }

    // Add current query
    contents.add(Content.text(query));

    List<String> errors = [];

    for (int i = 0; i < keys.length; i++) {
      try {
        debugPrint(
            '[GeminiService] Attempting with Key ${i + 1} of ${keys.length}...');
        final model = _getModel(keys[i]);
        final response = await model.generateContent(contents);

        // Track usage
        if (clinicId != null) {
          final totalTokens = response.usageMetadata?.totalTokenCount;
          if (totalTokens != null) {
            await _quotaService.incrementUsage(
              clinicId,
              userId,
              LimitType.aiTokens,
              amount: totalTokens,
            );
          }
        }

        return response;
      } catch (e) {
        final errorMsg = 'Key ${i + 1} error: $e';
        debugPrint('[GeminiService] $errorMsg');
        errors.add(errorMsg);
      }
    }
    throw Exception(
        'All ${keys.length} Gemini keys failed. Details:\n${errors.join("\n")}');
  }
}
