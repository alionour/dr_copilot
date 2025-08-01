import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/voice_message_model.dart';

/// Widget that displays a conversation message bubble
class ConversationBubbleWidget extends StatelessWidget {
  final VoiceMessageModel? message;
  final String? text;
  final bool isUser;
  final bool isPartial;

  const ConversationBubbleWidget({
    super.key,
    required this.message,
    required this.isUser,
  })  : text = null,
        isPartial = false;

  const ConversationBubbleWidget.partial({
    super.key,
    required this.text,
    required this.isUser,
  })  : message = null,
        isPartial = true;

  @override
  Widget build(BuildContext context) {
    final displayText = isPartial ? text! : message!.content;
    final isError = message?.isError ?? false;
    final isAction = message?.isAction ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _buildAvatar(context, isError: isError, isAction: isAction),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBubbleColor(context, isUser, isError, isAction),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                border: isPartial
                    ? Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                        style: BorderStyle.solid,
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isAction) _buildActionHeader(context),
                  _buildMessageContent(context, displayText, isError, isAction),
                  if (message != null && !isPartial)
                    _buildMessageFooter(context),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, isUser: true),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context,
      {bool isUser = false, bool isError = false, bool isAction = false}) {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;

    if (isUser) {
      iconData = Icons.person;
      backgroundColor = Theme.of(context).colorScheme.secondary;
      iconColor = Theme.of(context).colorScheme.onSecondary;
    } else if (isError) {
      iconData = Icons.error;
      backgroundColor = Theme.of(context).colorScheme.error;
      iconColor = Theme.of(context).colorScheme.onError;
    } else if (isAction) {
      iconData = Icons.settings;
      backgroundColor = Theme.of(context).colorScheme.tertiary;
      iconColor = Theme.of(context).colorScheme.onTertiary;
    } else {
      iconData = Icons.psychology;
      backgroundColor = Theme.of(context).colorScheme.primary;
      iconColor = Theme.of(context).colorScheme.onPrimary;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: backgroundColor,
      child: Icon(
        iconData,
        size: 16,
        color: iconColor,
      ),
    );
  }

  Color _getBubbleColor(
      BuildContext context, bool isUser, bool isError, bool isAction) {
    if (isError) {
      return Theme.of(context).colorScheme.errorContainer;
    }
    if (isAction) {
      return Theme.of(context).colorScheme.tertiaryContainer;
    }
    if (isUser) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  Widget _buildActionHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.smart_toy,
            size: 16,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            'System Action',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
      BuildContext context, String text, bool isError, bool isAction) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: SelectableText(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _getTextColor(context, isUser, isError, isAction),
              fontStyle: isPartial ? FontStyle.italic : null,
            ),
      ),
    );
  }

  Color _getTextColor(
      BuildContext context, bool isUser, bool isError, bool isAction) {
    if (isError) {
      return Theme.of(context).colorScheme.onErrorContainer;
    }
    if (isAction) {
      return Theme.of(context).colorScheme.onTertiaryContainer;
    }
    if (isUser) {
      return Theme.of(context).colorScheme.onPrimaryContainer;
    }
    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  Widget _buildMessageFooter(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (message!.hasAudio)
            Icon(
              Icons.volume_up,
              size: 12,
              color: Theme.of(context).colorScheme.outline,
            ),
          const SizedBox(width: 4),
          Text(
            _formatTimestamp(message!.timestamp.toDate()),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          if (message!.status == VoiceMessageStatus.processing) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
