import 'dart:math';

class RandomResponse {
  static final List<String> _responses = [
    "Based on the patient's symptoms, it is recommended to conduct a blood test.",
    "The patient might be experiencing side effects from their current medication.",
    "Consider scheduling a follow-up appointment to monitor the patient's progress.",
    "It is advisable to refer the patient to a specialist for further evaluation.",
    "The patient's condition seems stable, continue with the current treatment plan.",
    "Recommend the patient to maintain a healthy diet and regular exercise.",
    "The symptoms described could be indicative of an underlying condition.",
    "Ensure the patient is adhering to their prescribed medication regimen.",
    "Suggest the patient to keep a symptom diary for better diagnosis.",
    "Advise the patient to avoid any known allergens or triggers."
  ];

  static String getRandomResponse() {
    final random = Random();
    return _responses[random.nextInt(_responses.length)];
  }
}
