import 'package:flutter/material.dart';
import 'message_bubble.dart';
import 'empty_chat_placeholder.dart';

class MessageListView extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final Function(String, String) onEdit; // messageId, newText

  const MessageListView({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isLoading,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageBubble(
              message: message,
              onEdit: (newText) {
                onEdit(message['id'], newText);
              },
            );
          },
        ),
        if (messages.isEmpty) const EmptyChatPlaceholder(),
        if (isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
