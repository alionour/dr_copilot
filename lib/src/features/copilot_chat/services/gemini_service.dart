import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/domain/services/ai_service_interface.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/gemini_tools.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService implements AIService {
  final String apiKey;
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      tools: getGeminiTools(),
      systemInstruction: Content.text(
          'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals. Your core responsibilities include providing accurate medical information, efficiently managing patient records, and handling appointments and evaluations. You can execute specific functions within the application, such as adding, editing, or deleting patient profiles, scheduling and modifying sessions, and managing evaluations. When a user requests a function, you will proactively confirm the action and gather any necessary missing details through a conversational interface before proceeding. You are also capable of discussing patient-specific information and retrieving relevant data based on various criteria like name, ID, or date. Your goal is to streamline administrative tasks and enhance clinical decision-making.'),
    );

    // Vision model usually doesn't support tools in the same way or might need a different model name
    // For now using the same model as it supports multimodal
    _visionModel = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
  }

  @override
  Future<String> generateResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    return (await getGeminiResponse(query, messageHistory: messageHistory))
            .text ??
        '';
  }

  @override
  Future<String> generateResponseWithImage(
    String query,
    Uint8List imageBytes, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final content = [
      Content.multi([
        TextPart(query),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await _visionModel.generateContent(content);
    return response.text ?? '';
  }

  Future<GenerateContentResponse> getGeminiResponse(
    String query, {
    List<Map<String, dynamic>> messageHistory = const [],
  }) async {
    final List<Content> contents = [];

    // Add message history (last 8 messages for context)
    for (var message in messageHistory) {
      final isUser = message['isUser'] as bool? ?? false;
      final text = message['message'] as String? ?? '';

      if (text.isNotEmpty) {
        contents.add(Content(
          isUser ? 'user' : 'model',
          [TextPart(text)],
        ));
      }
    }

    // Add current query
    contents.add(Content.text(query));

    final response = await _model.generateContent(contents);
    return response;
  }
}
