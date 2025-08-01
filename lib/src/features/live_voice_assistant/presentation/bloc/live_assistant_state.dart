part of 'live_assistant_bloc.dart';

/// Base class for all live assistant states
abstract class LiveAssistantState extends Equatable {
  const LiveAssistantState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class LiveAssistantInitial extends LiveAssistantState {
  const LiveAssistantInitial();
}

/// Loading state
class LiveAssistantLoading extends LiveAssistantState {
  final String? message;

  const LiveAssistantLoading({this.message});

  @override
  List<Object?> get props => [message];
}

/// State when assistant is ready to use
class LiveAssistantReady extends LiveAssistantState {
  final bool hasMicrophonePermission;
  final bool isSpeechRecognitionAvailable;
  final List<String> availableLanguages;
  final List<String> availableVoices;
  final List<String> availableAiModels;

  const LiveAssistantReady({
    required this.hasMicrophonePermission,
    required this.isSpeechRecognitionAvailable,
    required this.availableLanguages,
    required this.availableVoices,
    required this.availableAiModels,
  });

  @override
  List<Object?> get props => [
        hasMicrophonePermission,
        isSpeechRecognitionAvailable,
        availableLanguages,
        availableVoices,
        availableAiModels,
      ];
}

/// State when a voice session is active
class LiveAssistantSessionActive extends LiveAssistantState {
  final VoiceSessionModel session;
  final VoiceSessionStatus sessionStatus;
  final String? currentPartialText;
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final bool isMuted;
  final String selectedAiModel;
  final List<AssistantActionModel> pendingActions;
  final Map<String, dynamic> sessionContext;
  final String? errorMessage;

  const LiveAssistantSessionActive({
    required this.session,
    required this.sessionStatus,
    this.currentPartialText,
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
    required this.isMuted,
    required this.selectedAiModel,
    required this.pendingActions,
    required this.sessionContext,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        session,
        sessionStatus,
        currentPartialText,
        isListening,
        isSpeaking,
        isProcessing,
        isMuted,
        selectedAiModel,
        pendingActions,
        sessionContext,
        errorMessage,
      ];

  LiveAssistantSessionActive copyWith({
    VoiceSessionModel? session,
    VoiceSessionStatus? sessionStatus,
    String? currentPartialText,
    bool? isListening,
    bool? isSpeaking,
    bool? isProcessing,
    bool? isMuted,
    String? selectedAiModel,
    List<AssistantActionModel>? pendingActions,
    Map<String, dynamic>? sessionContext,
    String? errorMessage,
  }) {
    return LiveAssistantSessionActive(
      session: session ?? this.session,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      currentPartialText: currentPartialText ?? this.currentPartialText,
      isListening: isListening ?? this.isListening,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isProcessing: isProcessing ?? this.isProcessing,
      isMuted: isMuted ?? this.isMuted,
      selectedAiModel: selectedAiModel ?? this.selectedAiModel,
      pendingActions: pendingActions ?? this.pendingActions,
      sessionContext: sessionContext ?? this.sessionContext,
      errorMessage: errorMessage,
    );
  }

  /// Check if the assistant is currently busy
  bool get isBusy => isListening || isSpeaking || isProcessing;

  /// Check if voice input is available
  bool get canReceiveVoiceInput => !isBusy && !isMuted;

  /// Check if the assistant can speak
  bool get canSpeak => !isSpeaking && !isMuted;

  /// Get the current conversation messages
  List<VoiceMessageModel> get messages => session.messages;

  /// Get the last message
  VoiceMessageModel? get lastMessage => session.lastMessage;

  /// Check if there are any pending actions
  bool get hasPendingActions => pendingActions.isNotEmpty;

  /// Get actions that require confirmation
  List<AssistantActionModel> get actionsRequiringConfirmation =>
      pendingActions.where((action) => action.requiresConfirmation && !action.isConfirmed).toList();
}

/// State when session history is loaded
class LiveAssistantSessionHistory extends LiveAssistantState {
  final List<VoiceSessionModel> sessions;
  final bool isLoading;

  const LiveAssistantSessionHistory({
    required this.sessions,
    required this.isLoading,
  });

  @override
  List<Object?> get props => [sessions, isLoading];

  LiveAssistantSessionHistory copyWith({
    List<VoiceSessionModel>? sessions,
    bool? isLoading,
  }) {
    return LiveAssistantSessionHistory(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// State when an action is being executed
class LiveAssistantActionExecuting extends LiveAssistantState {
  final AssistantActionModel action;
  final String? progressMessage;

  const LiveAssistantActionExecuting({
    required this.action,
    this.progressMessage,
  });

  @override
  List<Object?> get props => [action, progressMessage];
}

/// State when an action is completed
class LiveAssistantActionCompleted extends LiveAssistantState {
  final AssistantActionModel action;
  final Map<String, dynamic>? result;
  final String? successMessage;

  const LiveAssistantActionCompleted({
    required this.action,
    this.result,
    this.successMessage,
  });

  @override
  List<Object?> get props => [action, result, successMessage];
}

/// State when permission is required
class LiveAssistantPermissionRequired extends LiveAssistantState {
  final String permissionType;
  final String message;

  const LiveAssistantPermissionRequired({
    required this.permissionType,
    required this.message,
  });

  @override
  List<Object?> get props => [permissionType, message];
}

/// Error state
class LiveAssistantError extends LiveAssistantState {
  final String message;
  final String? errorCode;
  final bool isRecoverable;

  const LiveAssistantError({
    required this.message,
    this.errorCode,
    required this.isRecoverable,
  });

  @override
  List<Object?> get props => [message, errorCode, isRecoverable];
}

/// State when assistant is paused
class LiveAssistantPaused extends LiveAssistantState {
  final VoiceSessionModel? session;
  final String reason;

  const LiveAssistantPaused({
    this.session,
    required this.reason,
  });

  @override
  List<Object?> get props => [session, reason];
}

/// State when assistant is being configured
class LiveAssistantConfiguring extends LiveAssistantState {
  final Map<String, dynamic> settings;

  const LiveAssistantConfiguring({
    required this.settings,
  });

  @override
  List<Object?> get props => [settings];
}
