import 'dart:convert';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class CommandParserService {
  final GeminiService _geminiService;

  CommandParserService(this._geminiService);

  Future<Map<String, dynamic>> parseCommand(
      String command, List<String> conversationHistory) async {
    final prompt = """
      You are a command parser for a medical assistant app.
      Your task is to parse the user's voice command and extract the intent and the entities.

      If the user is missing information required for a command, you should ask for it.
      For example, if the user says "schedule a session", you should ask "For which patient?".
      The intent in this case should be "ask_for_information", and the "question" entity should contain the question to ask the user.

      If the user is just having a conversation, the intent should be "conversational_chat" and the "response" entity should contain a friendly and helpful response to the user's message.

      The output should be a JSON object with the following structure:
      {
        "intent": "intent_name",
        "entities": {
          "entity_name": "entity_value",
          ...
        }
      }

      If you cannot parse the command, return an error in the JSON object like this:
      {
        "error": "Could not parse command."
      }

      Here are the possible intents and their entities:
      - add_patient:
        - name (string)
        - age (integer)
        - phone (string)
        - address (string)
        - gender (string)
      - schedule_session:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
        - time (string, in HH:MM format)
      - record_evaluation:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
      - show_appointments:
        - date (string, in YYYY-MM-DD format, e.g., "today", "tomorrow")
      - show_revenue:
        - period (string, e.g., "this month", "last month")
      - ask_for_information:
        - question (string)
      - conversational_chat:
        - response (string)

      Conversation History:
      ${conversationHistory.join('\n')}

      User command: "$command"

      JSON output:
    """;

    final response = await _geminiService.getGeminiResponse(prompt);
    final jsonResponse =
        response.parts.map((part) => (part as TextPart).text).join('');

    try {
      final decoded = jsonDecode(jsonResponse);

      if (decoded['error'] != null) {
        throw Exception(decoded['error']);
      }

      return decoded;
    } catch (e) {
      print('Error decoding JSON: $e');
      throw Exception('Failed to parse command from AI response.');
    }
  }
}
