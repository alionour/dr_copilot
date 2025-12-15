import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/repositories/conversation_repository.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/function_call_handler.dart';
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

import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';

import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';

import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  FunctionCallHandler? _functionCallHandler;
  String? _currentConversationId;
  bool _isSidebarVisible = false; // Sidebar hidden by default

  String _selectedModel = 'Gemini';
  final bool _isModelChoiceEnabled = true;
  Uint8List? _pickedImage;

  final List<String> _availableModels = [];

  int _chatUsage = 0;
  int _chatLimit = 5; // Default for free
  int _tokenUsage = 0;
  int _tokenLimit = 0;
  SubscriptionTier _currentTier = SubscriptionTier.free;

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
    _requestPermissions();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
    String? clinicId = ownerNotifier.clinicId;
    final user = FirebaseAuth.instance.currentUser;

    if (clinicId == null && user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      clinicId = userDoc.data()?['primaryClinicId'];
    }

    if (clinicId != null && user != null) {
      final tier = await sl<SubscriptionService>().getCurrentTier(clinicId);
      final chatUsage = await sl<QuotaService>().getUsage(
        clinicId,
        user.uid,
        LimitType.aiChat,
      );
      final tokenUsage = await sl<QuotaService>().getUsage(
        clinicId,
        null,
        LimitType.aiTokens,
      );

      if (mounted) {
        setState(() {
          _currentTier = tier;
          _chatUsage = chatUsage;
          _chatLimit = tier.dailyChatLimit;
          _tokenUsage = tokenUsage;
          _tokenLimit = tier.maxMonthlyTokens;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initSpeechRecognitionService();
    // Only initialize once to prevent LateInitializationError
    _functionCallHandler ??= FunctionCallHandler(
      patientsUseCase: GetIt.instance<PatientsUseCase>(),
      sessionsUseCase: GetIt.instance<SessionsUseCase>(),
      evaluationsUseCase: GetIt.instance<EvaluationsUseCase>(),
      ownerNotifier: Provider.of<OwnerNotifier>(context, listen: false),
    );
  }

  Future<void> _initSpeechRecognitionService() async {
    final speechRecognitionService =
        GetIt.instance<AbstractSpeechRecognitionService>();

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
          final errorMessage =
              'Speech recognition initialization failed: ${failure.message}';
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
                  debugPrint(
                    'SnackBar Info: Error message copied to clipboard.',
                  ); // Log to console
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

  void _showUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('upgradeRequired'.tr()),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              context.pop();
              context.push('/subscription_pricing');
            },
            child: Text('upgrade'.tr()),
          ),
        ],
      ),
    );
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
      Uint8List? fileBytes = result.files.first.bytes;

      if (fileBytes == null && result.files.first.path != null) {
        fileBytes = await File(result.files.first.path!).readAsBytes();
      }

      if (fileBytes != null) {
        setState(() {
          _pickedImage = fileBytes;
        });
      }
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

    final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
    final clinicId = ownerNotifier.clinicId;

    if (clinicId != null) {
      final subscriptionService = sl<SubscriptionService>();
      final canChat = await subscriptionService.checkDailyChatLimit(
        clinicId,
        userId,
      );

      if (!canChat && mounted) {
        _showUpgradeDialog(context, 'dailyChatLimitReached'.tr());
        return;
      }

      // Increment usage
      await sl<QuotaService>().incrementUsage(
        clinicId,
        userId,
        LimitType.aiChat,
      );
      if (mounted) {
        setState(() {
          _chatUsage++;
        });
      }
    }

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
          "image": base64Encode(_pickedImage!),
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
      context.read<CopilotBloc>().add(
        UploadImageEvent(
          imageBytes: _pickedImage!,
          text: _controller.text,
          clinicId: clinicId,
          userId: userId,
        ),
      );
      setState(() {
        _pickedImage = null;
      });
    } else if (_controller.text.isNotEmpty) {
      final messageId = const Uuid().v4();
      setState(() {
        _messages.add({
          "id": messageId,
          "isUser": true,
          "message": _controller.text,
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
      // Get last 8 messages for context (excluding the current message just added)
      final recentMessages = _messages.length > 8
          ? _messages.sublist(_messages.length - 8)
          : _messages;
      context.read<CopilotBloc>().add(
        GenerateResponseEvent(
          query: _controller.text,
          messageHistory: recentMessages,
          clinicId: clinicId,
          userId: userId,
        ),
      );
    }
    _controller.clear();
    _scrollToBottom();
    if (!mounted) return;
    context.read<CopilotBloc>().add(CacheMessagesEvent(_messages));
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);
    final numberFormat = NumberFormat.compact();

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
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                if (_currentTier == SubscriptionTier.free)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 16,
                          color: _chatUsage >= _chatLimit
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Free Plan: $_chatUsage/$_chatLimit chats today',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: _chatUsage >= _chatLimit
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.token,
                      size: 16,
                      color: _tokenUsage >= _tokenLimit
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Monthly Tokens: ${numberFormat.format(_tokenUsage)} / ${numberFormat.format(_tokenLimit)}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: _tokenUsage >= _tokenLimit
                            ? Theme.of(context).colorScheme.error
                            : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentTier == SubscriptionTier.free &&
                        (_chatUsage >= _chatLimit ||
                            _tokenUsage >= _tokenLimit)) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/subscription_pricing'),
                        child: Text(
                          'Upgrade',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ),
                    ],
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
                            child: BlocListener<CopilotBloc, CopilotState>(
                              listener: (context, state) {
                                if (state is CopilotResponseGenerated) {
                                  _showTypingEffect(state.response);
                                  _loadSubscriptionInfo();
                                } else if (state is CopilotFunctionCall) {
                                  _handleFunctionCall(state.functionCall);
                                } else if (state is CopilotError) {
                                  // Show error in SnackBar with Change Model button
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'AI Error: ${state.error}',
                                        ),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 10),
                                        action: SnackBarAction(
                                          label: 'Change Model',
                                          textColor: Colors.white,
                                          onPressed: () {
                                            context.push(
                                              '/settings/model_selection',
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  }
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              height: MediaQuery.of(context).size.height * 0.08,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                children: [
                                  if (_pickedImage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 8.0,
                                      ),
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
                                                borderRadius:
                                                    BorderRadius.circular(20),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                      ),
                                      child: TextFormField(
                                        controller: _controller,
                                        focusNode: _focusNode,
                                        decoration: InputDecoration(
                                          hintText: "messageDrCopilot".tr(),
                                          border: InputBorder.none,
                                          hintStyle: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface, // Text color
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
                                        onPressed: isEnabled
                                            ? _sendMessage
                                            : null,
                                        icon: const Icon(Icons.send),
                                        color: isEnabled
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
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
                                              final speechRecognitionService =
                                                  GetIt.instance<
                                                    AbstractSpeechRecognitionService
                                                  >();

                                              // Update language based on current APP locale before starting (not device locale)
                                              final currentLocale =
                                                  context.locale;
                                              debugPrint(
                                                '[CopilotPage] Voice input starting with app locale: ${currentLocale.languageCode}',
                                              );
                                              if (speechRecognitionService
                                                  is HybridSpeechRecognitionService) {
                                                speechRecognitionService
                                                    .setLanguage(
                                                      currentLocale
                                                          .languageCode,
                                                    );
                                              }

                                              final startResult =
                                                  await speechRecognitionService
                                                      .startListening();
                                              startResult.fold((failure) {
                                                _isListeningSpeech.value =
                                                    false;
                                                _showTypingEffect(
                                                  'Error starting speech recognition: ${failure.message}',
                                                );
                                              }, (_) {});
                                            },
                                            onLongPressEnd: (_) async {
                                              final speechRecognitionService =
                                                  GetIt.instance<
                                                    AbstractSpeechRecognitionService
                                                  >();
                                              debugPrint(
                                                '[CopilotPage] Stopping speech recognition...',
                                              );
                                              final stopResult =
                                                  await speechRecognitionService
                                                      .stopListening();
                                              _isListeningSpeech.value = false;
                                              stopResult.fold(
                                                (failure) {
                                                  debugPrint(
                                                    '[CopilotPage] Error stopping: ${failure.message}',
                                                  );
                                                  _showTypingEffect(
                                                    'Error stopping speech recognition: ${failure.message}',
                                                  );
                                                },
                                                (transcript) {
                                                  debugPrint(
                                                    '[CopilotPage] Received transcript: "$transcript" (length: ${transcript.length}, isEmpty: ${transcript.isEmpty})',
                                                  );
                                                  if (transcript.isNotEmpty) {
                                                    final currentText =
                                                        _controller.text;
                                                    if (currentText
                                                        .isNotEmpty) {
                                                      _controller.text =
                                                          '$currentText $transcript';
                                                    } else {
                                                      _controller.text =
                                                          transcript;
                                                    }
                                                    debugPrint(
                                                      '[CopilotPage] Text field updated with transcript',
                                                    );
                                                  } else {
                                                    debugPrint(
                                                      '[CopilotPage] WARNING: Transcript is empty, not updating text field',
                                                    );
                                                  }
                                                },
                                              );
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                AnimatedOpacity(
                                                  opacity: isListeningSpeech
                                                      ? 1.0
                                                      : 0.0,
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child: Container(
                                                    width: 48.0,
                                                    height: 48.0,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: Colors.red
                                                          .withValues(
                                                            alpha: 0.2,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.red
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          blurRadius:
                                                              isListeningSpeech
                                                              ? 20.0
                                                              : 0.0,
                                                          spreadRadius:
                                                              isListeningSpeech
                                                              ? 10.0
                                                              : 0.0,
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
                                                  color:
                                                      isListeningSpeech ||
                                                          isRecording
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
                                    icon: const Icon(
                                      Icons.add_a_photo_outlined,
                                    ),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  IconButton(
                                    onPressed: null, // Disabled for now
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
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
                                        .map<DropdownMenuItem<String>>((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        })
                                        .toList(),
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
          ), // Close Expanded
        ], // Close Column children
      ), // Close Column
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
          _messages[index]["message"] = _formatMarkdown(
            _messages[index]["message"],
          );
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
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _handleFunctionCall([FunctionCall? initialFunctionCall]) async {
    if (initialFunctionCall != null) {
      _functionCallArgs = {
        'functionName': initialFunctionCall.name,
        ...initialFunctionCall.args,
      };
    }

    final functionName = _functionCallArgs['functionName'] as String?;
    if (functionName == null) return;

    // Helper to check and ask for parameters
    bool checkAndAsk(String param, String question) {
      if (_functionCallArgs[param] == null) {
        _askForParameter(param, question);
        return false;
      }
      return true;
    }

    if (functionName == 'add_patient') {
      if (!checkAndAsk('name', 'What is the name of the patient?')) return;
      if (!checkAndAsk('age', 'What is the age of the patient?')) return;
      if (!checkAndAsk('gender', 'What is the gender of the patient?')) return;
      if (!checkAndAsk('address', 'What is the address of the patient?')) {
        return;
      }
      if (!checkAndAsk(
        'phoneNumber',
        'What is the phone number of the patient?',
      )) {
        return;
      }

      _executeFunction(functionName);
    } else if (functionName == 'edit_patient') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the patient you want to edit?',
      )) {
        return;
      }
      // Check if at least one optional param is present
      bool hasOptional =
          [
            'name',
            'age',
            'gender',
            'address',
            'phoneNumber',
            'alternativePhoneNumber',
            'treatingDoctor',
            'occupation',
          ].any(
            (key) =>
                _functionCallArgs.containsKey(key) &&
                _functionCallArgs[key] != null,
          );

      if (!hasOptional) {
        _showTypingEffect(
          'Please provide at least one field to update for the patient.',
        );
        _functionCallArgs.clear();
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'delete_patient') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the patient you want to delete?',
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'add_session') {
      if (!checkAndAsk(
        'patientId',
        'What is the ID of the patient for this session?',
      )) {
        return;
      }
      if (!checkAndAsk('price', 'What is the price of the session?')) return;
      if (!checkAndAsk(
        'startDateTime',
        'What is the start date and time of the session (e.g., 2023-11-15T10:00:00)?',
      )) {
        return;
      }
      if (!checkAndAsk(
        'endDateTime',
        'What is the end date and time of the session (e.g., 2023-11-15T11:00:00)?',
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'edit_session') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the session you want to edit?',
      )) {
        return;
      }
      bool hasOptional =
          [
            'patientId',
            'price',
            'startDateTime',
            'endDateTime',
            'sessionType',
            'patientName',
            'doctorId',
          ].any(
            (key) =>
                _functionCallArgs.containsKey(key) &&
                _functionCallArgs[key] != null,
          );
      if (!hasOptional) {
        _showTypingEffect(
          'Please provide at least one field to update for the session.',
        );
        _functionCallArgs.clear();
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'delete_session') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the session you want to delete?',
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'add_evaluation') {
      if (!checkAndAsk(
        'patientId',
        'What is the ID of the patient for this evaluation?',
      )) {
        return;
      }
      if (!checkAndAsk(
        'patientName',
        'What is the name of the patient for this evaluation?',
      )) {
        return;
      }
      if (!checkAndAsk('price', 'What is the price of the evaluation?')) return;
      if (!checkAndAsk(
        'startDateTime',
        'What is the start date and time of the evaluation (e.g., 2023-11-15T10:00:00)?',
      )) {
        return;
      }
      if (!checkAndAsk(
        'endDateTime',
        'What is the end date and time of the evaluation (e.g., 2023-11-15T11:00:00)?',
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'edit_evaluation') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the evaluation you want to edit?',
      )) {
        return;
      }
      bool hasOptional =
          [
            'patientId',
            'patientName',
            'price',
            'startDateTime',
            'endDateTime',
            'doctorId',
          ].any(
            (key) =>
                _functionCallArgs.containsKey(key) &&
                _functionCallArgs[key] != null,
          );
      if (!hasOptional) {
        _showTypingEffect(
          'Please provide at least one field to update for the evaluation.',
        );
        _functionCallArgs.clear();
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'delete_evaluation') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the evaluation you want to delete?',
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'get_patient') {
      if (_functionCallArgs['id'] == null &&
          _functionCallArgs['name'] == null) {
        _askForParameter(
          'name',
          'What is the ID or name of the patient you want to retrieve?',
        );
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'list_patients') {
      _executeFunction(functionName);
    } else if (functionName == 'get_session') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the session you want to retrieve?',
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'list_sessions') {
      _executeFunction(functionName);
    } else if (functionName == 'get_evaluation') {
      if (!checkAndAsk(
        'id',
        'What is the ID of the evaluation you want to retrieve?',
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'list_evaluations') {
      _executeFunction(functionName);
    } else {
      _showTypingEffect('Unknown function: $functionName');
      _functionCallArgs.clear();
    }
  }

  void _executeFunction(String functionName) async {
    _showTypingEffect('Executing $functionName...');

    final Map<String, dynamic> cleanArgs = Map.from(_functionCallArgs);
    cleanArgs.remove('functionName');

    // Basic type conversion for common fields
    if (cleanArgs.containsKey('age') && cleanArgs['age'] is String) {
      cleanArgs['age'] = int.tryParse(cleanArgs['age']);
    }
    if (cleanArgs.containsKey('price') && cleanArgs['price'] is String) {
      cleanArgs['price'] = double.tryParse(cleanArgs['price']);
    }

    // Null safety check for _functionCallHandler
    if (_functionCallHandler == null) {
      _showTypingEffect('Error: Function handler not initialized.');
      return;
    }

    final functionCall = FunctionCall(functionName, cleanArgs);
    final result = await _functionCallHandler!.handleFunctionCall(functionCall);

    if (result.containsKey('error')) {
      _showTypingEffect('Error: ${result['error']}');
    } else if (result.containsKey('message')) {
      _showTypingEffect(result['message']);
    } else if (result.containsKey('patients')) {
      final patients = result['patients'] as List;
      if (patients.isEmpty) {
        _showTypingEffect('No patients found.');
      } else {
        String response = 'Patients found:';
        for (var p in patients) {
          response +=
              '\n- ${p['name']} (ID: ${p['id']}, Age: ${p['age']}, Gender: ${p['gender']})';
        }
        _showTypingEffect(response);
      }
    } else if (result.containsKey('sessions')) {
      final sessions = result['sessions'] as List;
      if (sessions.isEmpty) {
        _showTypingEffect('No sessions found.');
      } else {
        String response = 'Sessions found:';
        for (var s in sessions) {
          response +=
              '\n- ID: ${s['id']}, Patient: ${s['patientName']}, Date: ${s['startDateTime']}';
        }
        _showTypingEffect(response);
      }
    } else if (result.containsKey('evaluations')) {
      final evaluations = result['evaluations'] as List;
      if (evaluations.isEmpty) {
        _showTypingEffect('No evaluations found.');
      } else {
        String response = 'Evaluations found:';
        for (var e in evaluations) {
          response +=
              '\n- ID: ${e['id']}, Patient: ${e['patientName']}, Date: ${e['startDateTime']}';
        }
        _showTypingEffect(response);
      }
    } else {
      // Handle single object returns (get_patient, get_session, etc)
      if (functionName == 'get_patient') {
        _showTypingEffect(
          'Patient found: ${result['name']}, Age: ${result['age']}, Gender: ${result['gender']}, Phone: ${result['phoneNumber']}',
        );
      } else if (functionName == 'get_session') {
        _showTypingEffect(
          'Session found: ID: ${result['id']}, Patient: ${result['patientName']}, Date: ${result['startDateTime']}',
        );
      } else if (functionName == 'get_evaluation') {
        _showTypingEffect(
          'Evaluation found: ID: ${result['id']}, Patient: ${result['patientName']}, Date: ${result['startDateTime']}',
        );
      } else {
        _showTypingEffect('Function executed successfully: $result');
      }
    }

    _functionCallArgs.clear();
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

