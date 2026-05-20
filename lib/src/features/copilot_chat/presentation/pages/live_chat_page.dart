import 'package:dr_copilot/src/features/copilot_chat/data/services/live_chat_service.dart';
import 'package:dr_copilot/src/features/copilot_chat/presentation/bloc/copilot_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/function_call_handler.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:math';
import 'dart:async';
import 'package:dr_copilot/src/features/patients/presentation/pages/add_patient_page.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LiveChatPage extends StatefulWidget {
  const LiveChatPage({super.key});

  @override
  State<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends State<LiveChatPage>
    with SingleTickerProviderStateMixin {
  late LiveChatService _liveChatService;
  late AnimationController _visualizerController;

  String _lastTranscript = "";
  String? _activeFormType;
  Map<String, dynamic>? _activeFormData;
  String? _lastUsedModel; // Track which model was used

  @override
  void initState() {
    super.initState();
    _liveChatService = GetIt.instance<LiveChatService>();
    _visualizerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat();

    // Setup AI response callback
    _liveChatService.onGenerateResponse = _generateAIResponse;

    // Start session
    _liveChatService.startSession();
  }

  Future<String> _generateAIResponse(String query) async {
    final completer = Completer<String>();
    final bloc = context.read<CopilotBloc>();

    StreamSubscription? sub;
    sub = bloc.stream.listen((state) async {
      if (state is CopilotResponseGenerated) {
        if (!completer.isCompleted) {
          completer.complete(state.response);
          setState(() {
            _lastUsedModel = state.usedModel; // Capture the model name
          });
          sub?.cancel();
        }
      } else if (state is CopilotFunctionCall) {
        // Handle function call locally for Live Chat
        if (!completer.isCompleted) {
          final ownerNotifier =
              Provider.of<OwnerNotifier>(context, listen: false);
          final handler = FunctionCallHandler(
            patientsUseCase: GetIt.instance<PatientsUseCase>(),
            sessionsUseCase: GetIt.instance<SessionsUseCase>(),
            evaluationsUseCase: GetIt.instance<EvaluationsUseCase>(),
            ownerNotifier: ownerNotifier,
            permissionService: GetIt.instance<PermissionService>(),
          );

          final result = await handler.handleFunctionCall(state.functionCall);

          // Convert result map to speakable string
          String spokenResponse = "";
          if (result.containsKey('error')) {
            spokenResponse = "Error: ${result['error']}";
          } else if (result.containsKey('message')) {
            spokenResponse = result['message'];
          } else if (result.containsKey('sessions')) {
            final list = result['sessions'] as List;
            spokenResponse = list.isEmpty
                ? "No sessions found for today."
                : "I found ${list.length} sessions.";
          } else if (result.containsKey('patients')) {
            final list = result['patients'] as List;
            spokenResponse = list.isEmpty
                ? "No patients found."
                : "I found ${list.length} patients.";
          } else {
            spokenResponse = "I have executed the action.";
          }

          // We complete the future with the *tool result* so the AI speaks it.
          completer.complete(spokenResponse);
          sub?.cancel();
        }
      } else if (state is CopilotGroqFunctionCall) {
        // Handle Groq function call for Live Chat
        if (!completer.isCompleted) {
          final groqCall = state.functionCall;
          debugPrint('[LiveChat] Groq Function Call: ${groqCall.name}');
          debugPrint('[LiveChat] Function Args: ${groqCall.arguments}');

          // Convert GroqFunctionCall to standard FunctionCall
          final functionCall = FunctionCall(groqCall.name, groqCall.arguments);

          final ownerNotifier =
              Provider.of<OwnerNotifier>(context, listen: false);
          final handler = FunctionCallHandler(
            patientsUseCase: GetIt.instance<PatientsUseCase>(),
            sessionsUseCase: GetIt.instance<SessionsUseCase>(),
            evaluationsUseCase: GetIt.instance<EvaluationsUseCase>(),
            ownerNotifier: ownerNotifier,
            permissionService: GetIt.instance<PermissionService>(),
          );

          final result = await handler.handleFunctionCall(functionCall);
          debugPrint('[LiveChat] Function Result: $result');

          // Convert result map to speakable string
          String spokenResponse = "";
          if (result.containsKey('error')) {
            spokenResponse = "Error: ${result['error']}";
          } else if (result.containsKey('message')) {
            // This handles prompts like "What is the name?"
            spokenResponse = result['message'];
          } else if (result.containsKey('sessions')) {
            final list = result['sessions'] as List;
            spokenResponse = list.isEmpty
                ? "No sessions found for today."
                : "I found ${list.length} sessions.";
          } else if (result.containsKey('patients')) {
            final list = result['patients'] as List;
            spokenResponse = list.isEmpty
                ? "No patients found."
                : "I found ${list.length} patients.";
          } else if (result.containsKey('evaluations')) {
            final list = result['evaluations'] as List;
            spokenResponse = list.isEmpty
                ? "No evaluations found."
                : "I found ${list.length} evaluations.";
          } else {
            spokenResponse = "I have executed the action.";
          }

          debugPrint('[LiveChat] Speaking: $spokenResponse');
          completer.complete(spokenResponse);
          sub?.cancel();
        }
      } else if (state is CopilotFormRequested) {
        // For Live Chat, show form inline instead of executing
        if (!completer.isCompleted) {
          setState(() {
            _activeFormType = state.formType;
            _activeFormData = state.initialData;
          });
          // Speak a prompt to let user know the form is ready
          completer.complete(
              "I have prepared the form for you. Please review and confirm.");
          sub?.cancel();
        }
      } else if (state is CopilotError) {
        if (!completer.isCompleted) {
          completer.complete("Sorry, I encountered an error: ${state.error}");
          sub?.cancel();
        }
      }
    });

    final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final forcePremium = context.read<SettingsBloc>().state.usePremiumModels;

    bloc.add(GenerateResponseEvent(
      query: query,
      messageHistory: [], // Live chat maybe transient or we pass recent context?
      clinicId: ownerNotifier.clinicId ?? '',
      userId: userId,
      forcePremium: forcePremium,
      activeFormContext: _activeFormType != null
          ? {
              'formType': _activeFormType,
              'formData': _activeFormData,
            }
          : null,
    ));

    // Increase timeout to 30 seconds to accommodate slow models/cold starts
    return completer.future.timeout(const Duration(seconds: 30), onTimeout: () {
      sub?.cancel();
      // Don't just return an error string, maybe return a polite fallback
      return "I'm still thinking, but it's taking a while. Please wait a moment.";
    });
  }

  @override
  void dispose() {
    _liveChatService.stopSession();
    _liveChatService.onGenerateResponse = null;
    _visualizerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use theme colors
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final visualizer = _buildVisualizer(theme, isDark);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use theme background
      body: SafeArea(
        child: _activeFormData != null
            ? Row(
                children: [
                  // Visualizer on the left (or top on mobile?)
                  // For now, assume desktop/tablet where side-by-side makes sense
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: theme.dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: visualizer,
                    ),
                  ),
                  // Form on the right
                  Expanded(
                    flex: 1,
                    child: _buildFormView(),
                  ),
                ],
              )
            : visualizer,
      ),
    );
  }

  Widget _buildVisualizer(ThemeData theme, bool isDark) {
    return Stack(
      children: [
        // Close Button
        Positioned(
          top: 16,
          left: 16,
          child: IconButton(
            icon: Icon(Icons.close,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                size: 30),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),

        // Debug Model Label (bottom-left)
        if (kDebugMode && _lastUsedModel != null)
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.greenAccent.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Text(
                'Model: $_lastUsedModel',
                style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

        // Main Visualizer Area
        Center(
          child: StreamBuilder<LiveChatState>(
            stream: _liveChatService.stateStream,
            initialData: LiveChatState.idle,
            builder: (context, snapshot) {
              final state = snapshot.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildStatusIcon(state),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(state),
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Visualizer
                  SizedBox(
                    height: 100,
                    child: AnimatedBuilder(
                      animation: _visualizerController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(5, (index) {
                            // Simple simulated waveform
                            final isActive = state == LiveChatState.speaking ||
                                state == LiveChatState.listening;
                            final value = isActive
                                ? sin((_visualizerController.value * 2 * pi) +
                                    (index * 1))
                                : 0.0;
                            final height = 20 + (value.abs() * 60);

                            return Container(
                              width: 10,
                              height: height,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(state),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Transcript Preview
                  StreamBuilder<String>(
                    stream: _liveChatService.transcriptStream,
                    builder: (context, transSnapshot) {
                      if (transSnapshot.hasData) {
                        _lastTranscript = transSnapshot.data!;
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          _lastTranscript,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(LiveChatState state) {
    switch (state) {
      case LiveChatState.listening:
        return const Icon(Icons.mic, color: Colors.blueAccent, size: 16);
      case LiveChatState.processing:
        return const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.purpleAccent));
      case LiveChatState.speaking:
        return const Icon(Icons.volume_up, color: Colors.greenAccent, size: 16);
      default:
        return const Icon(Icons.circle, color: Colors.grey, size: 16);
    }
  }

  String _getStatusText(LiveChatState state) {
    switch (state) {
      case LiveChatState.listening:
        return "Listening...";
      case LiveChatState.processing:
        return "Thinking...";
      case LiveChatState.speaking:
        return "Speaking...";
      case LiveChatState.idle:
        return "Ready";
    }
  }

  Color _getStatusColor(LiveChatState state) {
    switch (state) {
      case LiveChatState.listening:
        return Colors.blueAccent;
      case LiveChatState.processing:
        return Colors.purpleAccent;
      case LiveChatState.speaking:
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFormView() {
    if (_activeFormType == null || _activeFormData == null) {
      return const SizedBox();
    }

    Widget formWidget;
    if (_activeFormType == 'add_patient' || _activeFormType == 'edit_patient') {
      PatientModel? patient;
      if (_activeFormType == 'edit_patient' && _activeFormData!['id'] != null) {
        patient = PatientModel(
          id: _activeFormData!['id'],
          name: _activeFormData!['name'] ?? '',
          age: _activeFormData!['age'] is int
              ? _activeFormData!['age']
              : int.tryParse(_activeFormData!['age']?.toString() ?? ''),
          gender: _activeFormData!['gender'],
          address: _activeFormData!['address'],
          phone1: _activeFormData!['phoneNumber'],
          phone2: _activeFormData!['alternativePhoneNumber'],
          treatingDoctorId: _activeFormData!['treatingDoctor'],
          occupation: _activeFormData!['occupation'],
          ownerId: '',
          clinicId: '',
          createdAt: Timestamp.now(),
        );
      }
      formWidget = Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: AddPatientPage(
          initialData: _activeFormData!,
          patient: patient,
          showScaffold: false,
          onSuccess: () {
            _closeForm();
            _liveChatService.speak(patient != null
                ? "Patient updated successfully."
                : "Patient added successfully.");
          },
          onCancel: _closeForm,
          onFormDataChange: (data) {
            // Update data WITHOUT setState to avoid rebuilding the form
            _activeFormData = data;
          },
        ),
      );
    } else {
      formWidget = Center(
        child: Text('Form type "$_activeFormType" not yet implemented'),
      );
    }

    // AddPatientPage already has Scaffold with back button
    return formWidget;
  }

  void _closeForm() {
    setState(() {
      _activeFormType = null;
      _activeFormData = null;
    });
    // Ensure Live Chat is listening again, restarting if needed
    _liveChatService.resume();
  }
}
