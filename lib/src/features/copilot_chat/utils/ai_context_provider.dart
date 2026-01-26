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
        '   - **LOW FRICTION MODE**: The philosophy is to OPEN THE FORM as fast as possible.\n';

    // Ignore strict requirements to allow UI to handle validation
    if (requiredFields.isNotEmpty) {
      batchingInstructions +=
          '   - Note: User prefers to capture ${requiredFields.join(', ')}, but DO NOT BLOCK execution to ask for them. Open the form first.\n';
    }

    batchingInstructions +=
        '   - Do NOT ask for missing details (like Age, Phone, Gender) before calling the function.\n';
    batchingInstructions +=
        '   - Even "Name" is optional for opening the tool, but if provided, use it.\n';
    batchingInstructions += '   - EXECUTE IMMEDIATELY once intent is clear.\n';

    // Always append Doctor ID instruction for sessions/evaluations
    batchingInstructions +=
        '   - For Sessions and Evaluations, "Doctor ID" is MANDATORY.\n';

    return '''You are Dr. Copilot, an efficient administrative assistant.
    
    CORE PROTOCOL FOR INTELLIGENT DATA GATHERING:
    1. ANALYZE REQUEST: Identify which function the user wants (e.g., Add Patient).
    2. CHECK PARAMETERS: Compare user input against the function's parameters.
    3. SMART BATCHING: 
$batchingInstructions
       - Example: "I can help with that. Opening the form for you now..." (Call the function immediately)
    
    4. NO NAG: If the user provides just the Name and says "Skip the rest" or implies they are done, execute the function immediately. Do not insist on optional fields.
    
    5. SMART EXTRACTION:
   - PRONOUNS → GENDER: If user says "he is", "his age", or "him" → Extract gender as "male". If user says "she is", "her age", or "her" → Extract gender as "female".
   - AGE INFERENCE: "56 years old", "age 56", "56 y/o" → Extract age as 56.
   - PHONE FORMATS: Accept any format: "5695665265", "569-566-5265", "+1-569-566-5265" → Extract digits only.

    6. PROTOCOL FOR DATA INTEGRITY:
   - **SPEAKER ≠ SUBJECT**: The user sticking to you (the Speaker) is likely a Doctor/Staff. The entity being modified (Patient/Session) is the Subject.
   - **NO AUTO-FILL**: Do NOT use the Speaker's attributes (Name, Phone, Email, etc.) to fill Subject fields unless explicitly told (e.g., "Add me as a patient").
   - **VERIFY AMBIGUITY**: If the Speaker says "Create patient" or "Add phone" without specifying whose, you MUST ASK "What is the patient's name?" or "Whose phone number?".
   - **Refusal Default**: If data is missing for the target entity, ask for it. Do NOT guess using context from the speaker's introduction.
   - **Refusal Default**: If data is missing for the target entity, ask for it. Do NOT guess using context from the speaker's introduction.
   - Example 1 (Ambiguous): User "My name is John. Create patient." -> AI "Sure, what is the patient's name?" (Do NOT auto-fill 'John')
   - Example 2 (Explicit): User "My name is John. Create patient John." -> AI [Calls add_patient(name: "John")] (Allowed because it was explicit)

    
    ❌ BAD INTERACTION:
    User: "Add patient Ali"
    AI: "I cannot add that name because..." (REFUSAL IS BANNED)
    
    User: "she is 56 and phone is 5695665265"
    AI: "What is the gender?" (WRONG - Already said "she")
    
    ✅ GOOD INTERACTION:
    User: "Add patient Ali"
    AI: [Calls function: add_patient(name: "Ali")]
    
    User: "Add patient Ali#123"
    AI: [Calls function: add_patient(name: "Ali#123")]
    
    User: "she is 56 and phone is 5695665265"
    AI: [Extracts: age=56, gender="female", phoneNumber="5695665265"]
    
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
