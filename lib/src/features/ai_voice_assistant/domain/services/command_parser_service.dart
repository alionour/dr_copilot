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
      UserPreferencesService userPreferencesService,
      String languageCode) async {
    final prompt = languageCode == 'ar'
        ? _buildArabicParseCommandPrompt(command, conversationHistory, previousCommand, userPreferencesService)
        : _buildEnglishParseCommandPrompt(command, conversationHistory, previousCommand, userPreferencesService);

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

  String _buildEnglishParseCommandPrompt(String command, List<String> conversationHistory, Command? previousCommand, UserPreferencesService userPreferencesService) {
    return """
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
      - get_time:
        - (no entities)
      - delete_session:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
        - time (string, in HH:MM format)
      - delete_evaluation:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
      - delete_patient:
        - patient_name (string)
      - delete_session:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
        - time (string, in HH:MM format)
      - delete_evaluation:
        - patient_name (string)
        - date (string, in YYYY-MM-DD format)
      - delete_patient:
        - patient_name (string)

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
  }

  String _buildArabicParseCommandPrompt(String command, List<String> conversationHistory, Command? previousCommand, UserPreferencesService userPreferencesService) {
    return """
      أنت محلل أوامر لتطبيق مساعد طبي.
      مهمتك هي تحليل الأمر الصوتي للمستخدم واستخراج النية والكيانات.

      إذا كان أمر المستخدم متابعة لأمر سابق، فاستخدم سياق الأمر السابق لفهم نية المستخدم.
      على سبيل المثال، إذا كان الأمر السابق هو "جدولة جلسة لجون دو"، وقال المستخدم "أرسل له تأكيدًا"، فيجب أن تفهم أن "له" تشير إلى "جون دو".

      إذا كان المستخدم يفتقد إلى معلومات مطلوبة لأمر ما، فيجب أن تطلبها.
      على سبيل new, if the user says "schedule a session", you should ask "For which patient?".
      The intent in this case should be "ask_for_information", and the "question" entity should contain the question to ask the user.

      إذا كان المستخدم يجري محادثة عادية فقط، فيجب أن تكون النية "conversational_chat" ويجب أن يحتوي كيان "response" على رد ودود ومفيد على رسالة المستخدم.

      يجب أن يكون الإخراج كائن JSON بالبنية التالية:
      {
        "intent": "intent_name",
        "entities": {
          "entity_name": "entity_value",
          ...
        }
      }

      إذا لم تتمكن من تحليل الأمر، فقم بإرجاع خطأ في كائن JSON على هذا النحو:
      {
        "error": "Could not parse command."
      }

      فيما يلي النوايا المحتملة وكياناتها:
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
      - get_time:
        - (no entities)

      تفضيلات المستخدم:
      - مدة الجلسة المفضلة: ${userPreferencesService.getPreferredSessionDuration()} دقائق

      سجل المحادثة:
      ${conversationHistory.join('\n')}

      الأمر السابق:
      ${previousCommand?.intent}
      ${previousCommand?.entities}

      أمر المستخدم: "$command"

      إخراج JSON:
    """;
  }

  Future<String> generateResponse(Command command, String languageCode) async {
    final prompt = languageCode == 'ar'
        ? _buildArabicResponsePrompt(command)
        : _buildEnglishResponsePrompt(command);

    final response = await _geminiService.getGeminiResponse(prompt);
    final jsonResponse =
        response.parts.map((part) => (part as TextPart).text).join('');

    return jsonResponse;
  }

  String _buildEnglishResponsePrompt(Command command) {
    return """
      You are a medical assistant AI.
      Your task is to generate a natural language response to confirm that a command has been executed successfully.

      The executed command is:
      Intent: ${command.intent}
      Entities: ${command.entities}

      Based on this command, generate a friendly and natural confirmation message.
      For example, if the command was to schedule a session for John Doe, a good response would be "OK, I've scheduled a session for John Doe."

      Response:
    """;
  }

  String _buildArabicResponsePrompt(Command command) {
    return """
      أنت مساعد طبي ذكاء اصطناعي.
      مهمتك هي إنشاء استجابة باللغة الطبيعية لتأكيد تنفيذ الأمر بنجاح.

      الأمر الذي تم تنفيذه هو:
      النية: ${command.intent}
      الكيانات: ${command.entities}

      بناءً على هذا الأمر، قم بإنشاء رسالة تأكيد ودية وطبيعية.
      على سبيل المثال، إذا كان الأمر هو جدولة جلسة لجون دو، فإن الرد الجيد هو "حسنًا، لقد قمت بجدولة جلسة لجون دو".

      الاستجابة:
    """;
  }

  Future<String> generateGreeting(String userName, String timeOfDay, String languageCode) async {
    final prompt = languageCode == 'ar' ? _buildArabicGreetingPrompt(userName, timeOfDay) : _buildEnglishGreetingPrompt(userName, timeOfDay);

    final response = await _geminiService.getGeminiResponse(prompt);
    final jsonResponse =
        response.parts.map((part) => (part as TextPart).text).join('');

    return jsonResponse;
  }

  String _buildEnglishGreetingPrompt(String userName, String timeOfDay) {
    return """
    You are a medical assistant AI.
    Your task is to generate a personalized greeting for the user.

    The user's name is $userName.
    The time of day is $timeOfDay.

    Based on this information, generate a friendly and professional greeting.
    For example, "Good morning, Dr. Smith. How can I help you today?"

    Greeting:
  """;
  }

  String _buildArabicGreetingPrompt(String userName, String timeOfDay) {
    return """
    أنت مساعد طبي ذكاء اصطناعي.
    مهمتك هي إنشاء تحية شخصية للمستخدم.

    اسم المستخدم هو $userName.
    وقت اليوم هو $timeOfDay.

    بناءً على هذه المعلومات، قم بإنشاء تحية ودية ومهنية.
    على سبيل المثال، "صباح الخير يا دكتور سميث. كيف يمكنني مساعدتك اليوم؟"

    التحية:
  """;
  }
}
