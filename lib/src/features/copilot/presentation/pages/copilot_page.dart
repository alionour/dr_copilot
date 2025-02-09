import 'dart:typed_data';

import 'package:dr_copilot/src/features/copilot/presentation/bloc/copilot_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
  String _selectedModel = 'GPT';
  final bool _isModelChoiceEnabled = true;
  Uint8List? _pickedImage;

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
    if (_pickedImage != null) {
      context.read<CopilotBloc>().add(UploadImageEvent(
          selectedModel: _selectedModel,
          imageBytes: _pickedImage!,
          text: _controller.text));
      setState(() {
        _pickedImage = null;
      });
    } else {
      context.read<CopilotBloc>().add(GenerateResponseEvent(
          query: _controller.text, selectedModel: _selectedModel));
    }
    _controller.clear();
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
                child: ListView.builder(
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
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: message["isUser"]
                                ? Colors.blueAccent // User message color
                                : Colors.greenAccent, // Bot message color
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            message["message"],
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white, // Text color
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
                                height: 100, // Slightly bigger height
                                width: 100, // Slightly bigger width
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
                                        Icons.cancel_presentation_outlined,
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
                        items: <String>['MedPaLM', 'GPT', 'Gemini']
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
          BlocBuilder<CopilotBloc, CopilotState>(
            builder: (context, state) {
              if (state is CopilotLoading) {
                return const CircularProgressIndicator();
              } else if (state is CopilotResponseGenerated) {
                _messages.add({"isUser": false, "message": state.response});
                _scrollToBottom();
                return Container();
              } else if (state is CopilotError) {
                return Text(
                  'Error: ${state.error}',
                  style: const TextStyle(color: Colors.red),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}
