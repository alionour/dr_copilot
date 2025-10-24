import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/models/voice_session_model.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/models/voice_message_model.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/models/assistant_action_model.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/usecases/start_voice_session_usecase.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/usecases/process_voice_input_usecase.dart';
import 'package:dr_copilot/src/features/live_voice_assistant/domain/repositories/abstract_live_assistant_repository.dart';

part 'live_assistant_event.dart';
part 'live_assistant_state.dart';

/// BLoC for managing live voice assistant functionality
class LiveAssistantBloc extends Bloc<LiveAssistantEvent, LiveAssistantState> {
  final StartVoiceSessionUseCase startVoiceSessionUseCase;
  final ProcessVoiceInputUseCase processVoiceInputUseCase;
  final AbstractLiveAssistantRepository repository;

  StreamSubscription<Either<Failure, String>>? _speechRecognitionSubscription;
  StreamSubscription<Either<Failure, VoiceSessionModel>>? _sessionSubscription;

  LiveAssistantBloc({
    required this.startVoiceSessionUseCase,
    required this.processVoiceInputUseCase,
    required this.repository,
  }) : super(const LiveAssistantInitial()) {
    // Register event handlers
    on<InitializeLiveAssistantEvent>(_onInitializeLiveAssistant);
    on<StartVoiceSessionEvent>(_onStartVoiceSession);
    on<EndVoiceSessionEvent>(_onEndVoiceSession);
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<CancelListeningEvent>(_onCancelListening);
    on<VoiceInputReceivedEvent>(_onVoiceInputReceived);
    on<ProcessTextInputEvent>(_onProcessTextInput);
    on<SpeakResponseEvent>(_onSpeakResponse);
    on<StopSpeakingEvent>(_onStopSpeaking);
    on<PauseSpeakingEvent>(_onPauseSpeaking);
    on<ResumeSpeakingEvent>(_onResumeSpeaking);
    on<ExecuteActionEvent>(_onExecuteAction);
    on<ConfirmActionEvent>(_onConfirmAction);
    on<CancelActionEvent>(_onCancelAction);
    on<ChangeAiModelEvent>(_onChangeAiModel);
    on<ChangeVoiceSettingsEvent>(_onChangeVoiceSettings);
    on<LoadSessionHistoryEvent>(_onLoadSessionHistory);
    on<LoadSessionEvent>(_onLoadSession);
    on<DeleteSessionEvent>(_onDeleteSession);
    on<ToggleMuteEvent>(_onToggleMute);
    on<ClearConversationEvent>(_onClearConversation);
    on<ErrorOccurredEvent>(_onErrorOccurred);
    on<ResetAssistantEvent>(_onResetAssistant);
    on<SpeechRecognitionUpdateEvent>(_onSpeechRecognitionUpdate);
    on<UpdateSessionContextEvent>(_onUpdateSessionContext);
    on<RequestMicrophonePermissionEvent>(_onRequestMicrophonePermission);
    on<CheckMicrophonePermissionEvent>(_onCheckMicrophonePermission);
  }

  @override
  Future<void> close() {
    _speechRecognitionSubscription?.cancel();
    _sessionSubscription?.cancel();
    return super.close();
  }

