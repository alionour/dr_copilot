import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart'
    as custom;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:markdown/markdown.dart' show markdownToHtml;

class CopilotPage extends StatefulWidget {
  const CopilotPage({super.key, required this.title});

  final String title;

  @override
  State<CopilotPage> createState() => _CopilotPageState();
}

class _CopilotPageState extends State<CopilotPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isButtonEnabled = ValueNotifier(false);
  final List<Map<String, dynamic>> _messages = [];
  String _selectedModel = 'Gemini';
  final bool _isModelChoiceEnabled = true;
  Uint8List? _pickedImage;

  final List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _isButtonEnabled.value =
          _controller.text.isNotEmpty || _pickedImage != null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _initializeAvailableModels();
    _loadCachedMessages();
  }

  void _initializeAvailableModels() {
    if (ApiKeyHelper.vertexAIKey.isNotEmpty) _availableModels.add('MedPaLM');
    if (ApiKeyHelper.gptKey.isNotEmpty) _availableModels.add('GPT');
    if (ApiKeyHelper.geminiKey.isNotEmpty) _availableModels.add('Gemini');
    if (ApiKeyHelper.deepSeekKey.isNotEmpty) _availableModels.add('DeepSeek');
    if (ApiKeyHelper.qwenKey.isNotEmpty) _availableModels.add('Qwen');
    if (ApiKeyHelper.claudeKey.isNotEmpty) _availableModels.add('Claude');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _isButtonEnabled.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _pickedImage = result.files.first.bytes;
      });
    }
  }

  void _cancelImage() {
    setState(() {
      _pickedImage = null;
      _isButtonEnabled.value = _controller.text.isNotEmpty;
    });
  }

  void _sendMessage() {
    if (_pickedImage != null && _controller.text.isNotEmpty) {
      setState(() {
        _messages.add({
          "isUser": true,
          "message": _controller.text,
          "image": base64Encode(_pickedImage!)
        });
      });
      context.read<CopilotBloc>().add(UploadImageEvent(
          selectedModel: _selectedModel,
          imageBytes: _pickedImage!,
          text: _controller.text));
      setState(() {
        _pickedImage = null;
      });
    } else if (_controller.text.isNotEmpty) {
      setState(() {
        _messages.add({"isUser": true, "message": _controller.text});
      });
      context.read<CopilotBloc>().add(GenerateResponseEvent(
          query: _controller.text, selectedModel: _selectedModel));
    }
    _controller.clear();
    _scrollToBottom();
    context.read<CopilotBloc>().add(CacheMessagesEvent(_messages));
  }

  void _loadCachedMessages() {
    context.read<CopilotBloc>().add(LoadCachedMessagesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: BlocListener<CopilotBloc, CopilotState>(
                  listener: (context, state) {
                    if (state is CopilotResponseGenerated) {
                      if (state.response is custom.GeminiResponse) {
                        final geminiResponse =
                            state.response as custom.GeminiResponse;
                        _showTypingEffect(geminiResponse.parts.last is TextPart
                            ? (geminiResponse.parts.last as TextPart).text
                            : geminiResponse.parts.last.toString());
                      } else {
                        _showTypingEffect(state.response.toString());
                      }
                    } else if (state is CopilotError) {
                      setState(() {
                        _messages.add({
                          "isUser": false,
                          "message": 'Error: ${state.error}'
                        });
                      });
                      _scrollToBottom();
                      context
                          .read<CopilotBloc>()
                          .add(CacheMessagesEvent(_messages));
                    } else if (state is CachedMessagesLoaded) {
                      setState(() {
                        _messages.addAll(state.messages);
                      });
                      _scrollToBottom();
                    } else if (state is NewChatStarted) {
                      setState(() {
                        _messages.clear();
                      });
                    }
                  },
                  child: BlocBuilder<CopilotBloc, CopilotState>(
                    builder: (context, state) {
                      return Stack(
                        children: [
                          ListView.builder(
                            controller: _scrollController,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Align(
                                  alignment: message["isUser"]
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: message["isUser"]
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (message["image"] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 8.0),
                                          child: SizedBox(
                                            height: 100, // Smaller height
                                            width: 100, // Smaller width
                                            child: Image.memory(
                                                base64Decode(message["image"])),
                                          ),
                                        ),
                                      message["isUser"]
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0xFFF0F0F0), // Light grey background
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10.0),
                                                  ),
                                                  child: Text(
                                                    message["message"],
                                                    style: TextStyle(
                                                      fontSize:
                                                          16, // Larger font size
                                                      fontWeight: FontWeight
                                                          .bold, // Bold text
                                                      foreground: Paint()
                                                        ..shader =
                                                            const LinearGradient(
                                                          colors: <Color>[
                                                            Color(
                                                                0xFF6A11CB), // Gradient start color
                                                            Color(
                                                                0xFF2575FC), // Gradient end color
                                                          ],
                                                        ).createShader(
                                                          const Rect.fromLTWH(
                                                              0.0,
                                                              0.0,
                                                              200.0,
                                                              70.0),
                                                        ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          right: 8.0),
                                                  child: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    backgroundImage: FirebaseAuth
                                                                .instance
                                                                .currentUser
                                                                ?.photoURL !=
                                                            null
                                                        ? NetworkImage(
                                                            FirebaseAuth
                                                                .instance
                                                                .currentUser!
                                                                .photoURL!)
                                                        : null, // Handle null photoURL
                                                    child: FirebaseAuth
                                                                .instance
                                                                .currentUser
                                                                ?.photoURL ==
                                                            null
                                                        ? Text(
                                                            FirebaseAuth
                                                                    .instance
                                                                    .currentUser
                                                                    ?.displayName
                                                                    ?.substring(
                                                                        0, 1)
                                                                    .toUpperCase() ??
                                                                'U',
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Container(
                                              padding:
                                                  const EdgeInsets.all(12.0),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                    0xFFF0F0F0), // Light grey background
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                              ),
                                              child: _buildMessageContent(
                                                message["message"],
                                                message["isUser"],
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_messages.isEmpty)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(12.0),
                                decoration: BoxDecoration(
                                  color: const Color(
                                      0xFFF0F0F0), // Light gray background
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Text(
                                  'noMessages'.tr(),
                                  style: TextStyle(
                                    fontSize: 24, // Larger font size
                                    fontWeight: FontWeight.bold, // Bold text
                                    foreground: Paint()
                                      ..shader = const LinearGradient(
                                        colors: <Color>[
                                          Color(
                                              0xFF6A11CB), // Gradient start color
                                          Color(
                                              0xFF2575FC), // Gradient end color
                                        ],
                                      ).createShader(
                                        const Rect.fromLTWH(
                                            0.0, 0.0, 200.0, 70.0),
                                      ),
                                  ),
                                ),
                              ),
                            ),
                          if (state is CopilotLoading)
                            const Center(
                              child: CircularProgressIndicator(),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  height: MediaQuery.of(context).size.height * 0.08,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest, // Light color for the container
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      if (_pickedImage != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: 60, // Slightly bigger height
                                width: 60, // Slightly bigger width
                                child: Image.memory(_pickedImage!),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _cancelImage,
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
                            controller: _controller,
                            focusNode: _focusNode,
                            decoration: InputDecoration(
                              hintText: "messageDrCopilot".tr(),
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
                                  .onSurface, // Text color
                            ),
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onFieldSubmitted: (value) {
                              _sendMessage();
                            },
                          ),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isButtonEnabled,
                        builder: (context, isEnabled, child) {
                          return IconButton(
                            onPressed: isEnabled ? _sendMessage : null,
                            icon: const Icon(Icons.send),
                            color: isEnabled
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          );
                        },
                      ),
                      IconButton(
                        onPressed: () {
                          context.read<CopilotBloc>().add(StartNewChatEvent());
                        },
                        icon: const Icon(Icons.add),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      DropdownButton<String>(
                        value: _selectedModel,
                        onChanged: _isModelChoiceEnabled
                            ? (String? newValue) {
                                setState(() {
                                  _selectedModel = newValue!;
                                });
                              }
                            : null,
                        items: _availableModels
                            .map<DropdownMenuItem<String>>((String value) {
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
          ),
        ],
      ),
    );
  }

  void _showTypingEffect(String message) {
    setState(() {
      _messages.add({"isUser": false, "message": ""});
    });
    int index = _messages.length - 1;
    int charIndex = 0;
    Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (charIndex < message.length) {
        setState(() {
          _messages[index]["message"] += message[charIndex];
        });
        charIndex++;
        _scrollToBottom();
      } else {
        timer.cancel();
        // Format the message as markdown
        setState(() {
          _messages[index]["message"] =
              _formatMarkdown(_messages[index]["message"]);
        });
        context.read<CopilotBloc>().add(CacheMessagesEvent(_messages));
      }
    });
  }

  String _formatMarkdown(String message) {
    // Use the markdown package to convert markdown to HTML
    // Add spaces for headings by replacing '#' with '# '
    final spacedMessage = message.replaceAllMapped(
      RegExp(r'^(#+)([^\s])', multiLine: true),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    return markdownToHtml(spacedMessage);
  }

  Widget _buildMessageContent(String message, bool isUser) {
    if (isUser) {
      return Text(
        message,
        style: const TextStyle(
            color: Colors.white, fontSize: 14), // Decreased font size
      );
    } else {
      return Html(
        data: message,
        style: {
          "body": Style(
            color:
                Colors.black, // Changed text color to black for better contrast
            fontSize: FontSize(14), // Decreased font size
            backgroundColor: const Color(
                0xFFF0F0F0), // Set a slightly darker light background color
          ),
        },
      );
    }
  }
}
