import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/message_list_view.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CopilotView extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final TextEditingController textController;
  final ScrollController scrollController;
  final bool isButtonEnabled;
  final bool isRecording;
  final bool isListeningSpeech;
  final bool isLoading;

  // Subscription / Quota Props
  final SubscriptionTier currentTier;
  final int tokenUsage;
  final int tokenLimit;

  // Interaction Callbacks
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onCancelImage;
  final VoidCallback onToggleHistory; // For sidebar toggle
  final Function(bool) onHistoryToggle; // Alternative if state passed down
  final Function(String, String) onEditMessage;

  // Voice Callbacks (assume handled by parent or just void placeholders for view)
  final VoidCallback? onSpeechStart;
  final VoidCallback? onSpeechStop;

  final Uint8List? pickedImage;
  final Widget? navMenuButton;
  final Widget? conversationSidebar; // Added sidebar widget
  final bool isSidebarVisible; // Added visibility flag
  final String? currentUserPhotoUrl;
  final String? currentUserDisplayName;
  final List<String>?
      userPermissions; // User's permissions for capability display

  const CopilotView({
    super.key,
    required this.messages,
    required this.textController,
    required this.scrollController,
    required this.isButtonEnabled,
    this.isRecording = false,
    this.isListeningSpeech = false,
    this.isLoading = false,
    required this.currentTier,
    required this.tokenUsage,
    required this.tokenLimit,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onCancelImage,
    required this.onToggleHistory,
    required this.onHistoryToggle,
    required this.onEditMessage,
    this.onSpeechStart,
    this.onSpeechStop,
    this.pickedImage,
    this.navMenuButton,
    this.conversationSidebar,
    this.isSidebarVisible = false,
    this.currentUserPhotoUrl,
    this.currentUserDisplayName,
    this.userPermissions,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.compact();

    return Scaffold(
      appBar: AppBar(
        title: Text('copilotChat'.tr()),
        leading: const Icon(Icons.chat_outlined),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: onToggleHistory,
          ),
          navMenuButton ?? const SizedBox(),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                // Token usage row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.token,
                      size: 16,
                      color: tokenUsage >= tokenLimit
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Tokens: ${numberFormat.format(tokenUsage)} / ${numberFormat.format(tokenLimit)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: tokenUsage >= tokenLimit
                                ? Theme.of(context).colorScheme.error
                                : null,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Chat Area
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: MessageListView(
                              scrollController: scrollController,
                              messages: messages,
                              isLoading: isLoading,
                              onEdit: onEditMessage,
                              currentUserPhotoUrl: currentUserPhotoUrl,
                              currentUserDisplayName: currentUserDisplayName,
                              userPermissions: userPermissions,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              height: MediaQuery.of(context).size.height * 0.08,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: tokenUsage >= tokenLimit
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.lock_outline,
                                            color: Colors.red),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Monthly quota exceeded. Upgrade to continue.',
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () {
                                            context
                                                .push('/settings/subscription');
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            foregroundColor: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                          ),
                                          child: const Text('Upgrade'),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        if (pickedImage != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Stack(
                                              children: [
                                                SizedBox(
                                                  height: 60,
                                                  width: 60,
                                                  child: Image.memory(
                                                      pickedImage!),
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap: onCancelImage,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      child: const Padding(
                                                        padding:
                                                            EdgeInsets.all(2.0),
                                                        child: Icon(
                                                          Icons.cancel_outlined,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                            child: TextFormField(
                                              controller: textController,
                                              // focusNode: _focusNode,
                                              decoration: InputDecoration(
                                                hintText:
                                                    "messageDrCopilot".tr(),
                                                border: InputBorder.none,
                                                hintStyle: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                              maxLines: 1,
                                              textInputAction:
                                                  TextInputAction.send,
                                              onFieldSubmitted: (value) =>
                                                  onSendMessage(),
                                            ),
                                          ),
                                        ),
                                        // Send / Mic buttons
                                        if (textController.text.isNotEmpty ||
                                            pickedImage != null)
                                          IconButton(
                                            onPressed: onSendMessage,
                                            icon: const Icon(Icons.send),
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          )
                                        else
                                          GestureDetector(
                                            onLongPressStart: (_) =>
                                                onSpeechStart?.call(),
                                            onLongPressEnd: (_) =>
                                                onSpeechStop?.call(),
                                            child: Icon(Icons.mic,
                                                color: isListeningSpeech
                                                    ? Colors.red
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant),
                                          ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Sidebar logic handled by parent (if visible, show it).
                if (isSidebarVisible && conversationSidebar != null)
                  conversationSidebar!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
