class CopilotMockData {
  static List<Map<String, dynamic>> generateMockMessages() {
    return [
      {
        "isUser": true,
        "message": "Show me the schedule for today.",
      },
      {
        "isUser": false,
        "message":
            "Here are your appointments for today:\n\n1. 09:00 AM - Sarah Jones (Therapy Session)\n2. 10:30 AM - Mike Ross (Follow-up)\n3. 02:00 PM - John Doe (Initial Evaluation)\n\nWould you like to prepare for the first session?",
      },
      {
        "isUser": true,
        "message": "Yes, show me Sarah's last session notes.",
      },
      {
        "isUser": false,
        "message":
            "I found the notes from Sarah's last session on Dec 15th. She reported feeling improved anxiety levels but mentioned sleep struggles. \n\nLast homework assigned: 'Sleep hygiene log'.",
      },
    ];
  }
}
