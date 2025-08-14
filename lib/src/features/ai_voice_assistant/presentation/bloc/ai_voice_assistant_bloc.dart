import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/correction_model.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/correction_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/user_preferences_service.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

part 'ai_voice_assistant_event.dart';
part 'ai_voice_assistant_state.dart';

class AiVoiceAssistantBloc
    extends Bloc<AiVoiceAssistantEvent, AiVoiceAssistantState> {
  final SpeechRecognitionDatasource _speechRecognitionDatasource;
  final TextToSpeechDatasource _textToSpeechDatasource;
  final CommandParserService _commandParserService;
  final AudioRecorder _audioRecorder;
  final PatientsUseCase _patientsUseCase;
  final SessionsUseCase _sessionsUseCase;
  final EvaluationsUseCase _evaluationsUseCase;
  final FinancialsUseCase _financialsUseCase;
  final FirebaseAuth _firebaseAuth;
  final UserPreferencesService _userPreferencesService;
  final CorrectionService _correctionService;
  StreamSubscription<String>? _speechSubscription;
  Timer? _silenceTimer;

  AiVoiceAssistantBloc(
    this._speechRecognitionDatasource,
    this._textToSpeechDatasource,
    this._commandParserService,
    this._audioRecorder,
    this._patientsUseCase,
    this._sessionsUseCase,
    this._evaluationsUseCase,
    this._financialsUseCase,
    this._firebaseAuth,
    this._userPreferencesService,
    this._correctionService,
  ) : super(const AiVoiceAssistantInitial()) {
    on<StartListeningEvent>(_onStartListening);
    on<StopListeningEvent>(_onStopListening);
    on<TextChangedEvent>(_onTextChanged);
    on<ProcessCommandEvent>(_onProcessCommand);
    on<AddMessageToHistoryEvent>(_onAddMessageToHistory);
    on<ConfirmCommandEvent>(_onConfirmCommand);
    on<CancelCommandEvent>(_onCancelCommand);
    on<SelectPatientEvent>(_onSelectPatient);
    on<StartAssistantEvent>(_onStartAssistant);
    on<ToggleTranscriptVisibilityEvent>(_onToggleTranscriptVisibility);
  }

  void _onToggleTranscriptVisibility(ToggleTranscriptVisibilityEvent event,
      Emitter<AiVoiceAssistantState> emit) {
    emit(state.copyWith(isTranscriptVisible: !state.isTranscriptVisible));
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 17) {
      return 'Afternoon';
    } else {
      return 'Evening';
    }
  }

  Future<void> _onStartAssistant(
      StartAssistantEvent event, Emitter<AiVoiceAssistantState> emit) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return;
    }
    final userName = user.displayName ?? 'Doctor';
    final timeOfDay = _getTimeOfDay();
    final lang = _userPreferencesService.getLanguage();

    final greeting =
        await _commandParserService.generateGreeting(userName, timeOfDay, lang);
    add(AddMessageToHistoryEvent('AI: $greeting'));
    emit(AiVoiceAssistantSpeaking(greeting,
        recognizedText: state.recognizedText,
        conversationHistory: state.conversationHistory));
    await _textToSpeechDatasource.speak(greeting, lang);
  }

  @override
  void onEvent(AiVoiceAssistantEvent event) {
    super.onEvent(event);
    debugPrint('AiVoiceAssistantBloc: onEvent: $event');
  }

  @override
  void onTransition(
      Transition<AiVoiceAssistantEvent, AiVoiceAssistantState> transition) {
    super.onTransition(transition);
    debugPrint('AiVoiceAssistantBloc: onTransition: $transition');
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    _silenceTimer?.cancel();
    _audioRecorder.dispose();
    return super.close();
  }

  Future<void> _onStartListening(
      StartListeningEvent event, Emitter<AiVoiceAssistantState> emit) async {
    debugPrint('AiVoiceAssistantBloc: _onStartListening');
    try {
      final lang = _userPreferencesService.getLanguage();
      await _textToSpeechDatasource.speak("Hello, how can I help?", lang);
      if (await _audioRecorder.hasPermission()) {
        debugPrint('AiVoiceAssistantBloc: Microphone permission granted.');
        final audioStream = await _audioRecorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ));
        debugPrint('AiVoiceAssistantBloc: Audio stream started.');
        emit(AiVoiceAssistantListening(
            recognizedText: '',
            conversationHistory: state.conversationHistory,
            isTranscriptVisible: state.isTranscriptVisible));
        _startSilenceTimer();
        _speechSubscription = _speechRecognitionDatasource
            .startListening(audioStream, lang)
            .listen((text) {
          debugPrint('AiVoiceAssistantBloc: Received text from speech stream: $text');
          add(TextChangedEvent(text));
        }, onError: (error) {
          debugPrint('AiVoiceAssistantBloc: Error from speech stream: $error');
          add(AddMessageToHistoryEvent('Error: $error'));
          emit(AiVoiceAssistantError('Error from speech stream: $error',
              conversationHistory: state.conversationHistory,
              isTranscriptVisible: state.isTranscriptVisible));
        });
      } else {
        debugPrint('AiVoiceAssistantBloc: Microphone permission not granted.');
        add(const AddMessageToHistoryEvent(
            'Error: Microphone permission not granted.'));
        emit(AiVoiceAssistantError('Microphone permission not granted.',
            isTranscriptVisible: state.isTranscriptVisible));
      }
    } catch (e) {
      debugPrint('AiVoiceAssistantBloc: Error starting to listen: $e');
      add(AddMessageToHistoryEvent('Error: $e'));
      emit(AiVoiceAssistantError('Error starting to listen: $e',
          conversationHistory: state.conversationHistory,
          isTranscriptVisible: state.isTranscriptVisible));
    }
  }

  void _onStopListening(
      StopListeningEvent event, Emitter<AiVoiceAssistantState> emit) {
    debugPrint('AiVoiceAssistantBloc: _onStopListening');
    _audioRecorder.stop();
    _speechSubscription?.cancel();
    _silenceTimer?.cancel();
    if (state.recognizedText.isNotEmpty) {
      add(ProcessCommandEvent(state.recognizedText));
    }
    emit(AiVoiceAssistantIdle(
        recognizedText: state.recognizedText,
        conversationHistory: state.conversationHistory));
  }

  void _onTextChanged(
      TextChangedEvent event, Emitter<AiVoiceAssistantState> emit) {
    debugPrint('AiVoiceAssistantBloc: _onTextChanged: ${event.text}');
    _resetSilenceTimer();
    emit(AiVoiceAssistantListening(
        recognizedText: event.text,
        conversationHistory: state.conversationHistory));
  }

  Future<void> _onProcessCommand(
      ProcessCommandEvent event, Emitter<AiVoiceAssistantState> emit) async {
    debugPrint('AiVoiceAssistantBloc: _onProcessCommand: ${event.command}');
    if (event.command.isEmpty) {
      return;
    }
    add(AddMessageToHistoryEvent('You: ${event.command}'));
    emit(AiVoiceAssistantProcessing(
        recognizedText: state.recognizedText,
        conversationHistory: state.conversationHistory,
        partialCommand: state.partialCommand,
        originalCommand: state.originalCommand));
    try {
      final lang = _userPreferencesService.getLanguage();
      final commandJson = await _commandParserService.parseCommand(
          event.command,
          state.conversationHistory,
          state.partialCommand,
          _userPreferencesService,
          lang);
      debugPrint('AiVoiceAssistantBloc: Parsed command: $commandJson');
      final command = Command.fromJson(commandJson);

      if (state.partialCommand != null) {
        debugPrint('AiVoiceAssistantBloc: In conversation, merging commands.');
        // We are in a conversation, so we need to merge the new command with the partial command.
        final mergedEntities = {
          ...state.partialCommand!.entities,
          ...command.entities
        };
        final mergedCommand = Command(
            intent: state.partialCommand!.intent, entities: mergedEntities);
        debugPrint('AiVoiceAssistantBloc: Merged command: $mergedCommand');

        // Now we need to check if the merged command is complete.
        // For simplicity, I will assume it's complete and proceed to confirmation.
        // In a real app, I would need to check if all required entities are present.
        emit(AiVoiceAssistantCommandConfirmation(mergedCommand,
            recognizedText: state.recognizedText,
            conversationHistory: state.conversationHistory,
            originalCommand: state.originalCommand));
      } else {
        // This is a new command
        debugPrint('AiVoiceAssistantBloc: New command.');
        if (command.intent == 'ask_for_information') {
          debugPrint('AiVoiceAssistantBloc: Asking for information.');
          final question = command.entities['question'] as String;
          add(AddMessageToHistoryEvent('AI: $question'));
          emit(AiVoiceAssistantAskingForInformation(question,
              recognizedText: state.recognizedText,
              conversationHistory: state.conversationHistory,
              partialCommand: command,
              originalCommand: command));
          await _textToSpeechDatasource.speak(question, lang);
        } else if (command.intent == 'conversational_chat') {
          debugPrint('AiVoiceAssistantBloc: Conversational chat.');
          final response = command.entities['response'] as String;
          add(AddMessageToHistoryEvent('AI: $response'));
          await _textToSpeechDatasource.speak(response, lang);
          emit(AiVoiceAssistantIdle(
              recognizedText: state.recognizedText,
              conversationHistory: state.conversationHistory));
        } else {
          debugPrint('AiVoiceAssistantBloc: Command confirmation.');
          emit(AiVoiceAssistantCommandConfirmation(command,
              recognizedText: state.recognizedText,
              conversationHistory: state.conversationHistory,
              originalCommand: command));
        }
      }
    } catch (e) {
      debugPrint('AiVoiceAssistantBloc: Error processing command: $e');
      final errorMessage = 'Error processing command: $e';
      add(AddMessageToHistoryEvent('AI: $errorMessage'));
      emit(AiVoiceAssistantError(errorMessage,
          recognizedText: state.recognizedText,
          conversationHistory: state.conversationHistory));
      final lang = _userPreferencesService.getLanguage();
      await _textToSpeechDatasource.speak(errorMessage, lang);
    }
  }

  void _onAddMessageToHistory(
      AddMessageToHistoryEvent event, Emitter<AiVoiceAssistantState> emit) {
    final newHistory = List<String>.from(state.conversationHistory)
      ..add(event.message);
    emit(state.copyWith(conversationHistory: newHistory));
  }

  void _startSilenceTimer() {
    _silenceTimer = Timer(const Duration(seconds: 60), () {
      add(StopListeningEvent());
    });
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _startSilenceTimer();
  }

  Future<void> _onConfirmCommand(
      ConfirmCommandEvent event, Emitter<AiVoiceAssistantState> emit) async {
    final originalCommand = state.originalCommand;
    final correctedCommand = event.command;

    if (originalCommand != null && originalCommand != correctedCommand) {
      final correction = CorrectionModel(
        id: const Uuid().v4(),
        originalCommand: originalCommand,
        correctedCommand: correctedCommand,
        createdAt: DateTime.now(),
      );
      await _correctionService.saveCorrection(correction);
    }

    await _executeCommand(correctedCommand, emit);
  }

  void _onCancelCommand(
      CancelCommandEvent event, Emitter<AiVoiceAssistantState> emit) {
    emit(AiVoiceAssistantIdle(
        recognizedText: state.recognizedText,
        conversationHistory: state.conversationHistory));
  }

  Future<void> _onSelectPatient(
      SelectPatientEvent event, Emitter<AiVoiceAssistantState> emit) async {
    final patient = event.patient;
    final partialCommand = state.partialCommand;

    if (partialCommand != null) {
      final mergedEntities = {
        ...partialCommand.entities,
        'patient_name': patient.name,
        'patient_id': patient.id,
      };
      final mergedCommand =
          Command(intent: partialCommand.intent, entities: mergedEntities);

      emit(AiVoiceAssistantCommandConfirmation(mergedCommand,
          recognizedText: state.recognizedText,
          conversationHistory: state.conversationHistory));
    }
  }

  Future<void> _executeCommand(
      Command command, Emitter<AiVoiceAssistantState> emit) async {
    try {
      final intent = command.intent;
      final entities = command.entities;
      final lang = _userPreferencesService.getLanguage();

      switch (intent) {
        case 'add_patient':
          final user = _firebaseAuth.currentUser;
          if (user == null) {
            // Handle user not logged in
            return;
          }

          final patient = PatientModel(
            id: const Uuid().v4(),
            name: entities['name'],
            age: entities['age'],
            phoneNumber: entities['phone'],
            address: entities['address'],
            gender: entities['gender'],
            userId: user.uid,
          );
          await _patientsUseCase.addPatient(patient);
          final successMessage =
              await _commandParserService.generateResponse(command, lang);
          add(AddMessageToHistoryEvent('AI: $successMessage'));
          emit(AiVoiceAssistantSuccess(successMessage,
              recognizedText: state.recognizedText,
              conversationHistory: state.conversationHistory));
          await _textToSpeechDatasource.speak(successMessage, lang);
          break;
        case 'schedule_session':
          final patientId = entities['patient_id'];
          final patientName = entities['patient_name'];
          final date = entities['date'];
          final time = entities['time'];

          if (patientId != null) {
            // patient_id is available, no need to search
            final user = _firebaseAuth.currentUser;
            if (user == null) {
              return;
            }

            final duration = entities['duration'] as int? ??
                _userPreferencesService.getPreferredSessionDuration() ??
                60;
            final startDateTime = DateTime.parse('$date $time');
            final endDateTime =
                startDateTime.add(Duration(minutes: duration));

            final session = SessionModel(
              id: const Uuid().v4(),
              patientId: patientId,
              price: SessionType.standard.basePrice,
              startDateTime: Timestamp.fromDate(startDateTime),
              endDateTime: Timestamp.fromDate(endDateTime),
              sessionType: SessionType.standard,
              userId: user.uid,
              createdBy: user.uid,
              patientName: patientName,
            );
            await _sessionsUseCase.addSession(session);
            final successMessage =
                await _commandParserService.generateResponse(command, lang);
            add(AddMessageToHistoryEvent('AI: $successMessage'));
            emit(AiVoiceAssistantSuccess(successMessage,
                recognizedText: state.recognizedText,
                conversationHistory: state.conversationHistory));
            await _textToSpeechDatasource.speak(successMessage, lang);
          } else {
            // patient_id is not available, search by name
            final failureOrPatients =
                await _patientsUseCase.searchPatients(name: patientName);
            failureOrPatients.fold(
              (failure) {
                debugPrint('Error searching for patient: $failure');
                add(AddMessageToHistoryEvent(
                    'AI: Error searching for patient: $failure'));
              },
              (patients) async {
                if (patients.isEmpty) {
                  final question =
                      'I could not find a patient named $patientName. Would you like to add a new patient?';
                  add(AddMessageToHistoryEvent('AI: $question'));
                  emit(AiVoiceAssistantAskingForInformation(question,
                      recognizedText: state.recognizedText,
                      conversationHistory: state.conversationHistory,
                      partialCommand: command));
                  await _textToSpeechDatasource.speak(question, lang);
                } else if (patients.length == 1) {
                  final patient = patients.first;
                  final user = _firebaseAuth.currentUser;
                  if (user == null) {
                    return;
                  }

                  final duration = entities['duration'] as int? ??
                      _userPreferencesService.getPreferredSessionDuration() ??
                      60;
                  final startDateTime = DateTime.parse('$date $time');
                  final endDateTime =
                      startDateTime.add(Duration(minutes: duration));

                  final session = SessionModel(
                    id: const Uuid().v4(),
                    patientId: patient.id,
                    price: SessionType.standard.basePrice,
                    startDateTime: Timestamp.fromDate(startDateTime),
                    endDateTime: Timestamp.fromDate(endDateTime),
                    sessionType: SessionType.standard,
                    userId: user.uid,
                    createdBy: user.uid,
                    patientName: patient.name,
                  );
                  await _sessionsUseCase.addSession(session);
                  final successMessage =
                      await _commandParserService.generateResponse(
                          command, lang);
                  add(AddMessageToHistoryEvent('AI: $successMessage'));
                  emit(AiVoiceAssistantSuccess(successMessage,
                      recognizedText: state.recognizedText,
                      conversationHistory: state.conversationHistory));
                  await _textToSpeechDatasource.speak(successMessage, lang);
                } else {
                  // Multiple patients found, ask the user to select one.
                  emit(AiVoiceAssistantPatientSelection(patients,
                      recognizedText: state.recognizedText,
                      conversationHistory: state.conversationHistory,
                      partialCommand: command));
                }
              },
            );
          }
          break;
        case 'record_evaluation':
          final patientId = entities['patient_id'];
          final patientName = entities['patient_name'];
          final date = entities['date'];

          if (patientId != null) {
            // patient_id is available, no need to search
            final user = _firebaseAuth.currentUser;
            if (user == null) {
              return;
            }

            final startDateTime = DateTime.parse('$date 09:00:00');
            final endDateTime = startDateTime.add(const Duration(hours: 1));

            final evaluation = EvaluationModel(
              id: const Uuid().v4(),
              patientId: patientId,
              patientName: patientName,
              price: 200.0,
              startDateTime: Timestamp.fromDate(startDateTime),
              endDateTime: Timestamp.fromDate(endDateTime),
              userId: user.uid,
              createdBy: user.uid,
            );
            await _evaluationsUseCase.addEvaluation(evaluation);
            final successMessage =
                await _commandParserService.generateResponse(command, lang);
            add(AddMessageToHistoryEvent('AI: $successMessage'));
            emit(AiVoiceAssistantSuccess(successMessage,
                recognizedText: state.recognizedText,
                conversationHistory: state.conversationHistory));
            await _textToSpeechDatasource.speak(successMessage, lang);
          } else {
            // patient_id is not available, search by name
            final failureOrPatients =
                await _patientsUseCase.searchPatients(name: patientName);
            failureOrPatients.fold(
              (failure) {
                debugPrint('Error searching for patient: $failure');
                add(AddMessageToHistoryEvent(
                    'AI: Error searching for patient: $failure'));
              },
              (patients) async {
                if (patients.isEmpty) {
                  final question =
                      'I could not find a patient named $patientName. Would you like to add a new patient?';
                  add(AddMessageToHistoryEvent('AI: $question'));
                  emit(AiVoiceAssistantAskingForInformation(question,
                      recognizedText: state.recognizedText,
                      conversationHistory: state.conversationHistory,
                      partialCommand: command));
                  await _textToSpeechDatasource.speak(question, lang);
                } else if (patients.length == 1) {
                  final patient = patients.first;
                  final user = _firebaseAuth.currentUser;
                  if (user == null) {
                    return;
                  }

                  final startDateTime = DateTime.parse('$date 09:00:00');
                  final endDateTime =
                      startDateTime.add(const Duration(hours: 1));

                  final evaluation = EvaluationModel(
                    id: const Uuid().v4(),
                    patientId: patient.id,
                    patientName: patient.name,
                    price: 200.0,
                    startDateTime: Timestamp.fromDate(startDateTime),
                    endDateTime: Timestamp.fromDate(endDateTime),
                    userId: user.uid,
                    createdBy: user.uid,
                  );
                  await _evaluationsUseCase.addEvaluation(evaluation);
                  final successMessage =
                      await _commandParserService.generateResponse(
                          command, lang);
                  add(AddMessageToHistoryEvent('AI: $successMessage'));
                  emit(AiVoiceAssistantSuccess(successMessage,
                      recognizedText: state.recognizedText,
                      conversationHistory: state.conversationHistory));
                  await _textToSpeechDatasource.speak(successMessage, lang);
                } else {
                  // Multiple patients found, ask the user to select one.
                  emit(AiVoiceAssistantPatientSelection(patients,
                      recognizedText: state.recognizedText,
                      conversationHistory: state.conversationHistory,
                      partialCommand: command));
                }
              },
            );
          }
          break;
        case 'show_appointments':
          final dateString = entities['date'];
          DateTime date;
          if (dateString == 'today') {
            date = DateTime.now();
          } else if (dateString == 'tomorrow') {
            date = DateTime.now().add(const Duration(days: 1));
          } else {
            date = DateTime.parse(dateString);
          }

          final failureOrSessions =
              await _sessionsUseCase.getSessionsByDate(date);
          final failureOrEvaluations =
              await _evaluationsUseCase.getEvaluationsByDate(date);

          failureOrSessions.fold(
            (failure) => debugPrint('Error getting sessions: $failure'),
            (sessions) {
              failureOrEvaluations.fold(
                (failure) => debugPrint('Error getting evaluations: $failure'),
                (evaluations) {
                  final appointments = [...sessions, ...evaluations];
                  debugPrint('Appointments for $date:');
                  for (final appointment in appointments) {
                    debugPrint((appointment as dynamic).toJson());
                  }
                },
              );
            },
          );
          break;
        case 'show_revenue':
          final period = entities['period'];
          if (period == 'this month') {
            final now = DateTime.now();
            final firstDayOfMonth = DateTime(now.year, now.month, 1);
            final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

            final failureOrTransactions =
                await _financialsUseCase.getTransactions();
            failureOrTransactions.fold(
              (failure) => debugPrint('Error getting transactions: $failure'),
              (transactions) {
                final monthlyTransactions = transactions.where((t) {
                  final transactionDate = t.transactionDate.toDate();
                  return transactionDate.isAfter(firstDayOfMonth) &&
                      transactionDate.isBefore(lastDayOfMonth);
                }).toList();

                final totalRevenue = monthlyTransactions.fold<double>(
                    0, (sum, t) => sum + t.amount);
                debugPrint('Total revenue for this month: $totalRevenue');
              },
            );
          }
          break;
        case 'conversational_chat':
          // The response is already in the entities, so we just need to speak it.
          break;
        // TODO: Handle other intents
      }
    } catch (e) {
      final errorMessage = 'Error processing command: $e';
      add(AddMessageToHistoryEvent('AI: $errorMessage'));
      emit(AiVoiceAssistantError(errorMessage,
          recognizedText: state.recognizedText,
          conversationHistory: state.conversationHistory));
      final lang = _userPreferencesService.getLanguage();
      await _textToSpeechDatasource.speak(errorMessage, lang);
    }
  }
}

