import 'package:flutter/material.dart';

class TeamChatListView extends StatelessWidget {
  final List<TeamChatConversation> conversations;
  final VoidCallback? onAddChat;
  final Function(String) onConversationTap;

  const TeamChatListView({
    super.key,
    required this.conversations,
    this.onAddChat,
    required this.onConversationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Chat'),
        leading: const Icon(Icons.chat_outlined),
      ),
      floatingActionButton: onAddChat != null
          ? FloatingActionButton(
              onPressed: onAddChat,
              child: const Icon(Icons.add),
            )
          : null,
      body: conversations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('No chats yet'),
                  if (onAddChat != null)
                    TextButton(
                      onPressed: onAddChat,
                      child: const Text('Start New Chat'),
                    ),
                ],
              ),
            )
          : ListView.separated(
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: conversation.isDirectMessage
                        ? const Icon(Icons.person_outline)
                        : const Icon(Icons.group_outlined),
                  ),
                  title: Text(conversation.title),
                  subtitle: conversation.lastMessage != null
                      ? Text(
                          conversation.lastMessage!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: conversation.lastMessageTime != null
                      ? Text(
                          _formatTime(conversation.lastMessageTime!),
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  onTap: () => onConversationTap(conversation.id),
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Simple model for team chat conversations
class TeamChatConversation {
  final String id;
  final String title;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final bool isDirectMessage;

  const TeamChatConversation({
    required this.id,
    required this.title,
    this.lastMessage,
    this.lastMessageTime,
    this.isDirectMessage = false,
  });
}
