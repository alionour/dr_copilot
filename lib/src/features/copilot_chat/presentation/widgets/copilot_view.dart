import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/message_list_view.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/pages/live_chat_page.dart';
import 'package:go_router/go_router.dart';

enum CopilotMicState {
  idle,
  requestingPermission,
  initializing,
  listening,
  finalizing,
  error,
}

class CopilotView extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final TextEditingController textController;
  final ScrollController scrollController;
  final bool isButtonEnabled;
  final bool isRecording;
  final CopilotMicState micState;
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
  final VoidCallback onStopGeneration; // Stop AI generation
  final Function(bool) onHistoryToggle; // Alternative if state passed down
  final Function(String, String) onEditMessage;

  final VoidCallback? onSpeechToggle;

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
    this.micState = CopilotMicState.idle,
    this.isLoading = false,
    required this.currentTier,
    required this.tokenUsage,
    required this.tokenLimit,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onCancelImage,
    required this.onToggleHistory,
    required this.onStopGeneration,
    required this.onHistoryToggle,
    required this.onEditMessage,
    this.onSpeechToggle,
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
    final colorScheme = Theme.of(context).colorScheme;
    final micButton = _buildMicButton(context, colorScheme);

    return Scaffold(
      appBar: AppBar(
        title: Text('copilotChat'.tr()),
        leading: const Icon(Icons.chat_outlined),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'chatHistory'.tr(),
            onPressed: onToggleHistory,
          ),
          IconButton(
            icon: const Icon(Icons.graphic_eq),
            tooltip: 'liveChat'.tr(),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LiveChatPage()),
              );
            },
          ),
          navMenuButton ?? const SizedBox(),
        ],
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
                      'monthlyTokens'.tr(args: [numberFormat.format(tokenUsage), numberFormat.format(tokenLimit)]),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 700;
                final chatArea = Column(
                  children: <Widget>[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
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
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: tokenUsage >= tokenLimit
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_outline,
                                          color: colorScheme.error),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'monthlyQuotaExceeded'.tr(),
                                          style: TextStyle(
                                            color: colorScheme.error,
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
                                          backgroundColor: colorScheme.primary,
                                          foregroundColor:
                                              colorScheme.onPrimary,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16),
                                        ),
                                        child: Text('upgrade'.tr()),
                                      ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      if (pickedImage != null)
                                        Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(end: 8.0),
                                          child: Stack(
                                            children: [
                                              SizedBox(
                                                height: 60,
                                                width: 60,
                                                child:
                                                    Image.memory(pickedImage!),
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
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(2.0),
                                                      child: Icon(
                                                        Icons.cancel_outlined,
                                                        color: colorScheme.error,
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
                                            enabled: !isLoading &&
                                                micState !=
                                                    CopilotMicState.finalizing,
                                            // focusNode: _focusNode,
                                            decoration: InputDecoration(
                                              hintText: "messageDrCopilot".tr(),
                                              border: InputBorder.none,
                                              hintStyle: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                            ),
                                            maxLines: 1,
                                            textInputAction:
                                                TextInputAction.send,
                                            onFieldSubmitted: (value) =>
                                                isLoading
                                                    ? null
                                                    : onSendMessage(),
                                          ),
                                        ),
                                      ),
                                      // Send / Stop / Mic buttons
                                      if (isLoading)
                                        IconButton(
                                          onPressed: onStopGeneration,
                                          icon: const Icon(Icons.stop_circle),
                                          color: colorScheme.error,
                                          tooltip: 'stopGenerating'.tr(),
                                        )
                                      else if (textController.text.isNotEmpty ||
                                          pickedImage != null)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              onPressed: onSendMessage,
                                              icon: const Icon(Icons.send),
                                              color: colorScheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            micButton,
                                          ],
                                        )
                                      else
                                        micButton,
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                if (!isCompact) {
                  return Row(
                    children: [
                      Expanded(child: chatArea),
                      if (isSidebarVisible && conversationSidebar != null)
                        conversationSidebar!,
                    ],
                  );
                }

                return Stack(
                  children: [
                    Positioned.fill(child: chatArea),
                    if (isSidebarVisible && conversationSidebar != null) ...[
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onToggleHistory,
                          child: ColoredBox(
                            color: Colors.black.withValues(alpha: 0.32),
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: SafeArea(
                          top: false,
                          child: conversationSidebar!,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicButton(BuildContext context, ColorScheme colorScheme) {
    final isListening = micState == CopilotMicState.listening;
    final isBusy = micState == CopilotMicState.requestingPermission ||
        micState == CopilotMicState.initializing ||
        micState == CopilotMicState.finalizing;

    final tooltip = switch (micState) {
      CopilotMicState.requestingPermission => 'checkingMicPermission'.tr(),
      CopilotMicState.initializing => 'startingMic'.tr(),
      CopilotMicState.listening => 'stopDictation'.tr(),
      CopilotMicState.finalizing => 'finishingDictation'.tr(),
      CopilotMicState.error => 'micError'.tr(),
      CopilotMicState.idle => 'startDictation'.tr(),
    };

    final icon = isBusy
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colorScheme.primary,
            ),
          )
        : Icon(
            isListening ? Icons.stop_circle_outlined : Icons.mic_none,
            color: switch (micState) {
              CopilotMicState.listening => colorScheme.error,
              CopilotMicState.error => colorScheme.error,
              _ => colorScheme.onSurfaceVariant,
            },
          );

    return AnimatedScale(
      scale: isListening ? 1.08 : 1,
      duration: const Duration(milliseconds: 180),
      child: IconButton(
        onPressed: isBusy ? null : onSpeechToggle,
        icon: icon,
        tooltip: tooltip,
      ),
    );
  }
}
