import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/repositories/conversation_repository.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/message_list_view.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/conversation_sidebar.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/abstract_speech_recognition_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/hybrid_speech_recognition_service.dart';
import 'package:flutter/services.dart';











import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';


import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';

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
  final ValueNotifier<bool> _isRecording = ValueNotifier(false);
  final ValueNotifier<bool> _isListeningSpeech = ValueNotifier(false);
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic> _functionCallArgs = {};
  String? _currentParameterBeingAsked;
  final _audioRecorder = AudioRecorder();
  
  late final ConversationRepository _conversationRepo;
  String? _currentConversationId;
  bool _isSidebarVisible = false; // Sidebar hidden by default

  String _selectedModel = 'Gemini';
  final bool _isModelChoiceEnabled = true;
  Uint8List? _pickedImage;

  final List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _conversationRepo = ConversationRepository();
    _controller.addListener(() {
      _isButtonEnabled.value =
          _controller.text.isNotEmpty || _pickedImage != null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _initializeAvailableModels();
    _loadCachedMessages();
    _requestPermissions();
    _initSpeechRecognitionService();
  }



  Future<void> _initSpeechRecognitionService() async {
    final speechRecognitionService = GetIt.instance<AbstractSpeechRecognitionService>();
    
    // Set language based on current APP locale (not device locale)
    final currentLocale = context.locale;
    debugPrint('[CopilotPage] Using app locale: ${currentLocale.languageCode}');
    if (speechRecognitionService is HybridSpeechRecognitionService) {
      speechRecognitionService.setLanguage(currentLocale.languageCode);
    }
    
    final initResult = await speechRecognitionService.initialize();
    initResult.fold(
      (failure) {
        if (mounted) {
          final errorMessage = 'Speech recognition initialization failed: ${failure.message}';
          debugPrint('SnackBar Error: $errorMessage'); // Log to console
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: SelectableText(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Copy',
                textColor: Colors.white,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorMessage));
                  debugPrint('SnackBar Info: Error message copied to clipboard.'); // Log to console
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error message copied to clipboard.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          );
        }
      },
      (_) => debugPrint('Speech recognition service initialized successfully.'),
    );
  }



  Future<void> _requestPermissions() async {
    if (await Permission.microphone.isDenied) {
      await Permission.microphone.request();
    }
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
    _isListeningSpeech.dispose();
    _audioRecorder.dispose();
    // Don't dispose the speech recognition service here as it's a singleton
    // It will be disposed when the app closes
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


  void _sendMessage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    if (_functionCallArgs.isNotEmpty && _currentParameterBeingAsked != null) {
      // User is providing an answer to a pending function call parameter.
      final message = _controller.text;
      _controller.clear();
      _messages.add({"isUser": true, "message": message});

      // Save to Firebase
      if (_currentConversationId != null) {
        if (!mounted) return;
        await _conversationRepo.addMessage(
          conversationId: _currentConversationId!,
          text: message,
          senderId: userId,
        );
      }

      // Update the specific parameter being asked for
      _functionCallArgs[_currentParameterBeingAsked!] = message;
      _currentParameterBeingAsked = null; // Reset after receiving the answer

      _handleFunctionCall(); // Continue processing the function call
      _scrollToBottom();
      if (!mounted) return;
      context.read<CopilotBloc>().add(CacheMessagesEvent(_messages));
      return;
    }

    if (_pickedImage != null && _controller.text.isNotEmpty) {
      setState(() {
        _messages.add({
          "isUser": true,
          "message": _controller.text,
          "image": base64Encode(_pickedImage!)
        });
      });

      // Create or add to conversation
      if (_currentConversationId == null) {
        _currentConversationId = await _conversationRepo.createConversation(
          title: _controller.text.length > 50
              ? '${_controller.text.substring(0, 50)}...'
              : _controller.text,
          initialMessageText: _controller.text,
        );
      } else {
        if (!mounted) return;
        await _conversationRepo.addMessage(
          conversationId: _currentConversationId!,
          text: _controller.text,
          senderId: userId,
        );
      }

      if (!mounted) return;
      context.read<CopilotBloc>().add(UploadImageEvent(
          selectedModel: _selectedModel,
          imageBytes: _pickedImage!,
          text: _controller.text));
      setState(() {
        _pickedImage = null;
      });
    } else if (_controller.text.isNotEmpty) {
      final messageId = const Uuid().v4();
      setState(() {
        _messages.add({"id": messageId, "isUser": true, "message": _controller.text});
      });

      // Create or add to conversation
      if (_currentConversationId == null) {
        _currentConversationId = await _conversationRepo.createConversation(
          title: _controller.text.length > 50
              ? '${_controller.text.substring(0, 50)}...'
              : _controller.text,
          initialMessageText: _controller.text,
        );
      } else {
        if (!mounted) return;
        await _conversationRepo.addMessage(
          conversationId: _currentConversationId!,
          text: _controller.text,
          senderId: userId,
        );
      }

      if (!mounted) return;
      // Get last 8 messages for context (excluding the current message just added)
      final recentMessages = _messages.length > 8 
          ? _messages.sublist(_messages.length - 8)
          : _messages;
      context.read<CopilotBloc>().add(GenerateResponseEvent(
          query: _controller.text,
          selectedModel: _selectedModel,
          messageHistory: recentMessages));
    }
    _controller.clear();
    _scrollToBottom();
    if (!mounted) return;
    context.read<CopilotBloc>().add(CacheMessagesEvent(_messages));
  }

  void _loadCachedMessages() {
    context.read<CopilotBloc>().add(LoadCachedMessagesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('copilotChat'.tr()),
        leading: Icon(Icons.chat),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {
              setState(() {
                _isSidebarVisible = !_isSidebarVisible;
              });
            },
          ),
          navMenuButton ?? SizedBox(),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: Row(
        children: [
          // Chat Area
          Expanded(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: BlocListener<CopilotBloc, CopilotState>(
                  listener: (context, state) {
                    if (state is CopilotResponseGenerated) {
                      _showTypingEffect(state.response);
                    } else if (state is CopilotFunctionCall) {
                      _handleFunctionCall(state.functionCall);
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
                                            return MessageListView(
                                              scrollController: _scrollController,
                                              messages: _messages,
                                              isLoading: state is CopilotLoading,
                                              onEdit: _handleEditMessage,
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
                        .surfaceContainerHighest,
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
                                height: 60,
                                width: 60,
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
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          );
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isRecording,
                        builder: (context, isRecording, child) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: _isListeningSpeech,
                            builder: (context, isListeningSpeech, child) {
                              return GestureDetector(
                                onLongPressStart: (_) async {
                                  _isListeningSpeech.value = true;
                                  final speechRecognitionService = GetIt.instance<AbstractSpeechRecognitionService>();
                                  
                                  // Update language based on current APP locale before starting (not device locale)
                                  final currentLocale = context.locale;
                                  debugPrint('[CopilotPage] Voice input starting with app locale: ${currentLocale.languageCode}');
                                  if (speechRecognitionService is HybridSpeechRecognitionService) {
                                    speechRecognitionService.setLanguage(currentLocale.languageCode);
                                  }
                                  
                                  final startResult = await speechRecognitionService.startListening();
                                  startResult.fold(
                                    (failure) {
                                      _isListeningSpeech.value = false;
                                      _showTypingEffect('Error starting speech recognition: ${failure.message}');
                                    },
                                    (_) {},
                                  );
                                },
                                onLongPressEnd: (_) async {
                                  final speechRecognitionService = GetIt.instance<AbstractSpeechRecognitionService>();
                                  debugPrint('[CopilotPage] Stopping speech recognition...');
                                  final stopResult = await speechRecognitionService.stopListening();
                                  _isListeningSpeech.value = false;
                                  stopResult.fold(
                                    (failure) {
                                      debugPrint('[CopilotPage] Error stopping: ${failure.message}');
                                      _showTypingEffect('Error stopping speech recognition: ${failure.message}');
                                    },
                                    (transcript) {
                                      debugPrint('[CopilotPage] Received transcript: "$transcript" (length: ${transcript.length}, isEmpty: ${transcript.isEmpty})');
                                      if (transcript.isNotEmpty) {
                                        final currentText = _controller.text;
                                        if (currentText.isNotEmpty) {
                                          _controller.text = '$currentText $transcript';
                                        } else {
                                          _controller.text = transcript;
                                        }
                                        debugPrint('[CopilotPage] Text field updated with transcript');
                                      } else {
                                        debugPrint('[CopilotPage] WARNING: Transcript is empty, not updating text field');
                                      }
                                    },
                                  );
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    AnimatedOpacity(
                                      opacity: isListeningSpeech ? 1.0 : 0.0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Container(
                                        width: 48.0,
                                        height: 48.0,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.red.withValues(alpha: 0.2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withValues(alpha: 0.5),
                                              blurRadius: isListeningSpeech ? 20.0 : 0.0,
                                              spreadRadius: isListeningSpeech ? 10.0 : 0.0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isListeningSpeech
                                          ? Icons.mic
                                          : isRecording
                                              ? Icons.stop_circle
                                              : Icons.mic,
                                      size: 24.0,
                                      color: isListeningSpeech || isRecording
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),

                      IconButton(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      IconButton(
                        onPressed: null, // Disabled for now
                        icon: const Icon(Icons.chat_bubble_outline),
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
        ], // Close Column children
      ), // Close Column
      ), // Close Expanded
      // Sidebar - conditionally shown on the right
      if (_isSidebarVisible)
        ConversationSidebar(
          repository: _conversationRepo,
          currentConversationId: _currentConversationId,
          onConversationSelected: _loadConversation,
          onNewChat: _startNewConversation,
          onDeleteConversation: _showDeleteConfirmation,
          onRenameConversation: _showRenameDialog,
        ),
    ], // Close Row children
    ), // Close Row
    ); // Close Scaffold
  }

  void _handleEditMessage(String messageId, String newText) {
    if (_currentConversationId != null) {
      _conversationRepo.updateMessage(
        conversationId: _currentConversationId!,
        messageId: messageId,
        newText: newText,
      );
      final index = _messages.indexWhere((msg) => msg['id'] == messageId);
      if (index != -1) {
        setState(() {
          _messages[index]['message'] = newText;
        });
      }
    }
  }

  void _showTypingEffect(String message) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
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
        
        // Save AI response to Firebase
        if (_currentConversationId != null && userId != null) {
          _conversationRepo.addMessage(
            conversationId: _currentConversationId!,
            text: message,
            senderId: 'ai',
          );
        }
      }
    });
  }

  String _formatMarkdown(String message) {
    // Return markdown as-is, no HTML conversion needed
    return message;
  }



  void _askForParameter(String parameterName, String question) {
    _currentParameterBeingAsked = parameterName;
    _showTypingEffect(question);
  }

  void _startNewConversation() {
    setState(() {
      _currentConversationId = null;
      _messages.clear();
      _isSidebarVisible = false; // Close sidebar after action
    });
    context.read<CopilotBloc>().add(StartNewChatEvent());
  }

  void _loadConversation(String conversationId) async {
    setState(() {
      _currentConversationId = conversationId;
      _messages.clear();
      _isSidebarVisible = false; // Close sidebar after action
    });

    // Load messages from Firebase
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messages = await _conversationRepo
          .getMessages(conversationId: conversationId)
          .first;

      setState(() {
        for (var msg in messages) {
          _messages.add({
            "id": msg.id,
            "isUser": msg.isUser,
            "message": msg.text,
            "type": msg.type,
            "url": msg.audioUrl,
            "duration": msg.audioDuration,
          });
        }
      });
      _scrollToBottom();
    });
  }

  void _showDeleteConfirmation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _conversationRepo.deleteConversation(conversationId);
              if (mounted) {
                navigator.pop();
                if (_currentConversationId == conversationId) {
                  _startNewConversation();
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleFunctionCall([FunctionCall? initialFunctionCall]) {
    if (initialFunctionCall != null) {
      _functionCallArgs = {
        'functionName': initialFunctionCall.name,
        ...initialFunctionCall.args,
      };
    }

    final functionName = _functionCallArgs['functionName'] as String?;
    if (functionName == null) return;

    if (functionName == 'add_patient') {
      String? name = _functionCallArgs['name'] as String?;
      int? age;
      if (_functionCallArgs['age'] is String) {
        age = int.tryParse(_functionCallArgs['age'] as String);
      } else {
        age = _functionCallArgs['age'] as int?;
      }
      String? gender = _functionCallArgs['gender'] as String?;
      String? address = _functionCallArgs['address'] as String?;
      String? phoneNumber = _functionCallArgs['phoneNumber'] as String?;
      String? alternativePhoneNumber = _functionCallArgs['alternativePhoneNumber'] as String?;
      String? treatingDoctor = _functionCallArgs['treatingDoctor'] as String?;
      String? occupation = _functionCallArgs['occupation'] as String?;

      // Collect missing parameters
      if (name == null) {
        _askForParameter('name', 'What is the name of the patient?');
        return;
      }
      if (age == null) {
        _askForParameter('age', 'What is the age of the patient?');
        return;
      }
      if (gender == null) {
        _askForParameter('gender', 'What is the gender of the patient?');
        return;
      }
      if (address == null) {
        _askForParameter('address', 'What is the address of the patient?');
        return;
      }
      if (phoneNumber == null) {
        _askForParameter('phoneNumber', 'What is the phone number of the patient?');
        return;
      }
      // Optional fields, only ask if the user explicitly mentioned them or if they are needed for a specific flow.
      // For now, we will assume if they are not provided, they are not needed.

      // All required parameters collected, execute the function.
      _showTypingEffect('Adding patient: $name, age: $age, gender: $gender, address: $address, phone: $phoneNumber');

      final patientsUseCase = GetIt.instance<PatientsUseCase>();
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = ownerNotifier.clinicId; // Assuming a default clinic for now

      if (ownerId == null || clinicId == null) {
        _showTypingEffect('Error: Owner ID or Clinic ID not available. Cannot add patient.');
        _functionCallArgs.clear();
        return;
      }

      final patientModel = PatientModel(
        id: const Uuid().v4(),
        name: name,
        age: age,
        gender: gender,
        address: address,
        ownerId: ownerId,
        clinicId: clinicId,
        phoneNumber: phoneNumber,
        alternativePhoneNumber: alternativePhoneNumber,
        treatingDoctor: treatingDoctor,
        occupation: occupation,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );

      patientsUseCase.addPatient(patientModel).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error adding patient: ${failure.message}'),
          (patient) => _showTypingEffect('Patient ${patient.name} added successfully!'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'edit_patient') {
      String? id = _functionCallArgs['id'] as String?;
      String? name = _functionCallArgs['name'] as String?;
      int? age;
      if (_functionCallArgs['age'] is String) {
        age = int.tryParse(_functionCallArgs['age'] as String);
      } else {
        age = _functionCallArgs['age'] as int?;
      }
      String? gender = _functionCallArgs['gender'] as String?;
      String? address = _functionCallArgs['address'] as String?;
      String? phoneNumber = _functionCallArgs['phoneNumber'] as String?;
      String? alternativePhoneNumber = _functionCallArgs['alternativePhoneNumber'] as String?;
      String? treatingDoctor = _functionCallArgs['treatingDoctor'] as String?;
      String? occupation = _functionCallArgs['occupation'] as String?;

      if (id == null) {
        _askForParameter('id', 'What is the ID of the patient you want to edit?');
        return;
      }

      // Check if at least one editable parameter is provided
      if (name == null && age == null && gender == null && address == null &&
          phoneNumber == null && alternativePhoneNumber == null &&
          treatingDoctor == null && occupation == null) {
        _showTypingEffect('Please provide at least one field to update for the patient.');
        _functionCallArgs.clear();
        return;
      }

      _showTypingEffect('Editing patient with ID: $id');

      final patientsUseCase = GetIt.instance<PatientsUseCase>();
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = ownerNotifier.clinicId;

      if (ownerId == null || clinicId == null) {
        _showTypingEffect('Error: Owner ID or Clinic ID not available. Cannot edit patient.');
        _functionCallArgs.clear();
        return;
      }

      // Create a PatientModel with only the provided fields for update
      final updatedPatient = PatientModel(
        id: id,
        name: name ?? '', // Name is required in PatientModel, so provide a default if null
        age: age,
        gender: gender,
        address: address,
        ownerId: ownerId,
        clinicId: clinicId,
        phoneNumber: phoneNumber,
        alternativePhoneNumber: alternativePhoneNumber,
        treatingDoctor: treatingDoctor,
        occupation: occupation,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()), // This will be overwritten by the existing patient's createdAt
      );

      patientsUseCase.updatePatient(id, updatedPatient).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error editing patient: ${failure.message}'),
          (patient) => _showTypingEffect('Patient ${patient.name} (ID: ${patient.id}) updated successfully!'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'delete_patient') {
      String? id = _functionCallArgs['id'] as String?;

      if (id == null) {
        _askForParameter('id', 'What is the ID of the patient you want to delete?');
        return;
      }

      _showTypingEffect('Deleting patient with ID: $id');

      final patientsUseCase = GetIt.instance<PatientsUseCase>();
      patientsUseCase.deletePatient(id).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error deleting patient: ${failure.message}'),
          (_) => _showTypingEffect('Patient with ID: $id deleted successfully!'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'add_session') {
      String? patientId = _functionCallArgs['patientId'] as String?;
      double? price = _functionCallArgs['price'] as double?;
      String? startDateTimeString = _functionCallArgs['startDateTime'] as String?;
      String? endDateTimeString = _functionCallArgs['endDateTime'] as String?;
      String? sessionTypeString = _functionCallArgs['sessionType'] as String?;
      String? patientName = _functionCallArgs['patientName'] as String?;
      String? doctorId = _functionCallArgs['doctorId'] as String?;

      if (patientId == null) {
        _askForParameter('patientId', 'What is the ID of the patient for this session?');
        return;
      }
      if (price == null) {
        _askForParameter('price', 'What is the price of the session?');
        return;
      }
      if (startDateTimeString == null) {
        _askForParameter('startDateTime', 'What is the start date and time of the session (e.g., 2023-11-15T10:00:00)?');
        return;
      }
      if (endDateTimeString == null) {
        _askForParameter('endDateTime', 'What is the end date and time of the session (e.g., 2023-11-15T11:00:00)?');
        return;
      }

      final startDateTime = DateTime.tryParse(startDateTimeString);
      final endDateTime = DateTime.tryParse(endDateTimeString);

      if (startDateTime == null || endDateTime == null) {
        _showTypingEffect('Invalid date/time format. Please use ISO 8601 format (e.g., 2023-11-15T10:00:00).');
        _functionCallArgs.clear();
        return;
      }

      SessionType? sessionType;
      if (sessionTypeString != null) {
        try {
          sessionType = SessionType.values.firstWhere(
              (type) => type.toString().split('.').last == sessionTypeString);
        } catch (e) {
          _showTypingEffect('Invalid session type. Available types: pediatricIntensive, adultIntensive, standard, traction.');
          _functionCallArgs.clear();
          return;
        }
      }

      _showTypingEffect('Adding session for patient ID: $patientId, price: $price, from: $startDateTime to: $endDateTime');

      final sessionsUseCase = GetIt.instance<SessionsUseCase>();
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = ownerNotifier.clinicId;
      final createdBy = FirebaseAuth.instance.currentUser?.uid;

      if (ownerId == null || clinicId == null || createdBy == null) {
        _showTypingEffect('Error: Owner ID, Clinic ID, or User ID not available. Cannot add session.');
        _functionCallArgs.clear();
        return;
      }

      final sessionModel = SessionModel(
        id: const Uuid().v4(),
        patientId: patientId,
        price: price,
        startDateTime: Timestamp.fromDate(startDateTime),
        endDateTime: Timestamp.fromDate(endDateTime),
        sessionType: sessionType,
        ownerId: ownerId,
        clinicId: clinicId,
        createdBy: createdBy,
        patientName: patientName,
        doctorId: doctorId,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );

      sessionsUseCase.addSession(sessionModel).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error adding session: ${failure.message}'),
          (session) => _showTypingEffect('Session (ID: ${session.id}) added successfully for patient ${session.patientId}!'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'edit_session') {
      String? id = _functionCallArgs['id'] as String?;
      String? patientId = _functionCallArgs['patientId'] as String?;
      double? price = _functionCallArgs['price'] as double?;
      String? startDateTimeString = _functionCallArgs['startDateTime'] as String?;
      String? endDateTimeString = _functionCallArgs['endDateTime'] as String?;
      String? sessionTypeString = _functionCallArgs['sessionType'] as String?;
      String? patientName = _functionCallArgs['patientName'] as String?;
      String? doctorId = _functionCallArgs['doctorId'] as String?;

      if (id == null) {
        _askForParameter('id', 'What is the ID of the session you want to edit?');
        return;
      }

      if (patientId == null && price == null && startDateTimeString == null &&
          endDateTimeString == null && sessionTypeString == null &&
          patientName == null && doctorId == null) {
        _showTypingEffect('Please provide at least one field to update for the session.');
        _functionCallArgs.clear();
        return;
      }

      _showTypingEffect('Editing session with ID: $id');

      final sessionsUseCase = GetIt.instance<SessionsUseCase>();
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = ownerNotifier.clinicId;
      final updatedBy = FirebaseAuth.instance.currentUser?.uid;

      if (ownerId == null || clinicId == null || updatedBy == null) {
        _showTypingEffect('Error: Owner ID, Clinic ID, or User ID not available. Cannot edit session.');
        _functionCallArgs.clear();
        return;
      }

      sessionsUseCase.getSessionById(id).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error fetching session: ${failure.message}'),
          (existingSession) {
            DateTime? startDateTime;
            if (startDateTimeString != null) {
              startDateTime = DateTime.tryParse(startDateTimeString);
              if (startDateTime == null) {
                _showTypingEffect('Invalid start date/time format. Please use ISO 8601 format (e.g., 2023-11-15T10:00:00).');
                _functionCallArgs.clear();
                return;
              }
            }

            DateTime? endDateTime;
            if (endDateTimeString != null) {
              endDateTime = DateTime.tryParse(endDateTimeString);
              if (endDateTime == null) {
                _showTypingEffect('Invalid end date/time format. Please use ISO 8601 format (e.g., 2023-11-15T11:00:00).');
                _functionCallArgs.clear();
                return;
              }
            }

            SessionType? sessionType;
            if (sessionTypeString != null) {
              try {
                sessionType = SessionType.values.firstWhere(
                    (type) => type.toString().split('.').last == sessionTypeString);
              } catch (e) {
                _showTypingEffect('Invalid session type. Available types: pediatricIntensive, adultIntensive, standard, traction.');
                _functionCallArgs.clear();
                return;
              }
            }

            final updatedSession = existingSession.copyWith(
              patientId: patientId,
              price: price,
              startDateTime: startDateTime != null ? Timestamp.fromDate(startDateTime) : null,
              endDateTime: endDateTime != null ? Timestamp.fromDate(endDateTime) : null,
              sessionType: sessionType,
              patientName: patientName,
              doctorId: doctorId,
              updatedBy: updatedBy,
              updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
            );

            sessionsUseCase.updateSession(id, updatedSession).then((result) {
              result.fold(
                (failure) => _showTypingEffect('Error editing session: ${failure.message}'),
                (session) => _showTypingEffect('Session (ID: ${session.id}) updated successfully!'),
              );
            });
          },
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'delete_session') {
      String? id = _functionCallArgs['id'] as String?;

      if (id == null) {
        _askForParameter('id', 'What is the ID of the session you want to delete?');
        return;
      }

      _showTypingEffect('Deleting session with ID: $id');

      final sessionsUseCase = GetIt.instance<SessionsUseCase>();
      sessionsUseCase.deleteSession(id).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error deleting session: ${failure.message}'),
          (_) => _showTypingEffect('Session with ID: $id deleted successfully!'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'add_evaluation') {
      String? patientId = _functionCallArgs['patientId'] as String?;
      String? patientName = _functionCallArgs['patientName'] as String?;
      double? price = _functionCallArgs['price'] as double?;
      String? startDateTimeString = _functionCallArgs['startDateTime'] as String?;
      String? endDateTimeString = _functionCallArgs['endDateTime'] as String?;
      String? doctorId = _functionCallArgs['doctorId'] as String?;

      if (patientId == null) {
        _askForParameter('patientId', 'What is the ID of the patient for this evaluation?');
        return;
      }
      if (patientName == null) {
        _askForParameter('patientName', 'What is the name of the patient for this evaluation?');
        return;
      }
      if (price == null) {
        _askForParameter('price', 'What is the price of the evaluation?');
        return;
      }
      if (startDateTimeString == null) {
        _askForParameter('startDateTime', 'What is the start date and time of the evaluation (e.g., 2023-11-15T10:00:00)?');
        return;
      }
      if (endDateTimeString == null) {
        _askForParameter('endDateTime', 'What is the end date and time of the evaluation (e.g., 2023-11-15T11:00:00)?');
        return;
      }

      final startDateTime = DateTime.tryParse(startDateTimeString);
      final endDateTime = DateTime.tryParse(endDateTimeString);

      if (startDateTime == null || endDateTime == null) {
        _showTypingEffect('Invalid date/time format. Please use ISO 8601 format (e.g., 2023-11-15T10:00:00).');
        _functionCallArgs.clear();
        return;
      }

      _showTypingEffect('Adding evaluation for patient ID: $patientId, name: $patientName, price: $price, from: $startDateTime to: $endDateTime');

      final evaluationsUseCase = GetIt.instance<EvaluationsUseCase>();
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = ownerNotifier.clinicId;
      final createdBy = FirebaseAuth.instance.currentUser?.uid;

      if (ownerId == null || clinicId == null || createdBy == null) {
        _showTypingEffect('Error: Owner ID, Clinic ID, or User ID not available. Cannot add evaluation.');
        _functionCallArgs.clear();
        return;
      }

      final evaluationModel = EvaluationModel(
        id: const Uuid().v4(),
        patientId: patientId,
        patientName: patientName,
        price: price,
        startDateTime: Timestamp.fromDate(startDateTime),
        endDateTime: Timestamp.fromDate(endDateTime),
        ownerId: ownerId,
        clinicId: clinicId,
        createdBy: createdBy,
        doctorId: doctorId,
        createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
      );

      evaluationsUseCase.addEvaluation(evaluationModel).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error adding evaluation: ${failure.message}'),
          (evaluation) => _showTypingEffect('Evaluation (ID: ${evaluation.id}) added successfully for patient ${evaluation.patientName}!'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'edit_evaluation') {
      String? id = _functionCallArgs['id'] as String?;
      String? patientId = _functionCallArgs['patientId'] as String?;
      String? patientName = _functionCallArgs['patientName'] as String?;
      double? price = _functionCallArgs['price'] as double?;
      String? startDateTimeString = _functionCallArgs['startDateTime'] as String?;
      String? endDateTimeString = _functionCallArgs['endDateTime'] as String?;
      String? doctorId = _functionCallArgs['doctorId'] as String?;

      if (id == null) {
        _askForParameter('id', 'What is the ID of the evaluation you want to edit?');
        return;
      }

      if (patientId == null && patientName == null && price == null &&
          startDateTimeString == null && endDateTimeString == null &&
          doctorId == null) {
        _showTypingEffect('Please provide at least one field to update for the evaluation.');
        _functionCallArgs.clear();
        return;
      }

      _showTypingEffect('Editing evaluation with ID: $id');

      final evaluationsUseCase = GetIt.instance<EvaluationsUseCase>();
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = ownerNotifier.clinicId;
      final updatedBy = FirebaseAuth.instance.currentUser?.uid;

      if (ownerId == null || clinicId == null || updatedBy == null) {
        _showTypingEffect('Error: Owner ID, Clinic ID, or User ID not available. Cannot edit evaluation.');
        _functionCallArgs.clear();
        return;
      }

      evaluationsUseCase.getEvaluationById(id).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error fetching evaluation: ${failure.message}'),
          (existingEvaluation) {
            DateTime? startDateTime;
            if (startDateTimeString != null) {
              startDateTime = DateTime.tryParse(startDateTimeString);
              if (startDateTime == null) {
                _showTypingEffect('Invalid start date/time format. Please use ISO 8601 format (e.g., 2023-11-15T10:00:00).');
                _functionCallArgs.clear();
                return;
              }
            }

            DateTime? endDateTime;
            if (endDateTimeString != null) {
              endDateTime = DateTime.tryParse(endDateTimeString);
              if (endDateTime == null) {
                _showTypingEffect('Invalid end date/time format. Please use ISO 8601 format (e.g., 2023-11-15T11:00:00).');
                _functionCallArgs.clear();
                return;
              }
            }

            final updatedEvaluation = existingEvaluation.copyWith(
              patientId: patientId,
              patientName: patientName,
              price: price,
              startDateTime: startDateTime != null ? Timestamp.fromDate(startDateTime) : null,
              endDateTime: endDateTime != null ? Timestamp.fromDate(endDateTime) : null,
              doctorId: doctorId,
              updatedBy: updatedBy,
              updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
            );

            evaluationsUseCase.updateEvaluation(id, updatedEvaluation).then((result) {
              result.fold(
                (failure) => _showTypingEffect('Error editing evaluation: ${failure.message}'),
                (evaluation) => _showTypingEffect('Evaluation (ID: ${evaluation.id}) updated successfully!'),
              );
            });
          },
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'get_patient') {
      String? id = _functionCallArgs['id'] as String?;
      String? name = _functionCallArgs['name'] as String?;

      if (id == null && name == null) {
        _askForParameter('id', 'What is the ID or name of the patient you want to retrieve?');
        _askForParameter('name', 'What is the ID or name of the patient you want to retrieve?'); // This is a placeholder, will be handled by _currentParameterBeingAsked
        return;
      }

      _showTypingEffect('Retrieving patient information...');

      final patientsUseCase = GetIt.instance<PatientsUseCase>();

      if (id != null) {
        patientsUseCase.getPatientById(id).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error retrieving patient: ${failure.message}'),
            (patient) => _showTypingEffect('Patient found: ${patient.name}, Age: ${patient.age}, Gender: ${patient.gender}, Address: ${patient.address}, Phone: ${patient.phoneNumber}'),
          );
        });
      } else if (name != null) {
        patientsUseCase.searchPatients(name: name).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error searching patients: ${failure.message}'),
            (patients) {
              if (patients.isNotEmpty) {
                String response = 'Patients found:';
                for (var patient in patients) {
                  response += '\n- ${patient.name} (ID: ${patient.id}, Age: ${patient.age}, Gender: ${patient.gender})';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No patients found with the name: $name');
              }
            },
          );
        });
      }

      _functionCallArgs.clear();
    } else if (functionName == 'list_patients') {
      String? name = _functionCallArgs['name'] as String?;

      _showTypingEffect('Listing patients...');

      final patientsUseCase = GetIt.instance<PatientsUseCase>();

      patientsUseCase.getAllPatients().then((result) { // Changed to getAllPatients
        result.fold(
          (failure) => _showTypingEffect('Error listing patients: ${failure.message}'),
          (patients) {
            List<PatientModel> filteredPatients = patients;
            if (name != null && name.isNotEmpty) {
              filteredPatients = patients.where((patient) => patient.name.toLowerCase().contains(name.toLowerCase())).toList();
            }

            if (filteredPatients.isNotEmpty) {
              String response = 'Patients:';
              for (var patient in filteredPatients) {
                response += '\n- ${patient.name} (ID: ${patient.id}, Age: ${patient.age}, Gender: ${patient.gender})';
              }
              _showTypingEffect(response);
            } else {
              _showTypingEffect('No patients found.');
            }
          },
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'get_patient') {
      String? id = _functionCallArgs['id'] as String?;
      String? name = _functionCallArgs['name'] as String?;

      if (id == null && name == null) {
        _askForParameter('id', 'What is the ID or name of the patient you want to retrieve?');
        _askForParameter('name', 'What is the ID or name of the patient you want to retrieve?'); // This is a placeholder, will be handled by _currentParameterBeingAsked
        return;
      }

      _showTypingEffect('Retrieving patient information...');

      final patientsUseCase = GetIt.instance<PatientsUseCase>();

      if (id != null) {
        patientsUseCase.getPatientById(id).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error retrieving patient: ${failure.message}'),
            (patient) => _showTypingEffect('Patient found: ${patient.name}, Age: ${patient.age}, Gender: ${patient.gender}, Address: ${patient.address}, Phone: ${patient.phoneNumber}'),
          );
        });
      } else if (name != null) {
        patientsUseCase.searchPatients(name: name).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error searching patients: ${failure.message}'),
            (patients) {
              if (patients.isNotEmpty) {
                String response = 'Patients found:';
                for (var patient in patients) {
                  response += '\n- ${patient.name} (ID: ${patient.id}, Age: ${patient.age}, Gender: ${patient.gender})';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No patients found with the name: $name');
              }
            },
          );
        });
      }

      _functionCallArgs.clear();
    } else if (functionName == 'list_patients') {
      String? name = _functionCallArgs['name'] as String?;

      _showTypingEffect('Listing patients...');

      final patientsUseCase = GetIt.instance<PatientsUseCase>();

      patientsUseCase.getAllPatients().then((result) { // Changed to getAllPatients
        result.fold(
          (failure) => _showTypingEffect('Error listing patients: ${failure.message}'),
          (patients) {
            List<PatientModel> filteredPatients = patients;
            if (name != null && name.isNotEmpty) {
              filteredPatients = patients.where((patient) => patient.name.toLowerCase().contains(name.toLowerCase())).toList();
            }

            if (filteredPatients.isNotEmpty) {
              String response = 'Patients:';
              for (var patient in filteredPatients) {
                response += '\n- ${patient.name} (ID: ${patient.id}, Age: ${patient.age}, Gender: ${patient.gender})';
              }
              _showTypingEffect(response);
            } else {
              _showTypingEffect('No patients found.');
            }
          },
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'get_session') {
      String? id = _functionCallArgs['id'] as String?;

      if (id == null) {
        _askForParameter('id', 'What is the ID of the session you want to retrieve?');
        return;
      }

      _showTypingEffect('Retrieving session information...');

      final sessionsUseCase = GetIt.instance<SessionsUseCase>();

      sessionsUseCase.getSessionById(id).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error retrieving session: ${failure.message}'),
          (session) => _showTypingEffect('Session found: Patient ID: ${session.patientId}, Price: ${session.price}, Start: ${session.startDateTime.toDate()}, End: ${session.endDateTime.toDate()}'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'list_sessions') {
      String? patientName = _functionCallArgs['patientName'] as String?;
      String? dateString = _functionCallArgs['date'] as String?;

      _showTypingEffect('Listing sessions...');

      final sessionsUseCase = GetIt.instance<SessionsUseCase>();

      if (patientName != null && patientName.isNotEmpty) {
        sessionsUseCase.searchSessions(name: patientName).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error searching sessions: ${failure.message}'),
            (sessions) {
              if (sessions.isNotEmpty) {
                String response = 'Sessions found for patient "$patientName":';
                for (var session in sessions) {
                  response += '\n- ID: ${session.id}, Price: ${session.price}, Start: ${session.startDateTime.toDate()}, End: ${session.endDateTime.toDate()}';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No sessions found for patient "$patientName".');
              }
            },
          );
        });
      } else if (dateString != null && dateString.isNotEmpty) {
        DateTime? date = DateTime.tryParse(dateString);
        if (date == null) {
          _showTypingEffect('Invalid date format. Please use YYYY-MM-DD.');
          _functionCallArgs.clear();
          return;
        }
        sessionsUseCase.getSessionsByDate(date).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error getting sessions by date: ${failure.message}'),
            (sessions) {
              if (sessions.isNotEmpty) {
                String response = 'Sessions found for date "$dateString":';
                for (var session in sessions) {
                  response += '\n- ID: ${session.id}, Patient ID: ${session.patientId}, Price: ${session.price}, Start: ${session.startDateTime.toDate()}, End: ${session.endDateTime.toDate()}';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No sessions found for date "$dateString".');
              }
            },
          );
        });
      } else {
        sessionsUseCase.getAllSessions().then((result) { // Changed to getAllSessions
          result.fold(
            (failure) => _showTypingEffect('Error listing all sessions: ${failure.message}'),
            (sessions) {
              if (sessions.isNotEmpty) {
                String response = 'All sessions:';
                for (var session in sessions) {
                  response += '\n- ID: ${session.id}, Patient ID: ${session.patientId}, Price: ${session.price}, Start: ${session.startDateTime.toDate()}, End: ${session.endDateTime.toDate()}';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No sessions found.');
              }
            },
          );
        });
      }

      _functionCallArgs.clear();
    } else if (functionName == 'get_evaluation') {
      String? id = _functionCallArgs['id'] as String?;

      if (id == null) {
        _askForParameter('id', 'What is the ID of the evaluation you want to retrieve?');
        return;
      }

      _showTypingEffect('Retrieving evaluation information...');

      final evaluationsUseCase = GetIt.instance<EvaluationsUseCase>();

      evaluationsUseCase.getEvaluationById(id).then((result) {
        result.fold(
          (failure) => _showTypingEffect('Error retrieving evaluation: ${failure.message}'),
          (evaluation) => _showTypingEffect('Evaluation found: Patient ID: ${evaluation.patientId}, Patient Name: ${evaluation.patientName}, Price: ${evaluation.price}, Start: ${evaluation.startDateTime.toDate()}, End: ${evaluation.endDateTime.toDate()}'),
        );
      });

      _functionCallArgs.clear();
    } else if (functionName == 'list_evaluations') {
      String? patientName = _functionCallArgs['patientName'] as String?;
      String? dateString = _functionCallArgs['date'] as String?;

      _showTypingEffect('Listing evaluations...');

      final evaluationsUseCase = GetIt.instance<EvaluationsUseCase>();

      if (patientName != null && patientName.isNotEmpty) {
        evaluationsUseCase.searchEvaluations(name: patientName).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error searching evaluations: ${failure.message}'),
            (evaluations) {
              if (evaluations.isNotEmpty) {
                String response = 'Evaluations found for patient "$patientName":';
                for (var evaluation in evaluations) {
                  response += '\n- ID: ${evaluation.id}, Price: ${evaluation.price}, Start: ${evaluation.startDateTime.toDate()}, End: ${evaluation.endDateTime.toDate()}';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No evaluations found for patient "$patientName".');
              }
            },
          );
        });
      } else if (dateString != null && dateString.isNotEmpty) {
        DateTime? date = DateTime.tryParse(dateString);
        if (date == null) {
          _showTypingEffect('Invalid date format. Please use YYYY-MM-DD.');
          _functionCallArgs.clear();
          return;
        }
        evaluationsUseCase.getEvaluationsByDate(date).then((result) {
          result.fold(
            (failure) => _showTypingEffect('Error getting evaluations by date: ${failure.message}'),
            (evaluations) {
              if (evaluations.isNotEmpty) {
                String response = 'Evaluations found for date "$dateString":';
                for (var evaluation in evaluations) {
                  response += '\n- ID: ${evaluation.id}, Patient ID: ${evaluation.patientId}, Price: ${evaluation.price}, Start: ${evaluation.startDateTime.toDate()}, End: ${evaluation.endDateTime.toDate()}';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No evaluations found for date "$dateString".');
              }
            },
          );
        });
      } else {
        evaluationsUseCase.getAllEvaluations().then((result) { // Changed to getAllEvaluations
          result.fold(
            (failure) => _showTypingEffect('Error listing all evaluations: ${failure.message}'),
            (evaluations) {
              if (evaluations.isNotEmpty) {
                String response = 'All evaluations:';
                for (var evaluation in evaluations) {
                  response += '\n- ID: ${evaluation.id}, Patient ID: ${evaluation.patientId}, Price: ${evaluation.price}, Start: ${evaluation.startDateTime.toDate()}, End: ${evaluation.endDateTime.toDate()}';
                }
                _showTypingEffect(response);
              } else {
                _showTypingEffect('No evaluations found.');
              }
            },
          );
        });
      }

      _functionCallArgs.clear();
    }
  }

  void _showRenameDialog(String conversationId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter new title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (controller.text.isNotEmpty) {
                await _conversationRepo.renameConversation(
                  conversationId: conversationId,
                  newTitle: controller.text,
                );
                if (mounted) {
                  navigator.pop();
                }
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}