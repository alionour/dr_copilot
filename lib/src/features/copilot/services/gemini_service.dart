import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService(this.apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: apiKey,
    );
    _chat = _model.startChat();
  }

  Future<String> getGeminiResponse(String query) async {
    try {
      final response = await _chat.sendMessage(Content.text(query));
      final text = response.text;
      if (text == null) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } catch (e) {
      throw Exception('Failed to get response from Gemini: $e');
    }
  }

  Future<String> getGeminiResponseFromBytes(Uint8List fileBytes) async {
    try {
      final base64String = base64Encode(fileBytes);
      final response = await _chat.sendMessage(Content.text(base64String));
      final text = response.text;
      if (text == null) {
        throw Exception('Empty response from Gemini');
      }
      return text;
    } catch (e) {
      throw Exception('Failed to get response from Gemini: $e');
    }
  }
}
