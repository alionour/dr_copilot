import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ClinicalReportAIService {
  final FlutterSecureStorage _secureStorage;

  ClinicalReportAIService(this._secureStorage);

  Future<GenerativeModel> _getModel() async {
    String? apiKey = await _secureStorage.read(key: 'geminiApiKey');
    if (apiKey == null || apiKey.isEmpty) {
      apiKey = ApiKeyHelper.geminiKey;
    }

    if (apiKey.isEmpty) {
      throw Exception(
        'Gemini API Key not found. Please configure it in settings.',
      );
    }

    return GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: apiKey);
  }

  Future<String> editReport(String currentContent, String instruction) async {
    try {
      final model = await _getModel();
      final prompt =
          '''
You are a medical assistant helping a doctor write a clinical report.
Current Report Content (Quill Delta JSON):
$currentContent

User Instruction:
$instruction

Task:
Modify the report content based on the instruction.
Return ONLY the updated content in valid Quill Delta JSON format.
Do not include any markdown formatting (like ```json ... ```), just the raw JSON string.
If the instruction implies a minor change, preserve the rest of the document structure as much as possible.
If the instruction is to "fix grammar" or "refine", apply it to the text within the JSON structure.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null) {
        throw Exception('Empty response from AI');
      }

      // Clean up potential markdown code blocks
      String result = response.text!.trim();
      if (result.startsWith('```json')) {
        result = result.substring(7);
      } else if (result.startsWith('```')) {
        result = result.substring(3);
      }
      if (result.endsWith('```')) {
        result = result.substring(0, result.length - 3);
      }

      return result.trim();
    } catch (e) {
      throw Exception('Failed to edit report: $e');
    }
  }

  Future<String> editSelection(String selection, String instruction) async {
    try {
      final model = await _getModel();
      final prompt =
          '''
You are a medical assistant helping a doctor write a clinical report.
Selected Text:
"$selection"

User Instruction:
$instruction

Task:
Rewrite the selected text based on the instruction.
Return ONLY the rewritten text.
Do not include any markdown formatting or explanations.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null) {
        throw Exception('Empty response from AI');
      }

      return response.text!.trim();
    } catch (e) {
      throw Exception('Failed to edit selection: $e');
    }
  }

  Future<String> chat(String message) async {
    try {
      final model = await _getModel();
      final prompt =
          '''
You are a helpful medical assistant.
User Message:
$message

Task:
Respond to the user's message in a helpful and professional manner.
''';

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      if (response.text == null) {
        throw Exception('Empty response from AI');
      }

      return response.text!.trim();
    } catch (e) {
      throw Exception('Failed to chat: $e');
    }
  }
}
