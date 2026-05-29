import 'dart:convert';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/audio_player_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> message;
  final Function(String) onEdit;
  final String? currentUserPhotoUrl;
  final bool isEditable;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onEdit,
    this.currentUserPhotoUrl,
    this.currentUserDisplayName,
    this.isEditable = true,
  });

  final String? currentUserDisplayName;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isEditing = false;
  late TextEditingController _editingController;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: widget.message['message']);
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectionArea(child: Text('copilotMessageCopied'.tr())),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message["isUser"] as bool;
    final messageText = widget.message["message"] as String?;
    final imageData = widget.message["image"] as String?;
    final messageType = widget.message["type"] as String?;
    final audioUrl = widget.message["url"] as String?;
    final audioDuration = widget.message["duration"] as int?;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (imageData != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: Image.memory(base64Decode(imageData)),
                ),
              ),
            if (messageType == 'audio' &&
                audioUrl != null &&
                audioDuration != null)
              AudioPlayerWidget(
                audioUrl: audioUrl,
                durationInSeconds: audioDuration,
              )
            else if (messageText != null)
              isUser
                  ? _buildUserMessage(context, messageText)
                  : _buildBotMessage(context, messageText),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(BuildContext context, String messageText) {
    final isHovering = ValueNotifier<bool>(false);

    if (_isEditing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: TextFormField(
              controller: _editingController,
              autofocus: true,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              widget.onEdit(_editingController.text);
              setState(() {
                _isEditing = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.cancel),
            onPressed: () {
              setState(() {
                _isEditing = false;
                _editingController.text = messageText;
              });
            },
          ),
        ],
      );
    }

    return MouseRegion(
      onEnter: (_) => isHovering.value = true,
      onExit: (_) => isHovering.value = false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: isHovering,
            builder: (context, hovering, _) {
              return AnimatedOpacity(
                opacity: hovering ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 16),
                      onPressed: () => _copyToClipboard(context, messageText),
                      tooltip: 'copilotCopyMessage'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    if (widget.isEditable)
                      IconButton(
                        icon: const Icon(Icons.edit, size: 16),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        tooltip: 'copilotEditMessage'.tr(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: SelectableText(
                  messageText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8.0),
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              backgroundImage: widget.currentUserPhotoUrl != null
                  ? NetworkImage(widget.currentUserPhotoUrl!)
                  : null,
              child: widget.currentUserPhotoUrl == null
                  ? Text(
                      widget.currentUserDisplayName
                              ?.substring(0, 1)
                              .toUpperCase() ??
                          'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotMessage(BuildContext context, String messageText) {
    final isHovering = ValueNotifier<bool>(false);

    return MouseRegion(
      onEnter: (_) => isHovering.value = true,
      onExit: (_) => isHovering.value = false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar Icon
          Container(
            margin: const EdgeInsetsDirectional.only(end: 12, top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 20,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: MarkdownBody(
                data: messageText,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: GoogleFonts.roboto(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.6,
                  ),
                  pPadding: const EdgeInsets.only(bottom: 12),
                  h1: GoogleFonts.roboto(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                  h2: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                  h3: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.3,
                  ),
                  h1Padding: const EdgeInsets.only(top: 24, bottom: 10),
                  h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
                  h3Padding: const EdgeInsets.only(top: 16, bottom: 6),
                  listBullet: GoogleFonts.roboto(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  listIndent: 20,
                  blockSpacing: 16,
                  blockquotePadding: const EdgeInsets.only(
                    left: 16,
                    top: 12,
                    bottom: 12,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 3),
                    ),
                  ),
                  code: GoogleFonts.sourceCodePro(
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  codeblockPadding: const EdgeInsets.all(16),
                  codeblockDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  strong: GoogleFonts.roboto(fontWeight: FontWeight.bold),
                  em: GoogleFonts.roboto(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ),
          ),
          const SizedBox(width: 4),
          ValueListenableBuilder<bool>(
            valueListenable: isHovering,
            builder: (context, hovering, _) {
              return AnimatedOpacity(
                opacity: hovering ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 16),
                      onPressed: () => _copyToClipboard(context, messageText),
                      tooltip: 'copilotCopyMessage'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 16),
                      onPressed: () {
                        // Regenerate functionality not yet implemented
                      },
                      tooltip: 'copilotRegenerateResponse'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_up_outlined, size: 16),
                      onPressed: () {
                        // Like functionality handled by parent widget
                      },
                      tooltip: 'copilotGoodResponse'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_down_outlined, size: 16),
                      onPressed: () {
                        // Dislike functionality handled by parent widget
                      },
                      tooltip: 'copilotBadResponse'.tr(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
