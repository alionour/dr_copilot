import 'package:dr_copilot/src/features/team_chat/presentation/widgets/team_chat_list_view.dart';

class TeamChatMockData {
  static List<TeamChatConversation> generateMockConversations() {
    final now = DateTime.now();

    return [
      TeamChatConversation(
        id: 'conv_001',
        title: 'Clinical Team',
        lastMessage: 'Meeting at 3 PM today',
        lastMessageTime: now.subtract(const Duration(minutes: 5)),
        isDirectMessage: false,
      ),
      TeamChatConversation(
        id: 'conv_002',
        title: 'Dr. Sarah Williams',
        lastMessage: 'Patient progress looks good',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        isDirectMessage: true,
      ),
      TeamChatConversation(
        id: 'conv_003',
        title: 'Admin Team',
        lastMessage: 'Billing updates are ready',
        lastMessageTime: now.subtract(const Duration(hours: 5)),
        isDirectMessage: false,
      ),
      TeamChatConversation(
        id: 'conv_004',
        title: 'Dr. Michael Chen',
        lastMessage: 'Can you review the case notes?',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        isDirectMessage: true,
      ),
      TeamChatConversation(
        id: 'conv_005',
        title: 'Therapy Group',
        lastMessage: 'Next session scheduled for Friday',
        lastMessageTime: now.subtract(const Duration(days: 1, hours: 3)),
        isDirectMessage: false,
      ),
      TeamChatConversation(
        id: 'conv_006',
        title: 'Nurse Emily Brown',
        lastMessage: 'Medication reminders sent',
        lastMessageTime: now.subtract(const Duration(days: 2)),
        isDirectMessage: true,
      ),
      TeamChatConversation(
        id: 'conv_007',
        title: 'Case Review Team',
        lastMessage: 'Weekly review tomorrow at 10 AM',
        lastMessageTime: now.subtract(const Duration(days: 2, hours: 5)),
        isDirectMessage: false,
      ),
      TeamChatConversation(
        id: 'conv_008',
        title: 'Dr. James Lee',
        lastMessage: 'Thanks for the consultation',
        lastMessageTime: now.subtract(const Duration(days: 3)),
        isDirectMessage: true,
      ),
      TeamChatConversation(
        id: 'conv_009',
        title: 'Emergency Response',
        lastMessage: 'Crisis protocol updated',
        lastMessageTime: now.subtract(const Duration(days: 4)),
        isDirectMessage: false,
      ),
      TeamChatConversation(
        id: 'conv_010',
        title: 'Receptionist Lisa',
        lastMessage: 'Appointment confirmations complete',
        lastMessageTime: now.subtract(const Duration(days: 5)),
        isDirectMessage: true,
      ),
    ];
  }
}
