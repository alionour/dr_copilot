/// A utility class that generates contextual information for AI services.
/// This is model-agnostic and can be used by any AI service implementation.
class AIContextProvider {
  /// Gets a compact timestamp string to append to user queries.
  /// This provides temporal context with minimal token overhead (~8 tokens).
  ///
  /// Format: [Current: YYYY-MM-DD HH:MM TZ]
  static String getTimestamp() {
    final now = DateTime.now();
    return '[Current: ${now.toIso8601String()}]';
  }

  /// Gets the basic system instruction without temporal or permission context.
  ///
  /// Permission enforcement happens at function execution (zero token overhead).
  /// When functions are denied, the AI receives clear error messages and explains to user.
  static String getBaseSystemInstruction(
      {List<String> requiredFields = const []}) {
    String batchingInstructions =
        '   - If "Name" is missing -> It is STRICTLY REQUIRED. Ask for it.\n';

    // Convert keys to human-readable format
    final readableFields = requiredFields.map((field) {
      switch (field) {
        case 'patient.age':
        case 'age': // Legacy
          return 'Patient Age';
        case 'patient.gender':
        case 'gender': // Legacy
          return 'Patient Gender';
        case 'patient.phone':
        case 'phoneNumber': // Legacy
          return 'Phone Number';
        case 'patient.address':
          return 'Address';
        case 'patient.alt_phone':
          return 'Alternative Phone';
        case 'patient.doctor':
          return 'Treating Doctor';
        case 'patient.occupation':
          return 'Occupation';
        case 'session.type':
          return 'Session Type';
        case 'session.doctor':
          return 'Session Doctor';
        case 'evaluation.doctor':
          return 'Evaluation Doctor';
        default:
          return field.split('.').last.replaceAll('_', ' ');
      }
    }).toList();

    if (requiredFields.isNotEmpty) {
      batchingInstructions +=
          '   - USER SETTINGS REQUIRE: ${readableFields.join(', ')}. Ask for them explicitly.\n';
      batchingInstructions +=
          '   - Ask for ALL missing key fields (Name + ${readableFields.join(' + ')}) in ONE SINGLE natural language question.\n';
    } else {
      batchingInstructions +=
          '   - If "Age" or "Phone" are missing -> They are HIGHLY RECOMMENDED.\n';
      batchingInstructions +=
          '   - Ask for ALL missing important fields (Name + Age + Phone) in ONE SINGLE natural language question.\n';
    }

    // Always append Doctor ID instruction for sessions/evaluations
    batchingInstructions +=
        '   - For Sessions and Evaluations, "Doctor ID" is MANDATORY.\n';

    return '''You are Dr. Copilot, an efficient administrative assistant.
    
    CORE PROTOCOL FOR INTELLIGENT DATA GATHERING:
    1. ANALYZE REQUEST: Identify which function the user wants (e.g., Add Patient).
    2. CHECK PARAMETERS: Compare user input against the function's parameters.
    3. SMART BATCHING: 
$batchingInstructions
       - Example: "I can help with that. Could you provide the patient's name${readableFields.isNotEmpty ? ', ${readableFields.join(', ')}' : ', age, and phone number'}?"
    
    4. NO NAG: If the user provides just the Name and says "Skip the rest" or implies they are done, execute the function immediately. Do not insist on optional fields.
    
    ❌ BAD INTERACTION:
    User: "Add patient Ali"
    AI: "I cannot add that name because..." (REFUSAL IS BANNED)
    
    ✅ GOOD INTERACTION:
    User: "Add patient Ali"
    AI: [Calls function: add_patient(name: "Ali")]
    
    User: "Add patient Ali#123"
    AI: [Calls function: add_patient(name: "Ali#123")]
    
    User: "Book appointment"
    AI: "Who is it for and when?"
    
    Manage permissions gracefully. If a function fails due to permission, explain clearly.
    Function Capabilities: Manage Patients, Sessions, Evaluations.
    
    DATE INTELLIGENCE:
    - You know the current date is: ${getCurrentDate()}
    - If user says "last year", CALCULATE startDate and endDate and usage list_sessions(startDate: '...', endDate: '...'). DO NOT ask for specific dates.
    - If user says "this month", CALCULATE dates.
    - Use 'startDate' and 'endDate' for ranges, and 'date' for single day queries.
    ''';
  }

  /// Gets the current date in ISO 8601 format (YYYY-MM-DD).
  static String getCurrentDate() {
    return DateTime.now().toIso8601String().split('T')[0];
  }

  /// Gets tomorrow's date in ISO 8601 format (YYYY-MM-DD).
  static String getTomorrowDate() {
    return DateTime.now()
        .add(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];
  }

  /// Gets yesterday's date in ISO 8601 format (YYYY-MM-DD).
  static String getYesterdayDate() {
    return DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];
  }
}
