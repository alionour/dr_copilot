import 'package:flutter/material.dart';
import 'message_bubble.dart';
import 'empty_chat_placeholder.dart';

class MessageListView extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> messages;
  final bool isLoading;
  final Function(String, String) onEdit; // messageId, newText
  final String? currentUserPhotoUrl;
  final String? currentUserDisplayName;
  final List<String>? userPermissions;
  final Function(bool isLike, String messageId) onFeedback;

  const MessageListView({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.isLoading,
    required this.onEdit,
    required this.onFeedback,
    this.currentUserPhotoUrl,
    this.currentUserDisplayName,
    this.userPermissions,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          controller: scrollController,
          itemCount: messages.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            // Show typing indicator as last item
            if (index == messages.length && isLoading) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.smart_toy,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypingDot(delay: 0),
                          const SizedBox(width: 4),
                          _TypingDot(delay: 200),
                          const SizedBox(width: 4),
                          _TypingDot(delay: 400),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final message = messages[index];
            final isLastMessage = index == messages.length - 1;
            return MessageBubble(
              message: message,
              isLastMessage: isLastMessage,
              currentUserPhotoUrl: currentUserPhotoUrl,
              currentUserDisplayName: currentUserDisplayName,
              onEdit: (newText) {
                onEdit(message['id'], newText);
              },
              onFeedback: onFeedback,
            );
          },
        ),
        if (messages.isEmpty && !isLoading)
          EmptyChatPlaceholder(userPermissions: userPermissions),
      ],
    );
  }
}

/// Animated dot for typing indicator
class _TypingDot extends StatefulWidget {
  final int delay;

  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
