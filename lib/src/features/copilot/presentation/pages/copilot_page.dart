import 'dart:typed_data';

import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart'
    as custom;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gemini/flutter_gemini.dart';

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
          "image": _pickedImage
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
                        setState(() {
                          _messages.add({
                            "isUser": false,
                            "message": geminiResponse.parts.last is TextPart
                                ? (geminiResponse.parts.last as TextPart).text
                                : geminiResponse.parts.last.toString()
                          });
                        });
                      } else {
                        setState(() {
                          _messages.add({
                            "isUser": false,
                            "message": state.response.toString()
                          });
                        });
                      }
                      _scrollToBottom();
                    } else if (state is CopilotError) {
                      setState(() {
                        _messages.add({
                          "isUser": false,
                          "message": 'Error: ${state.error}'
                        });
                      });
                      _scrollToBottom();
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
                                            child:
                                                Image.memory(message["image"]),
                                          ),
                                        ),
                                      Container(
                                        padding: const EdgeInsets.all(12.0),
                                        decoration: BoxDecoration(
                                          color: message["isUser"]
                                              ? Colors
                                                  .lightBlueAccent // User message color
                                              : Colors
                                                  .lightGreenAccent, // Bot message color
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          message["message"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.black, // Text color
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
                    color: Colors.grey[200], // Light color for the container
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
                              hintText: "Message Dr Copilot",
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
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
}
