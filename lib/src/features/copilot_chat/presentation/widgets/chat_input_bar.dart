import 'dart:typed_data';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueNotifier<bool> isButtonEnabled;
  final Uint8List? pickedImage;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final VoidCallback onCancelImage;
  final VoidCallback onNewChat;
  final String selectedModel;
  final List<String> availableModels;
  final bool isModelChoiceEnabled;
  final ValueChanged<String?> onModelChanged;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isButtonEnabled,
    required this.pickedImage,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onCancelImage,
    required this.onNewChat,
    required this.selectedModel,
    required this.availableModels,
    required this.isModelChoiceEnabled,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            height: MediaQuery.of(context).size.height * 0.08,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                if (pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        SizedBox(
                          height: 60,
                          width: 60,
                          child: Image.memory(pickedImage!),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onCancelImage,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(
                                  Icons.cancel,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: "messageDrCopilot".tr(),
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (value) {
                        onSendMessage();
                      },
                    ),
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: isButtonEnabled,
                  builder: (context, isEnabled, child) {
                    return IconButton(
                      onPressed: isEnabled ? onSendMessage : null,
                      icon: const Icon(Icons.send),
                      color: isEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    );
                  },
                ),
                IconButton(
                  onPressed: onNewChat,
                  icon: const Icon(Icons.add),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                IconButton(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                IconButton(
                  onPressed: () {
                    context.go('/live_assistant');
                  },
                  icon: const Icon(Icons.mic),
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                DropdownButton<String>(
                  value: selectedModel,
                  onChanged: isModelChoiceEnabled ? onModelChanged : null,
                  items: availableModels.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

