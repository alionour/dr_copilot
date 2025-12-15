import 'dart:convert';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class ClinicalReportAIService {
  final FlutterSecureStorage _secureStorage;

  ClinicalReportAIService(this._secureStorage);

  Future<String> _getApiKey(String model) async {
    String? apiKey = await _secureStorage.read(key: '${model}_api_key');

    // Fallback for Gemini and OpenAI if not found in secure storage (legacy support)
    if (apiKey == null || apiKey.isEmpty) {
      if (model == 'gemini') {
        // Try legacy key
        apiKey = await _secureStorage.read(key: 'geminiApiKey');
        if (apiKey == null || apiKey.isEmpty) {
          apiKey = ApiKeyHelper.geminiKey;
        }
      } else if (model == 'openai') {
        // Try legacy key
        apiKey = await _secureStorage.read(key: 'chatGptApiKey');
        if (apiKey == null || apiKey.isEmpty) {
          apiKey = ApiKeyHelper.gptKey;
        }
      } else if (model == 'claude') {
        apiKey = ApiKeyHelper.claudeKey;
      }
    }

    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'API Key for $model not found. Please configure it in settings.',
      );
    }
    return apiKey;
  }

  Future<String> _generateContent(String prompt) async {
    final selectedModel =
        await _secureStorage.read(key: 'selected_ai_model') ?? 'gemini';

    if (selectedModel == 'openai') {
      return _generateOpenAIContent(prompt);
    } else if (selectedModel == 'claude') {
      return _generateClaudeContent(prompt);
    } else {
      return _generateGeminiContent(prompt);
    }
  }

  Future<String> _generateGeminiContent(String prompt) async {
    final apiKey = await _getApiKey('gemini');
    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
    );
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);

    if (response.text == null) {
      throw Exception('Empty response from Gemini');
    }
    return response.text!;
  }

  Future<String> _generateOpenAIContent(String prompt) async {
    final apiKey = await _getApiKey('openai');
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-4o',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenAI Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> _generateClaudeContent(String prompt) async {
    final apiKey = await _getApiKey('claude');
    final url = Uri.parse('https://api.anthropic.com/v1/messages');

    final response = await http.post(
      url,
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-3-5-sonnet-20240620',
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'];
    } else {
      throw Exception('Claude Error: ${response.statusCode} ${response.body}');
    }
  }

  Future<String> editReport(
    String currentContent,
    String instruction, {
    String? clinicalData,
  }) async {
    try {
      final prompt =
          '''
You are a medical assistant helping a doctor write a clinical report.
Current Report Content (HTML):
$currentContent

User Instruction:
$instruction

${clinicalData != null && clinicalData.isNotEmpty ? 'Clinical Data:\n$clinicalData\n' : ''}
Task:
Modify the report content based on the instruction and provided clinical data.
Return ONLY the updated content in valid HTML format.
Do not include any markdown formatting (like ```html ... ```), just the raw HTML string.
If the instruction implies a minor change, preserve the rest of the document structure as much as possible.
If the instruction is to "fix grammar" or "refine", apply it to the text within the HTML structure.
''';

      final responseText = await _generateContent(prompt);

      // Clean up potential markdown code blocks
      String result = responseText.trim();
      if (result.startsWith('```html')) {
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

  Future<String> editSelection(
    String selection,
    String instruction, {
    String? clinicalData,
  }) async {
    try {
      final prompt =
          '''
You are a medical assistant helping a doctor write a clinical report.
Selected Text:
"$selection"

User Instruction:
$instruction

${clinicalData != null && clinicalData.isNotEmpty ? 'Clinical Data:\n$clinicalData\n' : ''}
Task:
Rewrite the selected text based on the instruction and provided clinical data.
Return ONLY the rewritten text.
Do not include any markdown formatting or explanations.
''';

      final responseText = await _generateContent(prompt);
      return responseText.trim();
    } catch (e) {
      throw Exception('Failed to edit selection: $e');
    }
  }

  Future<String> chat(String message, {String? clinicalData}) async {
    try {
      final prompt =
          '''
You are a helpful medical assistant.
User Message:
$message

${clinicalData != null && clinicalData.isNotEmpty ? 'Clinical Data:\n$clinicalData\n' : ''}
Task:
Respond to the user's message in a helpful and professional manner, incorporating the clinical data if relevant.
''';

      final responseText = await _generateContent(prompt);
      return responseText.trim();
    } catch (e) {
      throw Exception('Failed to chat: $e');
    }
  }

  Future<String> refineText(String text, String type) async {
    try {
      final prompt =
          '''
You are a helpful medical assistant.
User Input ($type):
"$text"

Task:
Refine the user input to be more professional, clear, and grammatically correct.
If the input is an instruction, make it a clear and concise instruction for an AI.
If the input is clinical data, format it as a professional clinical note snippet.
Return ONLY the refined text.
Do not include any explanations or markdown formatting.
''';

      final responseText = await _generateContent(prompt);
      return responseText.trim();
    } catch (e) {
      throw Exception('Failed to refine text: $e');
    }
  }
}