extension on AiVoiceAssistantState {
  AiVoiceAssistantState copyWith({
    List<String>? conversationHistory,
    String? recognizedText,
    Command? partialCommand,
    Command? originalCommand,
    bool? isTranscriptVisible,
  }) {
    if (this is AiVoiceAssistantInitial) {
      return AiVoiceAssistantInitial(
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantIdle) {
      return AiVoiceAssistantIdle(
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantListening) {
      return AiVoiceAssistantListening(
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantProcessing) {
      return AiVoiceAssistantProcessing(
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantSpeaking) {
      return AiVoiceAssistantSpeaking(
          (this as AiVoiceAssistantSpeaking).textToSpeak,
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantSuccess) {
      return AiVoiceAssistantSuccess((this as AiVoiceAssistantSuccess).message,
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantCommandConfirmation) {
      return AiVoiceAssistantCommandConfirmation(
          (this as AiVoiceAssistantCommandConfirmation).command,
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantAskingForInformation) {
      return AiVoiceAssistantAskingForInformation(
          (this as AiVoiceAssistantAskingForInformation).question,
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantPatientSelection) {
      return AiVoiceAssistantPatientSelection(
          (this as AiVoiceAssistantPatientSelection).patients,
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    } else if (this is AiVoiceAssistantError) {
      return AiVoiceAssistantError((this as AiVoiceAssistantError).message,
          recognizedText: recognizedText ?? this.recognizedText,
          conversationHistory:
              conversationHistory ?? this.conversationHistory,
          partialCommand: partialCommand ?? this.partialCommand,
          originalCommand: originalCommand ?? this.originalCommand,
          isTranscriptVisible: isTranscriptVisible ?? this.isTranscriptVisible);
    }
    return this;
  }
}
