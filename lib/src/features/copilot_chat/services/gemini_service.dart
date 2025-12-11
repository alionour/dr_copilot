import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';

class GeminiService implements AIService {
  final FlutterSecureStorage _secureStorage;
  final QuotaService _quotaService;
  final SubscriptionService _subscriptionService;

  GeminiService(
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
    final jsonStr = await _safeRead('gemini_api_keys');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) keys = List<String>.from(decoded);
      } catch (e) {
        debugPrint('Error decoding gemini keys: $e');
      }
    }

    // 2. Try single key
    if (keys.isEmpty) {
      String? key = await _safeRead('gemini_api_key');
      if (key != null && key.isNotEmpty) keys.add(key);
    }

    // 3. Try legacy key
    if (keys.isEmpty) {
      String? key = await _safeRead('geminiApiKey');
      if (key != null && key.isNotEmpty) keys.add(key);
    }

    // 4. Try env/helper key
    if (keys.isEmpty) {
      keys.add(ApiKeyHelper.geminiKey);
    }

    return keys.where((k) => k.isNotEmpty).toSet().toList();
  }

  GenerativeModel _getModel(String apiKey) {
    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API Key not found. Please configure it in settings.',
      );
    }
    return GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      tools: getGeminiTools(),
      systemInstruction: Content.text(
        'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals. Your core responsibilities include providing accurate medical information, efficiently managing patient records, and handling appointments and evaluations. You can execute specific functions within the application, such as adding, editing, or deleting patient profiles, scheduling and modifying sessions, and managing evaluations. When a user requests a function, you will proactively confirm the action and gather any necessary missing details through a conversational interface before proceeding. You are also capable of discussing patient-specific information and retrieving relevant data based on various criteria like name, ID, or date. Your goal is to streamline administrative tasks and enhance clinical decision-making.',
      ),
    );
  }

  GenerativeModel _getVisionModel(String apiKey) {
    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API Key not found. Please configure it in settings.',
      );
    }
    return GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
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

    for (int i = 0; i < keys.length; i++) {
      try {
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
        debugPrint('Gemini key $i failed (Vision): $e');
        if (i == keys.length - 1) rethrow;
      }
    }
    throw Exception('All Gemini keys failed.');
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

    for (int i = 0; i < keys.length; i++) {
      try {
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
        debugPrint('Gemini key $i failed: $e');
        if (i == keys.length - 1) rethrow;
      }
    }
    throw Exception('All Gemini keys failed.');
  }
}