  /// Initialize the live assistant
  Future<void> _onInitializeLiveAssistant(
    InitializeLiveAssistantEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    emit(
        const LiveAssistantLoading(message: 'Initializing voice assistant...'));

    try {
      // Check if voice session can be started
      final canStartResult =
          await startVoiceSessionUseCase.canStartVoiceSession();
      if (canStartResult.isLeft()) {
        final failure =
            canStartResult.fold((l) => l, (r) => throw 'Unexpected success');
        emit(LiveAssistantError(
          message: failure.message,
          errorCode: failure.code.toString(),
          isRecoverable:
              failure.code == 403, // Permission issues are recoverable
        ));
        return;
      }

      // Get available languages and voices
      final languagesResult =
          await startVoiceSessionUseCase.getAvailableLanguages();
      final voicesResult = await startVoiceSessionUseCase.getAvailableVoices();

      final languages = languagesResult.fold((l) => <String>[], (r) => r);
      final voices = voicesResult.fold((l) => <String>[], (r) => r);

      // Check microphone permission
      final permissionResult = await repository.checkMicrophonePermission();
      final hasPermission = permissionResult.fold((l) => false, (r) => r);

      // Check speech recognition availability
      final speechAvailableResult =
          await repository.isSpeechRecognitionAvailable();
      final speechAvailable =
          speechAvailableResult.fold((l) => false, (r) => r);

      emit(LiveAssistantReady(
        hasMicrophonePermission: hasPermission,
        isSpeechRecognitionAvailable: speechAvailable,
        availableLanguages: languages,
        availableVoices: voices,
        availableAiModels: [
          'Gemini',
          'GPT',
          'Claude',
          'MedPaLM',
          'DeepSeek',
          'Qwen'
        ],
      ));
    } catch (e, s) {
      print('Error in _onInitializeLiveAssistant: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to initialize voice assistant: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Start a new voice session
  Future<void> _onStartVoiceSession(
    StartVoiceSessionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    emit(const LiveAssistantLoading(message: 'Starting voice session...'));

    try {
      final result = await startVoiceSessionUseCase(
        userId: event.userId,
        title: event.title,
        selectedAiModel: event.selectedAiModel,
      );

      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(LiveAssistantError(
          message: failure.message,
          errorCode: failure.code.toString(),
          isRecoverable: true,
        ));
        return;
      }

      final session = result.fold((l) => throw l, (r) => r);

      // Start listening to session updates
      _sessionSubscription =
          repository.getVoiceSessionStream(session.id).listen(
        (sessionResult) {
          sessionResult.fold(
            (failure) => add(ErrorOccurredEvent(failure.message)),
            (updatedSession) {
              // Update the current state with the new session data
              if (state is LiveAssistantSessionActive) {
                final currentState = state as LiveAssistantSessionActive;
                emit(currentState.copyWith(session: updatedSession));
              }
            },
          );
        },
      );

      emit(LiveAssistantSessionActive(
        session: session,
        sessionStatus: session.status,
        isListening: false,
        isSpeaking: false,
        isProcessing: false,
        isMuted: false,
        selectedAiModel: session.selectedAiModel ?? 'Gemini',
        pendingActions: [],
        sessionContext: session.context,
      ));
    } catch (e, s) {
      print('Error in _onStartVoiceSession: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to start voice session: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// End the current voice session
  Future<void> _onEndVoiceSession(
    EndVoiceSessionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    try {
      // Cancel any ongoing operations
      await repository.cancelListening();
      await repository.stopSpeaking();

      // End the session
      await repository.endVoiceSession(event.sessionId);

      // Cancel subscriptions
      _speechRecognitionSubscription?.cancel();
      _sessionSubscription?.cancel();

      emit(const LiveAssistantReady(
        hasMicrophonePermission: true,
        isSpeechRecognitionAvailable: true,
        availableLanguages: [],
        availableVoices: [],
        availableAiModels: [
          'Gemini',
          'GPT',
          'Claude',
          'MedPaLM',
          'DeepSeek',
          'Qwen'
        ],
      ));
    } catch (e, s) {
      print('Error in _onEndVoiceSession: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to end voice session: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Start listening for voice input
  Future<void> _onStartListening(
    StartListeningEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;
    if (currentState.isBusy) return;

    try {
      emit(currentState.copyWith(isListening: true));

      final result = await processVoiceInputUseCase
          .startListening(currentState.session.id);
      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(currentState.copyWith(
          isListening: false,
          errorMessage: failure.message,
        ));
        return;
      }

      // Start listening to real-time speech recognition
      _speechRecognitionSubscription =
          repository.getRealtimeSpeechRecognitionStream().listen(
        (speechResult) {
          speechResult.fold(
            (failure) => add(ErrorOccurredEvent(failure.message)),
            (text) => add(SpeechRecognitionUpdateEvent(
                partialText: text, isFinal: false)),
          );
        },
      );
    } catch (e, s) {
      print('Error in _onStartListening: $e\n$s');
      emit(currentState.copyWith(
        isListening: false,
        errorMessage: 'Failed to start listening: ${e.toString()}',
      ));
    }
  }

  /// Stop listening for voice input
  Future<void> _onStopListening(
    StopListeningEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;
    if (!currentState.isListening) return;

    try {
      emit(currentState.copyWith(isListening: false, isProcessing: true));

      final result =
          await processVoiceInputUseCase.stopListening(currentState.session.id);
      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(currentState.copyWith(
          isProcessing: false,
          errorMessage: failure.message,
        ));
        return;
      }

      final recognizedText = result.fold((l) => throw l, (r) => r);
      if (recognizedText.isNotEmpty) {
        add(VoiceInputReceivedEvent(recognizedText));
      } else {
        emit(currentState.copyWith(isProcessing: false));
      }

      _speechRecognitionSubscription?.cancel();
    } catch (e, s) {
      print('Error in _onStopListening: $e\n$s');
      emit(currentState.copyWith(
        isListening: false,
        isProcessing: false,
        errorMessage: 'Failed to stop listening: ${e.toString()}',
      ));
    }
  }

  /// Cancel listening
  Future<void> _onCancelListening(
    CancelListeningEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;

    try {
      await processVoiceInputUseCase.cancelListening(currentState.session.id);
      _speechRecognitionSubscription?.cancel();

      emit(currentState.copyWith(
        isListening: false,
        isProcessing: false,
        currentPartialText: null,
      ));
    } catch (e, s) {
      print('Error in _onCancelListening: $e\n$s');
      emit(currentState.copyWith(
        isListening: false,
        isProcessing: false,
        errorMessage: 'Failed to cancel listening: ${e.toString()}',
      ));
    }
  }

  /// Handle voice input received
  Future<void> _onVoiceInputReceived(
    VoiceInputReceivedEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;

    try {
      emit(currentState.copyWith(isProcessing: true));

      final result = await processVoiceInputUseCase(
        sessionId: currentState.session.id,
        userInput: event.input,
        selectedModel: currentState.selectedAiModel,
        additionalContext: currentState.sessionContext,
      );

      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(currentState.copyWith(
          isProcessing: false,
          errorMessage: failure.message,
        ));
        return;
      }

      final updatedSession = result.fold((l) => throw l, (r) => r);
      final lastMessage = updatedSession.lastMessage;

      emit(currentState.copyWith(
        session: updatedSession,
        isProcessing: false,
        currentPartialText: null,
      ));

      // Automatically speak the AI response if it's an assistant message
      if (lastMessage != null &&
          lastMessage.isAssistantMessage &&
          !currentState.isMuted) {
        add(SpeakResponseEvent(lastMessage.content));
      }
    } catch (e, s) {
      print('Error in _onVoiceInputReceived: $e\n$s');
      emit(currentState.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to process voice input: ${e.toString()}',
      ));
    }
  }

  /// Process text input (manual text input)
  Future<void> _onProcessTextInput(
    ProcessTextInputEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    // Reuse the voice input processing logic
    add(VoiceInputReceivedEvent(event.input));
  }

  /// Speak AI response
  Future<void> _onSpeakResponse(
    SpeakResponseEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;
    if (currentState.isSpeaking || currentState.isMuted) return;

    try {
      emit(currentState.copyWith(isSpeaking: true));

      final result = await processVoiceInputUseCase.speakResponse(
        sessionId: currentState.session.id,
        text: event.text,
      );

      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(currentState.copyWith(
          isSpeaking: false,
          errorMessage: failure.message,
        ));
        return;
      }

      emit(currentState.copyWith(isSpeaking: false));
    } catch (e, s) {
      print('Error in _onSpeakResponse: $e\n$s');
      emit(currentState.copyWith(
        isSpeaking: false,
        errorMessage: 'Failed to speak response: ${e.toString()}',
      ));
    }
  }

  /// Stop speaking
  Future<void> _onStopSpeaking(
    StopSpeakingEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;

    try {
      await processVoiceInputUseCase.stopSpeaking(currentState.session.id);
      emit(currentState.copyWith(isSpeaking: false));
    } catch (e, s) {
      print('Error in _onStopSpeaking: $e\n$s');
      emit(currentState.copyWith(
        isSpeaking: false,
        errorMessage: 'Failed to stop speaking: ${e.toString()}',
      ));
    }
  }

  /// Pause speaking
  Future<void> _onPauseSpeaking(
    PauseSpeakingEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;

    try {
      await repository.pauseSpeaking();
      emit(LiveAssistantPaused(
          session: currentState.session, reason: 'Speaking paused'));
    } catch (e, s) {
      print('Error in _onPauseSpeaking: $e\n$s');
      emit(currentState.copyWith(
        errorMessage: 'Failed to pause speaking: ${e.toString()}',
      ));
    }
  }

  /// Resume speaking
  Future<void> _onResumeSpeaking(
    ResumeSpeakingEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantPaused) return;

    final pausedState = state as LiveAssistantPaused;
    if (pausedState.session == null) return;

    try {
      await repository.resumeSpeaking();

      emit(LiveAssistantSessionActive(
        session: pausedState.session!,
        sessionStatus: pausedState.session!.status,
        isListening: false,
        isSpeaking: true,
        isProcessing: false,
        isMuted: false,
        selectedAiModel: pausedState.session!.selectedAiModel ?? 'Gemini',
        pendingActions: [],
        sessionContext: pausedState.session!.context,
      ));
    } catch (e, s) {
      print('Error in _onResumeSpeaking: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to resume speaking: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Execute an action
  Future<void> _onExecuteAction(
    ExecuteActionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    try {
      emit(LiveAssistantActionExecuting(
        action: event.action,
        progressMessage: 'Executing ${event.action.description}...',
      ));

      final result = await repository.executeAction(event.action);
      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(LiveAssistantError(
          message: 'Failed to execute action: ${failure.message}',
          isRecoverable: true,
        ));
        return;
      }

      final completedAction = result.fold((l) => throw l, (r) => r);
      emit(LiveAssistantActionCompleted(
        action: completedAction,
        result: completedAction.result,
        successMessage: 'Successfully executed ${completedAction.description}',
      ));
    } catch (e, s) {
      print('Error in _onExecuteAction: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to execute action: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Confirm an action
  Future<void> _onConfirmAction(
    ConfirmActionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;
    final actionIndex =
        currentState.pendingActions.indexWhere((a) => a.id == event.actionId);

    if (actionIndex == -1) return;

    try {
      final action = currentState.pendingActions[actionIndex];
      final confirmedAction = action.confirm();

      final updatedActions =
          List<AssistantActionModel>.from(currentState.pendingActions);
      updatedActions[actionIndex] = confirmedAction;

      emit(currentState.copyWith(pendingActions: updatedActions));

      // Execute the confirmed action
      add(ExecuteActionEvent(confirmedAction));
    } catch (e, s) {
      print('Error in _onConfirmAction: $e\n$s');
      emit(currentState.copyWith(
        errorMessage: 'Failed to confirm action: ${e.toString()}',
      ));
    }
  }

  /// Cancel an action
  Future<void> _onCancelAction(
    CancelActionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;
    final updatedActions = currentState.pendingActions
        .where((action) => action.id != event.actionId)
        .toList();

    emit(currentState.copyWith(pendingActions: updatedActions));
  }

  /// Change AI model
  Future<void> _onChangeAiModel(
    ChangeAiModelEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;
    final updatedSession =
        currentState.session.copyWith(selectedAiModel: event.modelName);

    try {
      await repository.updateVoiceSession(updatedSession);
      emit(currentState.copyWith(
        session: updatedSession,
        selectedAiModel: event.modelName,
      ));
    } catch (e, s) {
      print('Error in _onChangeAiModel: $e\n$s');
      emit(currentState.copyWith(
        errorMessage: 'Failed to change AI model: ${e.toString()}',
      ));
    }
  }

  /// Change voice settings
  Future<void> _onChangeVoiceSettings(
    ChangeVoiceSettingsEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    try {
      if (event.voiceId != null) {
        await repository.setVoice(event.voiceId!);
      }
      if (event.speechRate != null) {
        await repository.setSpeechRate(event.speechRate!);
      }
      if (event.pitch != null) {
        await repository.setPitch(event.pitch!);
      }
    } catch (e, s) {
      print('Error in _onChangeVoiceSettings: $e\n$s');
      if (state is LiveAssistantSessionActive) {
        final currentState = state as LiveAssistantSessionActive;
        emit(currentState.copyWith(
          errorMessage: 'Failed to change voice settings: ${e.toString()}',
        ));
      }
    }
  }

  /// Load session history
  Future<void> _onLoadSessionHistory(
    LoadSessionHistoryEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    emit(const LiveAssistantSessionHistory(sessions: [], isLoading: true));

    try {
      final result = await repository.getUserVoiceSessions(event.userId);
      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(LiveAssistantError(
          message: 'Failed to load session history: ${failure.message}',
          isRecoverable: true,
        ));
        return;
      }

      final sessions = result.fold((l) => throw l, (r) => r);
      emit(LiveAssistantSessionHistory(sessions: sessions, isLoading: false));
    } catch (e, s) {
      print('Error in _onLoadSessionHistory: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to load session history: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Load a specific session
  Future<void> _onLoadSession(
    LoadSessionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    emit(const LiveAssistantLoading(message: 'Loading session...'));

    try {
      final result = await repository.getVoiceSession(event.sessionId);
      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(LiveAssistantError(
          message: 'Failed to load session: ${failure.message}',
          isRecoverable: true,
        ));
        return;
      }

      final session = result.fold((l) => throw l, (r) => r);
      emit(LiveAssistantSessionActive(
        session: session,
        sessionStatus: session.status,
        isListening: false,
        isSpeaking: false,
        isProcessing: false,
        isMuted: false,
        selectedAiModel: session.selectedAiModel ?? 'Gemini',
        pendingActions: [],
        sessionContext: session.context,
      ));
    } catch (e, s) {
      print('Error in _onLoadSession: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to load session: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Delete a session
  Future<void> _onDeleteSession(
    DeleteSessionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    try {
      await repository.deleteVoiceSession(event.sessionId);

      // If we're currently in this session, reset to ready state
      if (state is LiveAssistantSessionActive) {
        final currentState = state as LiveAssistantSessionActive;
        if (currentState.session.id == event.sessionId) {
          emit(const LiveAssistantReady(
            hasMicrophonePermission: true,
            isSpeechRecognitionAvailable: true,
            availableLanguages: [],
            availableVoices: [],
            availableAiModels: [
              'Gemini',
              'GPT',
              'Claude',
              'MedPaLM',
              'DeepSeek',
              'Qwen'
            ],
          ));
        }
      }
    } catch (e, s) {
      print('Error in _onDeleteSession: $e\n$s');
      if (state is LiveAssistantSessionActive) {
        final currentState = state as LiveAssistantSessionActive;
        emit(currentState.copyWith(
          errorMessage: 'Failed to delete session: ${e.toString()}',
        ));
      }
    }
  }

  /// Toggle mute
  Future<void> _onToggleMute(
    ToggleMuteEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;
    final newMuteState = !currentState.isMuted;

    // If unmuting and currently speaking, stop speaking
    if (!newMuteState && currentState.isSpeaking) {
      await repository.stopSpeaking();
    }

    emit(currentState.copyWith(isMuted: newMuteState, isSpeaking: false));
  }

  /// Clear conversation
  Future<void> _onClearConversation(
    ClearConversationEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;

    try {
      // Create a new session with the same settings but no messages
      final newSession = VoiceSessionModel.create(
        id: currentState.session.id,
        userId: currentState.session.userId,
        selectedAiModel: currentState.selectedAiModel,
      );

      await repository.updateVoiceSession(newSession);
      emit(currentState.copyWith(
        session: newSession,
        pendingActions: [],
        sessionContext: {},
      ));
    } catch (e, s) {
      print('Error in _onClearConversation: $e\n$s');
      emit(currentState.copyWith(
        errorMessage: 'Failed to clear conversation: ${e.toString()}',
      ));
    }
  }

  /// Handle errors
  Future<void> _onErrorOccurred(
    ErrorOccurredEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    emit(LiveAssistantError(
      message: event.errorMessage,
      isRecoverable: true,
    ));
  }

  /// Reset assistant
  Future<void> _onResetAssistant(
    ResetAssistantEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    try {
      // Cancel all ongoing operations
      await repository.cancelListening();
      await repository.stopSpeaking();

      // Cancel subscriptions
      _speechRecognitionSubscription?.cancel();
      _sessionSubscription?.cancel();

      emit(const LiveAssistantInitial());
    } catch (e, s) {
      print('Error in _onResetAssistant: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to reset assistant: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Handle speech recognition updates
  Future<void> _onSpeechRecognitionUpdate(
    SpeechRecognitionUpdateEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;

    if (event.isFinal) {
      // Final result - process the input
      add(VoiceInputReceivedEvent(event.partialText));
    } else {
      // Partial result - update the UI
      emit(currentState.copyWith(currentPartialText: event.partialText));
    }
  }

  /// Update session context
  Future<void> _onUpdateSessionContext(
    UpdateSessionContextEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    if (state is! LiveAssistantSessionActive) return;

    final currentState = state as LiveAssistantSessionActive;

    try {
      await repository.updateConversationContext(
        sessionId: currentState.session.id,
        context: event.context,
      );

      emit(currentState.copyWith(sessionContext: event.context));
    } catch (e, s) {
      print('Error in _onUpdateSessionContext: $e\n$s');
      emit(currentState.copyWith(
        errorMessage: 'Failed to update session context: ${e.toString()}',
      ));
    }
  }

  /// Request microphone permission
  Future<void> _onRequestMicrophonePermission(
    RequestMicrophonePermissionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    try {
      final result = await repository.requestMicrophonePermission();
      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(LiveAssistantPermissionRequired(
          permissionType: 'microphone',
          message: failure.message,
        ));
        return;
      }

      final granted = result.fold((l) => throw l, (r) => r);
      if (!granted) {
        emit(const LiveAssistantPermissionRequired(
          permissionType: 'microphone',
          message: 'Microphone permission is required for voice interaction',
        ));
      }
    } catch (e, s) {
      print('Error in _onRequestMicrophonePermission: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to request microphone permission: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }

  /// Check microphone permission
  Future<void> _onCheckMicrophonePermission(
    CheckMicrophonePermissionEvent event,
    Emitter<LiveAssistantState> emit,
  ) async {
    try {
      final result = await repository.checkMicrophonePermission();
      if (result.isLeft()) {
        final failure =
            result.fold((l) => l, (r) => throw 'Unexpected success');
        emit(LiveAssistantError(
          message: 'Failed to check microphone permission: ${failure.message}',
          isRecoverable: true,
        ));
        return;
      }

      final hasPermission = result.fold((l) => throw l, (r) => r);
      if (!hasPermission) {
        emit(const LiveAssistantPermissionRequired(
          permissionType: 'microphone',
          message: 'Microphone permission is required for voice interaction',
        ));
      }
    } catch (e, s) {
      print('Error in _onCheckMicrophonePermission: $e\n$s');
      emit(LiveAssistantError(
        message: 'Failed to check microphone permission: ${e.toString()}',
        isRecoverable: true,
      ));
    }
  }
}
