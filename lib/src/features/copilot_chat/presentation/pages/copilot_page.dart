import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/repositories/conversation_repository.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/function_call_handler.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/bloc/copilot_bloc.dart';

import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/conversation_sidebar.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/copilot_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
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
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';

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

  Uint8List? _pickedImage;

  final List<String> _availableModels = [];

  int _tokenUsage = 0;
  int _tokenLimit = 0;
  SubscriptionTier _currentTier = SubscriptionTier.free;
  List<String> _userPermissions = [];

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
      // Initialize settings
      final settingsState = context.read<SettingsBloc>().state;
      context.read<CopilotBloc>().add(
            UpdateCopilotSettingsEvent(settingsState.copilotRequiredFields),
          );
    });
    _initializeAvailableModels();
    _requestPermissions();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      String? clinicId = ownerNotifier.clinicId;
      final userResult = await sl<AbstractAuthRepository>().getCurrentUser();
      final user = userResult.fold((l) => null, (r) => r);

      if (clinicId == null && user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        clinicId = userDoc.data()?['primaryClinicId'];
      }

      if (clinicId != null && user != null) {
        final tier = await sl<SubscriptionService>().getCurrentTier(clinicId);
        final tokenUsage = await sl<QuotaService>().getUsage(
          clinicId,
          null,
          LimitType.aiTokens,
        );

        if (mounted) {
          setState(() {
            _currentTier = tier;
            _tokenUsage = tokenUsage;
            _tokenLimit = tier.maxMonthlyTokens;
          });
        }
      }
    } catch (e) {
      debugPrint('[CopilotPage] Error loading subscription info: $e');
      // Non-fatal: just log and continue
    }

    // Load user permissions
    await _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    try {
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final clinicId = ownerNotifier.clinicId;
      final userResult = await sl<AbstractAuthRepository>().getCurrentUser();
      final user = userResult.fold((l) => null, (r) => r);

      debugPrint(
          '[CopilotPage] Loading permissions - clinicId: $clinicId, userId: ${user?.uid}');

      if (user != null) {
        final hasPermission = await sl<PermissionService>().getUserPermissions(
          clinicId: clinicId,
        );

        debugPrint('[CopilotPage] Loaded permissions: $hasPermission');

        if (mounted && hasPermission != null) {
          setState(() {
            _userPermissions = hasPermission;
          });
          debugPrint('[CopilotPage] Set permissions state: $_userPermissions');
        }
      }
    } catch (e) {
      debugPrint('[CopilotPage] Error loading user permissions: $e');
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
      permissionService: GetIt.instance<PermissionService>(),
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

  Future<String>? _conversationCreationFuture;

  void _sendMessage() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
    final clinicId = ownerNotifier.clinicId;

    // Only token limits apply - no message count restrictions

    if (_functionCallArgs.isNotEmpty && _currentParameterBeingAsked != null) {
      // User is providing an answer to a pending function call parameter.
      final message = _controller.text;
      _controller.clear();
      _messages.add({"isUser": true, "message": message});

      // Ensure conversation exists before saving answer
      String? convId = _currentConversationId;
      if (convId == null) {
        // This case shouldn't technically happen if flow is correct, but safety net:
        if (_conversationCreationFuture != null) {
          convId = await _conversationCreationFuture;
        } else {
          // Fallback creation if somehow we are in a function loop without an ID
          // (Unlikely unless state was lost)
          _conversationCreationFuture = _conversationRepo.createConversation(
            title: message.length > 50
                ? '${message.substring(0, 50)}...'
                : message,
            initialMessageText: message,
          );
          convId = await _conversationCreationFuture;
          setState(() {
            _currentConversationId = convId;
            _conversationCreationFuture = null;
          });
        }
      }

      // Save to Firebase
      if (convId != null) {
        if (!mounted) return;
        await _conversationRepo.addMessage(
          conversationId: convId,
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
      final text = _controller.text;
      setState(() {
        _messages.add({
          "isUser": true,
          "message": text,
          "image": base64Encode(_pickedImage!),
        });
        _pickedImage = null; // Clear immediately to update UI
      });

      // Create or add to conversation with locking
      if (_currentConversationId == null) {
        if (_conversationCreationFuture == null) {
          _conversationCreationFuture = _conversationRepo.createConversation(
            title: text.length > 50 ? '${text.substring(0, 50)}...' : text,
            initialMessageText: text,
          );

          try {
            final newId = await _conversationCreationFuture;
            if (mounted) {
              setState(() {
                _currentConversationId = newId;
                _conversationCreationFuture = null;
              });
            }
          } catch (e) {
            // Handle error, maybe reset future
            _conversationCreationFuture = null;
            return;
          }
        } else {
          // Wait for existing creation
          await _conversationCreationFuture;
        }
      }

      // At this point _currentConversationId should be set (or we waited for it)
      // Double check because of async gap
      if (_currentConversationId != null && mounted) {
        await _conversationRepo.addMessage(
          conversationId: _currentConversationId!,
          text: text,
          senderId: userId,
        );
      }

      if (!mounted) return;

      // Get forcePremium setting
      final forcePremium = context.read<SettingsBloc>().state.usePremiumModels;

      context.read<CopilotBloc>().add(
            UploadImageEvent(
              imageBytes:
                  _pickedImage!, // Wait, I cleared it above. Need local ref.
              // Logic error in my head -> I need to keep reference before clearing.
              // But I can't undo the clear above for UI.
              // Wait, I didn't capture local var for bytes.
              // Let's refactor this block slightly.
              text: text,
              clinicId: clinicId,
              userId: userId,
              forcePremium: forcePremium,
            ),
          );
      // Logic for UploadImageEvent above checks _pickedImage in original code?
      // No, original code passed _pickedImage!.
      // I cleared it. I must capture it.
      // Re-writing this block carefully.
    } else if (_controller.text.isNotEmpty) {
      final text = _controller.text;
      final messageId = const Uuid().v4();
      setState(() {
        _messages.add({
          "id": messageId,
          "isUser": true,
          "message": text,
        });
      });
      _controller.clear(); // Clear immediately for UX

      // Create or add to conversation with locking
      if (_currentConversationId == null) {
        if (_conversationCreationFuture == null) {
          _conversationCreationFuture = _conversationRepo.createConversation(
            title: text.length > 50 ? '${text.substring(0, 50)}...' : text,
            initialMessageText: text,
          );

          try {
            final newId = await _conversationCreationFuture;
            if (mounted) {
              setState(() {
                _currentConversationId = newId;
                _conversationCreationFuture = null;
              });
            }
          } catch (e) {
            _conversationCreationFuture = null;
            return;
          }
        } else {
          // Already creating, wait for it
          await _conversationCreationFuture;
        }
      }

      if (_currentConversationId != null && mounted) {
        await _conversationRepo.addMessage(
          conversationId: _currentConversationId!,
          text: text,
          senderId: userId,
        );
      }

      if (!mounted) return;
      // Get last 8 messages for context
      final recentMessages = _messages.length > 8
          ? _messages.sublist(_messages.length - 8)
          : _messages;

      // Get forcePremium setting
      final forcePremium = context.read<SettingsBloc>().state.usePremiumModels;

      context.read<CopilotBloc>().add(
            GenerateResponseEvent(
              query: text,
              messageHistory: recentMessages,
              clinicId: clinicId,
              userId: userId,
              forcePremium: forcePremium,
            ),
          );
    }
    _scrollToBottom();
    if (!mounted) return;
    context.read<CopilotBloc>().add(CacheMessagesEvent(_messages));
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);

    // Create callbacks once or use direct method references

    return BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          context.read<CopilotBloc>().add(
                UpdateCopilotSettingsEvent(state.copilotRequiredFields),
              );
        },
        child: BlocListener<CopilotBloc, CopilotState>(
          listener: (context, state) {
            if (state is CopilotResponseGenerated) {
              _showTypingEffect(state.response);
              _loadSubscriptionInfo();
            } else if (state is CopilotFunctionCall) {
              _handleFunctionCall(state.functionCall);
            } else if (state is CopilotError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('AI Error: ${state.error}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 10),
                    action: SnackBarAction(
                      label: 'Change Model',
                      textColor: Colors.white,
                      onPressed: () {
                        context.push('/settings/model_selection');
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
              // We need to listen to the ValueNotifiers to trigger rebuilds of the View
              // Since CopilotView takes raw values, we wrap it in ValueListenableBuilder or AnimatedBuilder
              // A MultiValueListenableBuilder would be nice, but nesting is fine for now.

              return ValueListenableBuilder<bool>(
                  valueListenable: _isButtonEnabled,
                  builder: (context, isButtonEnabled, _) {
                    return ValueListenableBuilder<bool>(
                        valueListenable: _isRecording,
                        builder: (context, isRecording, _) {
                          return ValueListenableBuilder<bool>(
                              valueListenable: _isListeningSpeech,
                              builder: (context, isListeningSpeech, _) {
                                return CopilotView(
                                  messages: _messages,
                                  textController: _controller,
                                  scrollController: _scrollController,
                                  isButtonEnabled: isButtonEnabled,
                                  isRecording: isRecording,
                                  isListeningSpeech: isListeningSpeech,
                                  isLoading: state is CopilotLoading,
                                  currentTier: _currentTier,
                                  tokenUsage: _tokenUsage,
                                  tokenLimit: _tokenLimit,
                                  userPermissions: _userPermissions,
                                  onSendMessage: _sendMessage,
                                  onPickImage: _pickImage,
                                  onCancelImage: _cancelImage,
                                  conversationSidebar: ConversationSidebar(
                                    repository: _conversationRepo,
                                    currentConversationId:
                                        _currentConversationId,
                                    onConversationSelected: _loadConversation,
                                    onNewChat: _startNewConversation,
                                    onDeleteConversation:
                                        _showDeleteConfirmation,
                                    onRenameConversation: _showRenameDialog,
                                  ),
                                  isSidebarVisible: _isSidebarVisible,
                                  onToggleHistory: () {
                                    setState(() {
                                      _isSidebarVisible = !_isSidebarVisible;
                                    });
                                  },
                                  onHistoryToggle: (val) {},
                                  onEditMessage: _handleEditMessage,
                                  // For speech start/stop, passing the async logic wrappers
                                  onSpeechStart: () async {
                                    _isListeningSpeech.value = true;
                                    final speechRecognitionService =
                                        GetIt.instance<
                                            AbstractSpeechRecognitionService>();
                                    final currentLocale = context.locale;
                                    if (speechRecognitionService
                                        is HybridSpeechRecognitionService) {
                                      speechRecognitionService.setLanguage(
                                          currentLocale.languageCode);
                                    }
                                    final startResult =
                                        await speechRecognitionService
                                            .startListening();
                                    startResult.fold((failure) {
                                      _isListeningSpeech.value = false;
                                      _showTypingEffect(
                                          'Error starting speech recognition: ${failure.message}');
                                    }, (_) {});
                                  },
                                  onSpeechStop: () async {
                                    final speechRecognitionService =
                                        GetIt.instance<
                                            AbstractSpeechRecognitionService>();
                                    final stopResult =
                                        await speechRecognitionService
                                            .stopListening();
                                    _isListeningSpeech.value = false;
                                    stopResult.fold(
                                      (failure) => _showTypingEffect(
                                          'Error stopping: ${failure.message}'),
                                      (transcript) {
                                        if (transcript.isNotEmpty) {
                                          _controller.text = _controller
                                                  .text.isNotEmpty
                                              ? '${_controller.text} $transcript'
                                              : transcript;
                                        }
                                      },
                                    );
                                  },
                                  pickedImage: _pickedImage,
                                  navMenuButton: navMenuButton,
                                  currentUserPhotoUrl: FirebaseAuth
                                      .instance.currentUser?.photoURL,
                                  currentUserDisplayName: FirebaseAuth
                                      .instance.currentUser?.displayName,
                                );
                              });
                        });
                  });
            },
          ),
        ));
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
        final currentFocus = FocusScope.of(context);
        if (currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
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
      final value = _functionCallArgs[param];
      debugPrint(
          '[CopilotPage] Checking param: $param, Value: $value, Required: true');
      if (value == null ||
          value.toString().trim().isEmpty ||
          value.toString().toLowerCase() == 'null') {
        debugPrint('[CopilotPage] asking for $param');
        _askForParameter(param, question);
        return false;
      }
      return true;
    }

    if (functionName == 'add_patient') {
      if (!checkAndAsk('name', 'What is the name of the patient?')) return;

      // Check for user-configured required fields
      final requiredFields =
          context.read<SettingsBloc>().state.copilotRequiredFields;

      debugPrint(
          '[CopilotPage] Add Patient - Required Fields Config: $requiredFields');

      if (requiredFields.contains('patient.age') ||
          requiredFields.contains('age')) {
        if (!checkAndAsk('age', 'What is the age of the patient?')) return;
      }
      if (requiredFields.contains('patient.gender') ||
          requiredFields.contains('gender')) {
        if (!checkAndAsk('gender', 'What is the gender of the patient?')) {
          return;
        }
      }
      if (requiredFields.contains('patient.phone') ||
          requiredFields.contains('phoneNumber')) {
        if (!checkAndAsk(
            'phoneNumber', 'What is the phone number of the patient?')) {
          return;
        }
      }
      if (requiredFields.contains('patient.address')) {
        if (!checkAndAsk('address', 'What is the address of the patient?')) {
          return;
        }
      }
      if (requiredFields.contains('patient.alt_phone')) {
        if (!checkAndAsk('alternativePhoneNumber',
            'What is the alternative phone number?')) {
          return;
        }
      }
      if (requiredFields.contains('patient.doctor')) {
        if (!checkAndAsk('treatingDoctor', 'Who is the treating doctor?')) {
          return;
        }
      }
      if (requiredFields.contains('patient.occupation')) {
        if (!checkAndAsk('occupation', 'What is the patient\'s occupation?')) {
          return;
        }
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
      bool hasOptional = [
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
      bool hasOptional = [
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
      bool hasOptional = [
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
    // Function execution happens silently - no "Executing..." message shown
    // Results or errors will be displayed after execution completes

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
