import 'dart:convert';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/user_preferences_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

class CommandParserService {
  final GeminiService _geminiService;

  CommandParserService(this._geminiService);

  Future<Map<String, dynamic>> parseCommand(
      String command,
      List<String> conversationHistory,
      Command? previousCommand,
      UserPreferencesService userPreferencesService) async {
    final prompt = """
      You are a command parser for a medical assistant app.
      Your task is to parse the user's voice command and extract the intent and the entities.

      If the user's command is a follow-up to a previous command, use the context of the previous command to understand the user's intent.
      For example, if the previous command was "schedule a session for John Doe", and the user says "send him a confirmation", you should understand that "him" refers to "John Doe".

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
        - duration (integer, in minutes)
      - record_evaluation:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
      - show_appointments:
        - date (string, in YYYY-MM-DD format, e.g., "today", "tomorrow")
      - show_revenue:
        - period (string, e.g., "this month", "last month")
      - send_confirmation:
        - patient_name (string)
      - ask_for_information:
        - question (string)
      - conversational_chat:
        - response (string)

      User Preferences:
      - Preferred session duration: ${userPreferencesService.getPreferredSessionDuration()} minutes

      Conversation History:
      ${conversationHistory.join('\n')}

      Previous Command:
      ${previousCommand?.intent}
      ${previousCommand?.entities}

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

  Future<String> generateResponse(Command command) async {
    final prompt = """
      You are a medical assistant AI.
      Your task is to generate a natural language response to confirm that a command has been executed successfully.

      The executed command is:
      Intent: ${command.intent}
      Entities: ${command.entities}

      Based on this command, generate a friendly and natural confirmation message.
      For example, if the command was to schedule a session for John Doe, a good response would be "OK, I've scheduled a session for John Doe."

      Response:
    """;

    final response = await _geminiService.getGeminiResponse(prompt);
    final jsonResponse =
        response.parts.map((part) => (part as TextPart).text).join('');

    return jsonResponse;
  }

  Future<String> generateGreeting(String userName, String timeOfDay) async {
    final prompt = """
    You are a medical assistant AI.
    Your task is to generate a personalized greeting for the user.

    The user's name is $userName.
    The time of day is $timeOfDay.

    Based on this information, generate a friendly and professional greeting.
    For example, "Good morning, Dr. Smith. How can I help you today?"

    Greeting:
  """;

    final response = await _geminiService.getGeminiResponse(prompt);
    final jsonResponse =
        response.parts.map((part) => (part as TextPart).text).join('');

    return jsonResponse;
  }
}
