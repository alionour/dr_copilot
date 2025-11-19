import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  final String apiKey;
  late final GenerativeModel _model;

  GeminiService(this.apiKey) {
    final addPatientTool = Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'add_patient',
          'Adds a new patient to the system.',
          Schema(
            SchemaType.object,
            properties: {
              'name': Schema(SchemaType.string, description: 'The name of the patient.'),
              'age': Schema(SchemaType.integer, description: 'The age of the patient.'),
              'gender': Schema(SchemaType.string, description: 'The gender of the patient.'),
              'address': Schema(SchemaType.string, description: 'The address of the patient.'),
              'phoneNumber': Schema(SchemaType.string, description: 'The phone number of the patient.'),
              'alternativePhoneNumber': Schema(SchemaType.string, description: 'The alternative phone number of the patient.'),
              'treatingDoctor': Schema(SchemaType.string, description: 'The name of the treating doctor.'),
              'occupation': Schema(SchemaType.string, description: 'The occupation of the patient.'),
            },
            requiredProperties: ['name'],
          ),
        ),
        FunctionDeclaration(
          'edit_patient',
          'Edits an existing patient\'s information.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the patient to edit.'),
              'name': Schema(SchemaType.string, description: 'The new name of the patient.'),
              'age': Schema(SchemaType.integer, description: 'The new age of the patient.'),
              'gender': Schema(SchemaType.string, description: 'The new gender of the patient.'),
              'address': Schema(SchemaType.string, description: 'The new address of the patient.'),
              'phoneNumber': Schema(SchemaType.string, description: 'The new phone number of the patient.'),
              'alternativePhoneNumber': Schema(SchemaType.string, description: 'The new alternative phone number of the patient.'),
              'treatingDoctor': Schema(SchemaType.string, description: 'The new name of the treating doctor.'),
              'occupation': Schema(SchemaType.string, description: 'The new occupation of the patient.'),
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'delete_patient',
          'Deletes a patient from the system.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the patient to delete.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'add_session',
          'Adds a new session for a patient.',
          Schema(
            SchemaType.object,
            properties: {
              'patientId': Schema(SchemaType.string, description: 'The ID of the patient for whom the session is being added.'),
              'price': Schema(SchemaType.number, format: 'double', description: 'The price of the session.'),
              'startDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The start date and time of the session in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The end date and time of the session in ISO 8601 format.'),
              'sessionType': Schema(SchemaType.string, description: 'The type of the session (e.g., \'pediatricIntensive\', \'adultIntensive\', \'standard\', \'traction\').'),
              'patientName': Schema(SchemaType.string, description: 'The name of the patient.'),
              'doctorId': Schema(SchemaType.string, description: 'The ID of the doctor for the session.')
            },
            requiredProperties: ['patientId', 'price', 'startDateTime', 'endDateTime'],
          ),
        ),
        FunctionDeclaration(
          'edit_session',
          'Edits an existing session\'s information.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the session to edit.'),
              'patientId': Schema(SchemaType.string, description: 'The ID of the patient for whom the session is being updated.'),
              'price': Schema(SchemaType.number, format: 'double', description: 'The new price of the session.'),
              'startDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The new start date and time of the session in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The new end date and time of the session in ISO 8601 format.'),
              'sessionType': Schema(SchemaType.string, description: 'The new type of the session (e.g., \'pediatricIntensive\', \'adultIntensive\', \'standard\', \'traction\').'),
              'patientName': Schema(SchemaType.string, description: 'The new name of the patient.'),
              'doctorId': Schema(SchemaType.string, description: 'The new ID of the doctor for the session.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'delete_session',
          'Deletes a session from the system.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the session to delete.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'add_evaluation',
          'Adds a new evaluation for a patient.',
          Schema(
            SchemaType.object,
            properties: {
              'patientId': Schema(SchemaType.string, description: 'The ID of the patient for whom the evaluation is being added.'),
              'patientName': Schema(SchemaType.string, description: 'The name of the patient for whom the evaluation is being added.'),
              'price': Schema(SchemaType.number, format: 'double', description: 'The price of the evaluation.'),
              'startDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The start date and time of the evaluation in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The end date and time of the evaluation in ISO 8601 format.'),
              'doctorId': Schema(SchemaType.string, description: 'The ID of the doctor for the evaluation.')
            },
            requiredProperties: ['patientId', 'patientName', 'price', 'startDateTime', 'endDateTime'],
          ),
        ),
        FunctionDeclaration(
          'edit_evaluation',
          'Edits an existing evaluation\'s information.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the evaluation to edit.'),
              'patientId': Schema(SchemaType.string, description: 'The ID of the patient for whom the evaluation is being updated.'),
              'patientName': Schema(SchemaType.string, description: 'The new name of the patient for whom the evaluation is being updated.'),
              'price': Schema(SchemaType.number, format: 'double', description: 'The new price of the evaluation.'),
              'startDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The new start date and time of the evaluation in ISO 8601 format.'),
              'endDateTime': Schema(SchemaType.string, format: 'date-time', description: 'The new end date and time of the evaluation in ISO 8601 format.'),
              'doctorId': Schema(SchemaType.string, description: 'The new ID of the doctor for the evaluation.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'delete_evaluation',
          'Deletes an evaluation from the system.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the evaluation to delete.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'get_patient',
          'Retrieves a patient\'s information by their ID or name.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the patient to retrieve.'),
              'name': Schema(SchemaType.string, description: 'The name of the patient to retrieve.')
            },
          ),
        ),
        FunctionDeclaration(
          'list_patients',
          'Lists patients, optionally filtered by name.',
          Schema(
            SchemaType.object,
            properties: {
              'name': Schema(SchemaType.string, description: 'Optional: The name or partial name to filter patients by.')
            },
          ),
        ),
        FunctionDeclaration(
          'get_session',
          'Retrieves a session\'s information by its ID.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the session to retrieve.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'list_sessions',
          'Lists sessions, optionally filtered by patient name or date.',
          Schema(
            SchemaType.object,
            properties: {
              'patientName': Schema(SchemaType.string, description: 'Optional: The name or partial name of the patient to filter sessions by.'),
              'date': Schema(SchemaType.string, format: 'date', description: 'Optional: The date to filter sessions by (e.g., \'YYYY-MM-DD\').')
            },
          ),
        ),
        FunctionDeclaration(
          'get_evaluation',
          'Retrieves an evaluation\'s information by its ID.',
          Schema(
            SchemaType.object,
            properties: {
              'id': Schema(SchemaType.string, description: 'The ID of the evaluation to retrieve.')
            },
            requiredProperties: ['id'],
          ),
        ),
        FunctionDeclaration(
          'list_evaluations',
          'Lists evaluations, optionally filtered by patient name or date.',
          Schema(
            SchemaType.object,
            properties: {
              'patientName': Schema(SchemaType.string, description: 'Optional: The name or partial name of the patient to filter evaluations by.'),
              'date': Schema(SchemaType.string, format: 'date', description: 'Optional: The date to filter evaluations by (e.g., \'YYYY-MM-DD\').')
            },
          ),
        ),
      ],
    );

    _model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: apiKey,
      tools: [addPatientTool],
      systemInstruction: Content.text(
          'You are Dr. Copilot, an advanced AI medical manager designed to assist healthcare professionals. Your core responsibilities include providing accurate medical information, efficiently managing patient records, and handling appointments and evaluations. You can execute specific functions within the application, such as adding, editing, or deleting patient profiles, scheduling and modifying sessions, and managing evaluations. When a user requests a function, you will proactively confirm the action and gather any necessary missing details through a conversational interface before proceeding. You are also capable of discussing patient-specific information and retrieving relevant data based on various criteria like name, ID, or date. Your goal is to streamline administrative tasks and enhance clinical decision-making.'),
    );
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
