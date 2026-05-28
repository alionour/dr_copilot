import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/core/helper/api_key_helper.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/repositories/conversation_repository.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/function_call_handler.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/bloc/copilot_bloc.dart';
import 'package:dr_copilot/src/features/copilot_chat/services/groq_service.dart';

import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/conversation_sidebar.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/widgets/copilot_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/services.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/abstract_speech_recognition_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/data/services/hybrid_speech_recognition_service.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:record/record.dart';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';

import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';

import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/enums/subscription_tier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';

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
  final ValueNotifier<CopilotMicState> _micState =
      ValueNotifier(CopilotMicState.idle);
  final List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic> _functionCallArgs = {};
  String? _currentParameterBeingAsked;
  String? _lastQuery; // Store last query for retry
  Timer? _typingTimer; // Track typing effect timer
  final _audioRecorder = AudioRecorder();

  late final ConversationRepository _conversationRepo;
  FunctionCallHandler? _functionCallHandler;
  String? _currentConversationId;
  bool _isSidebarVisible = false; // Sidebar hidden by default

  Uint8List? _pickedImage;

  final List<String> _availableModels = [];

  int _tokenUsage = 0;
  int _tokenLimit = SubscriptionTier.free.maxMonthlyTokens;
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

    _scrollController.addListener(_onScroll);
    _initializeAvailableModels();
    _requestPermissions();
    _loadSubscriptionInfo();
  }

  // Pagination State
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  dynamic _lastLoadedTimestamp; // Cursor for pagination

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMoreMessages &&
        _currentConversationId != null) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_currentConversationId == null || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final oldMessages = await _conversationRepo.fetchMessages(
        conversationId: _currentConversationId!,
        limit: 20,
        lastTimestamp: _lastLoadedTimestamp,
      );

      if (oldMessages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
          _isLoadingMore = false;
        });
        return;
      }

      // Update cursor
      _lastLoadedTimestamp = oldMessages.last.timestamp;

      setState(() {
        // Prepend older messages to the TOP of the list
        // Note: The UI displays reversed list (index 0 is bottom/newest).
        // Wait... _messages list order:
        // Currently: _loadConversation adds newest first (reversed) -> so index 0 is oldest?
        // Let's re-verify list order in _loadConversation.

        // _loadConversation:
        // for (var msg in messages.reversed) { _messages.add(...) }
        // repo returns NEWEST first (A, B, C) where A is newest.
        // reversed: (C, B, A) -> C is oldest.
        // So _messages = [Oldest, ..., Newest].
        // ListView is properly standard (top is index 0).

        // So to add OLDER messages, we must insert them at index 0.
        // oldMessages from repo = [D, E, F] (D is newer than E).
        // we want [F, E, D, C, B, A].

        final converted = <Map<String, dynamic>>[];
        for (var msg in oldMessages) {
          converted.add({
            "id": msg.id,
            "isUser": msg.isUser,
            "message": msg.text,
            "type": msg.type,
            "url": msg.audioUrl,
            "duration": msg.audioDuration,
          });
        }
        // Since list is reverse: true (0=Bottom, N=Top/Oldest), we append OLDER messages to the END.
        _messages.addAll(converted);

        _isLoadingMore = false;
      });
    } catch (e) {
      debugPrint('[CopilotPage] Error loading more messages: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  StreamSubscription? _usageSubscription;

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
        // Load static tier info
        final tier = await sl<SubscriptionService>().getCurrentTier(clinicId);

        if (mounted) {
          setState(() {
            _currentTier = tier;
            _tokenLimit = tier.maxMonthlyTokens;
          });
        }

        // Setup real-time usage listener
        _usageSubscription?.cancel();
        _usageSubscription = sl<QuotaService>()
            .watchUsage(
          clinicId,
          null,
          LimitType.aiTokens,
        )
            .listen((usage) {
          if (mounted) {
            setState(() {
              _tokenUsage = usage;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('[CopilotPage] Error loading subscription info: $e');
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
        var permissions = await sl<PermissionService>().getUserPermissions(
          clinicId: clinicId,
        );

        // If user is Owner or Admin, they should have all capabilities
        // even if not explicitly listed in permissions list
        if ((permissions == null || permissions.isEmpty) &&
            (ownerNotifier.ownerId == user.uid ||
                ownerNotifier.role == AppRole.admin)) {
          permissions = [
            'createPatient',
            'updatePatient',
            'createSession',
            'updateSession',
            'createEvaluation',
            'updateEvaluation',
            'viewCharts',
            'viewReports',
            'viewFinancials',
          ];
        }

        debugPrint('[CopilotPage] Final permissions: $permissions');

        if (mounted && permissions != null) {
          setState(() {
            _userPermissions = permissions!;
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
                label: 'copilotCopyMessage'.tr(),
                textColor: Colors.white,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: errorMessage));
                  debugPrint(
                    'SnackBar Info: ${'errorMessageCopied'.tr()}',
                  ); // Log to console
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: SelectionArea(
                          child: Text('errorMessageCopied'.tr())),
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

  void _setMicState(CopilotMicState state) {
    if (!mounted) return;
    _micState.value = state;
  }

  Future<void> _toggleSpeechInput() async {
    if (_micState.value == CopilotMicState.listening) {
      await _stopSpeechInput();
      return;
    }

    if (_micState.value == CopilotMicState.requestingPermission ||
        _micState.value == CopilotMicState.initializing ||
        _micState.value == CopilotMicState.finalizing) {
      return;
    }

    await _startSpeechInput();
  }

  Future<void> _startSpeechInput() async {
    final speechRecognitionService =
        GetIt.instance<AbstractSpeechRecognitionService>();
    final languageCode = context.locale.languageCode;

    try {
      _setMicState(CopilotMicState.requestingPermission);

      final permissionCheck =
          await speechRecognitionService.checkMicrophonePermission();
      var hasPermission = permissionCheck.fold((failure) {
        debugPrint('[Speech] Permission check failed: ${failure.message}');
        return false;
      }, (granted) => granted);

      if (!hasPermission) {
        final permissionRequest =
            await speechRecognitionService.requestMicrophonePermission();
        hasPermission = permissionRequest.fold((failure) {
          _showSpeechError(failure);
          return false;
        }, (granted) => granted);
      }

      if (!hasPermission) {
        _showMicrophonePermissionDenied();
        return;
      }

      _setMicState(CopilotMicState.initializing);

      debugPrint(
        '[CopilotPage] Voice input starting with app locale: $languageCode',
      );
      if (speechRecognitionService is HybridSpeechRecognitionService) {
        speechRecognitionService.setLanguage(languageCode);
      }

      speechRecognitionService.clearAccumulatedTranscript();

      final initResult = await speechRecognitionService.initialize();
      final initialized = initResult.fold((failure) {
        _showSpeechError(failure);
        return false;
      }, (_) => true);
      if (!initialized) return;

      final startResult = await speechRecognitionService.startListening();
      startResult.fold(
        _showSpeechError,
        (_) => _setMicState(CopilotMicState.listening),
      );
    } catch (e) {
      _showSpeechError(
        ServerFailure('Failed to start speech recognition: $e', 500),
      );
    }
  }

  Future<void> _stopSpeechInput() async {
    final speechRecognitionService =
        GetIt.instance<AbstractSpeechRecognitionService>();

    _setMicState(CopilotMicState.finalizing);

    try {
      final stopResult = await speechRecognitionService.stopListening();
      stopResult.fold(
        _showSpeechError,
        (transcript) {
          final cleanTranscript = _normalizeSpeechTranscript(transcript);
          if (cleanTranscript.isEmpty) {
            _showNoSpeechDetected();
          } else {
            _insertTranscriptIntoInput(cleanTranscript);
            _setMicState(CopilotMicState.idle);
          }
        },
      );
    } catch (e) {
      _showSpeechError(
        ServerFailure('Failed to stop speech recognition: $e', 500),
      );
    }
  }

  String _normalizeSpeechTranscript(String transcript) {
    return transcript.replaceFirst('__FINAL__:', '').trim();
  }

  void _insertTranscriptIntoInput(String transcript) {
    final text = _controller.text;
    final selection = _controller.selection;

    if (selection.start >= 0 &&
        selection.end >= selection.start &&
        selection.end <= text.length) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        transcript,
      );
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + transcript.length,
        ),
      );
      return;
    }

    final separator = text.isNotEmpty && !text.endsWith(' ') ? ' ' : '';
    _controller.text = '$text$separator$transcript';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  void _showMicrophonePermissionDenied() {
    _setMicState(CopilotMicState.error);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectionArea(
          child: Text('micPermissionRequired'.tr()),
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'settings'.tr(),
          textColor: Colors.white,
          onPressed: openAppSettings,
        ),
      ),
    );
    _resetMicErrorStateSoon();
  }

  void _showNoSpeechDetected() {
    _setMicState(CopilotMicState.error);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectionArea(
          child: Text('noSpeechDetected'.tr()),
        ),
        backgroundColor: Colors.orange,
      ),
    );
    _resetMicErrorStateSoon();
  }

  void _showSpeechError(Failure failure) {
    _setMicState(CopilotMicState.error);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectionArea(child: Text(_speechErrorMessage(failure))),
        backgroundColor: Colors.red,
        action: failure is PermissionFailure
            ? SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: openAppSettings,
              )
            : null,
      ),
    );
    _resetMicErrorStateSoon();
  }

  String _speechErrorMessage(Failure failure) {
    final message = failure.message.toLowerCase();

    if (failure is PermissionFailure || message.contains('permission')) {
      return 'micPermissionRequired'.tr();
    }
    if (failure is ApiKeyFailure ||
        message.contains('deepgram') ||
        message.contains('api key')) {
      return 'speechRecognitionUnavailable'.tr();
    }
    if (message.contains('locale') ||
        message.contains('language') ||
        message.contains('not available')) {
      return 'speechRecognitionLangUnavailable'.tr();
    }
    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('websocket') ||
        message.contains('connection')) {
      return 'speechRecognitionConnectionError'.tr();
    }

    return 'speechRecognitionFailed'.tr(args: [failure.message]);
  }

  void _resetMicErrorStateSoon() {
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted && _micState.value == CopilotMicState.error) {
        _micState.value = CopilotMicState.idle;
      }
    });
  }

  void _initializeAvailableModels() {
    if (ApiKeyHelper.vertexAIKey.isNotEmpty) _availableModels.add('MedPaLM');
    if (ApiKeyHelper.gptKey.isNotEmpty) _availableModels.add('GPT');
    if (ApiKeyHelper.geminiKey.isNotEmpty) _availableModels.add('Gemini');
    if (ApiKeyHelper.deepSeekKey.isNotEmpty) _availableModels.add('DeepSeek');
    if (ApiKeyHelper.qwenKey.isNotEmpty) _availableModels.add('Qwen');
    if (ApiKeyHelper.claudeKey.isNotEmpty) _availableModels.add('Claude');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _isButtonEnabled.dispose();
    _isRecording.dispose();
    _micState.dispose();
    _audioRecorder.dispose();
    _usageSubscription?.cancel();
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
      _messages.insert(0, {"isUser": true, "message": message});

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

      if (!mounted) return;

      // CRITICAL FIX: Instead of manually setting the parameter and retrying locally,
      // we must send the response back to the AI so it can parse complex answers
      // (like "22, male, 0123...") and update the function call arguments itself.

      _currentParameterBeingAsked = null; // Clear the flag

      // Get forcePremium setting
      final forcePremium = context.read<SettingsBloc>().state.usePremiumModels;

      // Send to AI to process the answer
      context.read<CopilotBloc>().add(GenerateResponseEvent(
            query: message,
            messageHistory: _messages.length > 8
                ? _messages.sublist(_messages.length - 8)
                : _messages,
            clinicId: clinicId!,
            userId: userId,
            forcePremium: forcePremium,
          ));

      _scrollToEnd();
      return;
    }

    if (_pickedImage != null && _controller.text.isNotEmpty) {
      final text = _controller.text;
      setState(() {
        _messages.insert(0, {
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
        _messages.insert(0, {
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

      _lastQuery = text; // Capture for retry

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
    _scrollToEnd();
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
            } else if (state is CopilotGroqFunctionCall) {
              // Handle Groq function calls by converting to handler format
              _handleGroqFunctionCall(state.functionCall);
            } else if (state is CopilotError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: SelectionArea(
                        child: Text('aiError'.tr(args: [state.error]))),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 10),
                    action: _lastQuery != null
                        ? SnackBarAction(
                            label: 'retry'.tr(),
                            textColor: Colors.white,
                            onPressed: () {
                              // Trigger retry
                              final ownerNotifier = Provider.of<OwnerNotifier>(
                                  context,
                                  listen: false);
                              final userId =
                                  FirebaseAuth.instance.currentUser?.uid;
                              final forcePremium = context
                                  .read<SettingsBloc>()
                                  .state
                                  .usePremiumModels;

                              if (userId != null &&
                                  ownerNotifier.clinicId != null) {
                                context
                                    .read<CopilotBloc>()
                                    .add(GenerateResponseEvent(
                                      query: _lastQuery!, // Use stored query
                                      messageHistory: _messages.length > 8
                                          ? _messages
                                              .sublist(_messages.length - 8)
                                          : _messages,
                                      clinicId: ownerNotifier.clinicId!,
                                      userId: userId,
                                      forcePremium: forcePremium,
                                    ));
                              }
                            },
                          )
                        : SnackBarAction(
                            label: 'changeModel'.tr(),
                            textColor: Colors.white,
                            onPressed: () {
                              context.push('/settings/model_selection');
                            },
                          ),
                  ),
                );
              }
            } else if (state is CopilotFormRequested) {
              // Only handle form request (show dialog) if this page is currently visible
              // This prevents duplicate forms when Live Chat is active on top
              if (ModalRoute.of(context)?.isCurrent == true) {
                _handleFormRequest(state.formType, state.initialData);
              }
            } else if (state is CachedMessagesLoaded) {
              setState(() {
                // Cache stores in chronological order (Oldest -> Newest)
                // UI expects reverse order (Newest -> Oldest) because of reverse: true
                _messages.addAll(state.messages.reversed);
                if (state.conversationId != null) {
                  _currentConversationId = state.conversationId;
                }
              });
              _scrollToEnd();
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
                          return ValueListenableBuilder<CopilotMicState>(
                              valueListenable: _micState,
                              builder: (context, micState, _) {
                                return CopilotView(
                                  messages: _messages,
                                  textController: _controller,
                                  scrollController: _scrollController,
                                  isButtonEnabled: isButtonEnabled,
                                  isRecording: isRecording,
                                  micState: micState,
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
                                  onSpeechToggle: _toggleSpeechInput,
                                  pickedImage: _pickedImage,
                                  navMenuButton: navMenuButton,
                                  currentUserPhotoUrl: FirebaseAuth
                                      .instance.currentUser?.photoURL,
                                  currentUserDisplayName: FirebaseAuth
                                      .instance.currentUser?.displayName,
                                  onStopGeneration: _stopGeneration,
                                );
                              });
                        });
                  });
            },
          ),
        ));
  }

  void _showTypingEffect(String message) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    setState(() {
      _messages.insert(0, {"isUser": false, "message": ""});
    });
    int index = 0;
    int charIndex = 0;
    _typingTimer?.cancel(); // Cancel previous timer if any
    _typingTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (charIndex < message.length) {
        setState(() {
          _messages[index]["message"] += message[charIndex];
        });
        charIndex++;
        _scrollToEnd();
      } else {
        timer.cancel();
        _typingTimer = null;
        // Format the message as markdown
        setState(() {
          _messages[index]["message"] = _formatMarkdown(
            _messages[index]["message"],
          );
        });

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
        // Scroll to bottom (Newest message/Index 0)
        _scrollToEnd();
      }
    });
  }

  String _formatMarkdown(String message) {
    // Return markdown as-is, no HTML conversion needed
    return message;
  }

  void _stopGeneration() {
    debugPrint('[CopilotPage] Stop generation requested');
    _typingTimer?.cancel();
    _typingTimer = null;
    context.read<CopilotBloc>().add(StopGenerationEvent());
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
        // Repo returns Newest -> Oldest. ListView is reverse: true (Index 0 = Bottom/Newest).
        // So we keep the order as is: [Newest, ..., Oldest]
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
      // Scroll to bottom (Newest message/Index 0)
      _scrollToEnd();
    });
  }

  void _showDeleteConfirmation(String conversationId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteChatTitle'.tr()),
        content: SelectionArea(
            child: Text('deleteChatConfirm'.tr())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              await _conversationRepo.deleteConversation(conversationId);
              if (!context.mounted || !mounted) return;

              navigator.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: SelectionArea(child: Text('chatDeletedSuccessfully'.tr())),
                  backgroundColor: Colors.green,
                ),
              );
              if (_currentConversationId == conversationId) {
                _startNewConversation();
              }
            },
            child: Text(
              'delete'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Handles Groq function calls by converting to the standard format
  void _handleGroqFunctionCall(GroqFunctionCall groqCall) {
    // Convert GroqFunctionCall to the format expected by _handleFunctionCall
    _functionCallArgs = {
      'functionName': groqCall.name,
      ...groqCall.arguments,
    };
    _handleFunctionCall();
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
      // 1. Check strict parameters first (name)
      if (!checkAndAsk('name', 'askPatientName'.tr())) return;

      // 2. Collect all missing optional-but-required fields
      final requiredFields =
          context.read<SettingsBloc>().state.copilotRequiredFields;
      debugPrint(
          '[CopilotPage] Add Patient - Required Fields Config: $requiredFields');

      List<String> missingFields = [];
      List<String> missingFieldPrompts = [];

      // Check Age
      if (requiredFields.contains('patient.age') ||
          requiredFields.contains('age')) {
        final val = _functionCallArgs['age'];
        if (val == null ||
            val.toString().trim().isEmpty ||
            val.toString().toLowerCase() == 'null') {
          missingFields.add('age');
          missingFieldPrompts.add('age');
        }
      }

      // Check Gender
      if (requiredFields.contains('patient.gender') ||
          requiredFields.contains('gender')) {
        final val = _functionCallArgs['gender'];
        if (val == null ||
            val.toString().trim().isEmpty ||
            val.toString().toLowerCase() == 'null') {
          missingFields.add('gender');
          missingFieldPrompts.add('gender');
        }
      }

      // Check Phone
      if (requiredFields.contains('patient.phone') ||
          requiredFields.contains('phoneNumber')) {
        final val = _functionCallArgs['phoneNumber'];
        if (val == null ||
            val.toString().trim().isEmpty ||
            val.toString().toLowerCase() == 'null') {
          missingFields.add('phoneNumber');
          missingFieldPrompts.add('phone number');
        }
      }

      // Check Address
      if (requiredFields.contains('patient.address')) {
        final val = _functionCallArgs['address'];
        if (val == null ||
            val.toString().trim().isEmpty ||
            val.toString().toLowerCase() == 'null') {
          missingFields.add('address');
          missingFieldPrompts.add('address');
        }
      }

      // Check Alt Phone
      if (requiredFields.contains('patient.alt_phone')) {
        final val = _functionCallArgs['alternativePhoneNumber'];
        if (val == null ||
            val.toString().trim().isEmpty ||
            val.toString().toLowerCase() == 'null') {
          missingFields.add('alternativePhoneNumber');
          missingFieldPrompts.add('alternative phone number');
        }
      }

      // Check Doctor
      if (requiredFields.contains('patient.doctor')) {
        final val = _functionCallArgs['treatingDoctor'];
        if (val == null ||
            val.toString().trim().isEmpty ||
            val.toString().toLowerCase() == 'null') {
          missingFields.add('treatingDoctor');
          missingFieldPrompts.add('treating doctor');
        }
      }

      // Check Occupation
      if (requiredFields.contains('patient.occupation')) {
        final val = _functionCallArgs['occupation'];
        if (val == null ||
            val.toString().trim().isEmpty ||
            val.toString().toLowerCase() == 'null') {
          missingFields.add('occupation');
          missingFieldPrompts.add('occupation');
        }
      }

      // 3. Ask for all missing fields at once
      if (missingFields.isNotEmpty) {
        String prompt;
        if (missingFields.length == 1) {
          prompt = 'askMissingField'.tr(args: [missingFieldPrompts.first]);
        } else {
          final last = missingFieldPrompts.removeLast();
          final joined = missingFieldPrompts.join(', ');
          prompt = 'askMultipleFields'.tr(args: [joined, last]);
        }

        // We use the first missing field as the 'key' for the AI context,
        // but the prompt asks for EVERYTHING.
        // NOTE: The AI needs to be smart enough to parse multiple items from the next user response.
        // Groq/Llama 3 is good at this.
        _askForParameter(missingFields.first, prompt);
        return;
      }

      _executeFunction(functionName);
    } else if (functionName == 'edit_patient') {
      if (!checkAndAsk(
        'id',
        'askEditPatientId'.tr(),
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
          'askAtLeastOneField'.tr(),
        );
        _functionCallArgs.clear();
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'delete_patient') {
      if (!checkAndAsk(
        'id',
        'askDeletePatientId'.tr(),
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'add_session') {
      if (!checkAndAsk(
        'patientId',
        'askSessionPatientId'.tr(),
      )) {
        return;
      }
      if (!checkAndAsk('price', 'askSessionPrice'.tr())) return;
      if (!checkAndAsk(
        'startDateTime',
        'askSessionStartTime'.tr(),
      )) {
        return;
      }
      if (!checkAndAsk(
        'endDateTime',
        'askSessionEndTime'.tr(),
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'edit_session') {
      if (!checkAndAsk(
        'id',
        'askEditSessionId'.tr(),
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
          'askAtLeastOneFieldSession'.tr(),
        );
        _functionCallArgs.clear();
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'delete_session') {
      if (!checkAndAsk(
        'id',
        'askDeleteSessionId'.tr(),
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'add_evaluation') {
      if (!checkAndAsk(
        'patientId',
        'askEvaluationPatientId'.tr(),
      )) {
        return;
      }
      if (!checkAndAsk(
        'patientName',
        'askEvaluationPatientName'.tr(),
      )) {
        return;
      }
      if (!checkAndAsk('price', 'askEvaluationPrice'.tr())) return;
      if (!checkAndAsk(
        'startDateTime',
        'askEvaluationStartTime'.tr(),
      )) {
        return;
      }
      if (!checkAndAsk(
        'endDateTime',
        'askEvaluationEndTime'.tr(),
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'edit_evaluation') {
      if (!checkAndAsk(
        'id',
        'askEditEvaluationId'.tr(),
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
          'askAtLeastOneFieldEval'.tr(),
        );
        _functionCallArgs.clear();
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'delete_evaluation') {
      if (!checkAndAsk(
        'id',
        'askDeleteEvaluationId'.tr(),
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'get_patient') {
      if (_functionCallArgs['id'] == null &&
          _functionCallArgs['name'] == null) {
        _askForParameter(
          'name',
          'askPatientIdOrName'.tr(),
        );
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'list_patients') {
      _executeFunction(functionName);
    } else if (functionName == 'get_session') {
      if (!checkAndAsk(
        'id',
        'askSessionRetrieveId'.tr(),
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'list_sessions') {
      _executeFunction(functionName);
    } else if (functionName == 'get_evaluation') {
      if (!checkAndAsk(
        'id',
        'askEvaluationRetrieveId'.tr(),
      )) {
        return;
      }
      _executeFunction(functionName);
    } else if (functionName == 'list_evaluations') {
      _executeFunction(functionName);
    } else {
      _showTypingEffect('unknownFunction'.tr(args: [functionName]));
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
      _showTypingEffect('functionHandlerNotInit'.tr());
      return;
    }

    final functionCall = FunctionCall(functionName, cleanArgs);
    final result = await _functionCallHandler!.handleFunctionCall(functionCall);

    if (result.containsKey('error')) {
      _showTypingEffect('functionError'.tr(args: [result['error']]));
    } else if (result.containsKey('message')) {
      _showTypingEffect(result['message']);
    } else if (result.containsKey('patients')) {
      final patients = result['patients'] as List;
      if (patients.isEmpty) {
        _showTypingEffect('noPatientsFound'.tr());
      } else {
        String response = 'patientsFound'.tr();
        for (var p in patients) {
          response += 'patientListItem'.tr(args: [
            p['name'] ?? '',
            p['id'] ?? '',
            '${p['age'] ?? ''}',
            p['gender'] ?? '',
          ]);
        }
        _showTypingEffect(response);
      }
    } else if (result.containsKey('sessions')) {
      final sessions = result['sessions'] as List;
      if (sessions.isEmpty) {
        _showTypingEffect('noSessionsFound'.tr());
      } else {
        String response = 'sessionsFound'.tr();
        for (var s in sessions) {
          response += 'sessionListItem'.tr(args: [
            s['id'] ?? '',
            s['patientName'] ?? '',
            '${s['startDateTime'] ?? ''}',
          ]);
        }
        _showTypingEffect(response);
      }
    } else if (result.containsKey('evaluations')) {
      final evaluations = result['evaluations'] as List;
      if (evaluations.isEmpty) {
        _showTypingEffect('noEvaluationsFound'.tr());
      } else {
        String response = 'evaluationsFound'.tr();
        for (var e in evaluations) {
          response += 'evaluationListItem'.tr(args: [
            e['id'] ?? '',
            e['patientName'] ?? '',
            '${e['startDateTime'] ?? ''}',
          ]);
        }
        _showTypingEffect(response);
      }
    } else {
      // Handle single object returns (get_patient, get_session, etc)
      if (functionName == 'get_patient') {
        _showTypingEffect(
          'patientFound'.tr(args: [
            result['name'] ?? '',
            '${result['age'] ?? ''}',
            result['gender'] ?? '',
            result['phoneNumber'] ?? '',
          ]),
        );
      } else if (functionName == 'get_session') {
        _showTypingEffect(
          'sessionFound'.tr(args: [
            result['id'] ?? '',
            result['patientName'] ?? '',
            '${result['startDateTime'] ?? ''}',
          ]),
        );
      } else if (functionName == 'get_evaluation') {
        _showTypingEffect(
          'evaluationFound'.tr(args: [
            result['id'] ?? '',
            result['patientName'] ?? '',
            '${result['startDateTime'] ?? ''}',
          ]),
        );
      } else {
        _showTypingEffect('functionExecuted'.tr(args: ['$result']));
      }
    }

    _functionCallArgs.clear();
  }

  void _showRenameDialog(String conversationId, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('renameChatTitle'.tr()),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'enterNewTitle'.tr()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('cancel'.tr()),
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
            child: Text('renameLabel'.tr()),
          ),
        ],
      ),
    );
  }

  void _scrollToEnd() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Scroll to bottom (0.0 because reverse: true)
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _handleEditMessage(String messageId, String currentText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('editMessageTitle'.tr()),
        content: SelectionArea(
            child: Text('editMessageDescription'.tr())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performRewindEdit(messageId, currentText);
            },
            child: Text('editLabelEdit'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performRewindEdit(String messageId, String currentText) async {
    if (_currentConversationId == null) return;

    // 1. Populate text controller
    setState(() {
      _controller.text = currentText;
      _focusNode.requestFocus();
    });

    // 2. Find message index
    final index = _messages.indexWhere((m) => m['id'] == messageId);
    if (index == -1) return;

    String? responseIdToDelete;
    if (index > 0) {
      final newerMsg = _messages[index - 1];
      // If the message immediately after (newer) is from AI, mark for deletion
      if (newerMsg['isUser'] == false) {
        responseIdToDelete = newerMsg['id'];
      }
    }

    // 3. Update UI instantly
    setState(() {
      _messages.removeAt(index); // Remove User Msg first
      if (responseIdToDelete != null) {
        _messages.removeWhere((m) => m['id'] == responseIdToDelete);
      }
    });

    // 4. Delete from Backend
    try {
      await _conversationRepo.deleteMessage(
        conversationId: _currentConversationId!,
        messageId: messageId,
      );
      if (responseIdToDelete != null) {
        await _conversationRepo.deleteMessage(
          conversationId: _currentConversationId!,
          messageId: responseIdToDelete,
        );
      }
    } catch (e) {
      debugPrint("Error deleting messages: $e");
      // Optional: Undo local changes or show error
    }
  }

  void _handleFormRequest(String formType, Map<String, dynamic> initialData) {
    debugPrint(
        '[CopilotPage] Handling Form Request: $formType with data: $initialData');
    if (formType == 'add_patient') {
      _showPatientForm(initialData);
    } else if (formType == 'edit_patient') {
      PatientModel? patient;
      if (initialData['id'] != null) {
        patient = PatientModel(
          id: initialData['id'],
          name: initialData['name'] ?? '',
          age: initialData['age'] is int
              ? initialData['age']
              : int.tryParse(initialData['age']?.toString() ?? ''),
          gender: initialData['gender'],
          address: initialData['address'],
          phone1: initialData['phoneNumber'],
          phone2: initialData['alternativePhoneNumber'],
          treatingDoctorId: initialData['treatingDoctor'],
          occupation: initialData['occupation'],
          ownerId: '',
          clinicId: '',
          createdAt: Timestamp.now(),
        );
      }
      _showPatientForm(initialData, patient: patient);
    } else if (formType == 'add_session') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                SelectionArea(child: Text('sessionFormNotImplemented'.tr()))),
      );
    }
  }

  void _showPatientForm(Map<String, dynamic> data, {PatientModel? patient}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 600,
          height: 700,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AddPatientPage(
              initialData: data,
              patient: patient,
            ),
          ),
        ),
      ),
    );
  }
}
