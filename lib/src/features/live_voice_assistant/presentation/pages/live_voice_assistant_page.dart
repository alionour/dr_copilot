import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:lottie/lottie.dart';
import 'dart:io';
import '../widgets/dynamic_action_ui.dart';
import '../widgets/windows_voice_input_widget.dart';
import '../../domain/models/assistant_action_model.dart';
import '../bloc/live_assistant_bloc.dart';
import '../widgets/conversation_bubble_widget.dart';
import '../widgets/voice_controls_widget.dart';
import '../widgets/assistant_avatar_widget.dart';

/// Main page for the Live Voice Assistant feature
class LiveVoiceAssistantPage extends StatefulWidget {
  const LiveVoiceAssistantPage({
    super.key,
  });

  @override
  State<LiveVoiceAssistantPage> createState() => _LiveVoiceAssistantPageState();
}

class _LiveVoiceAssistantPageState extends State<LiveVoiceAssistantPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  // Dynamic UI state
  AssistantActionModel? _currentAction;
  String? _currentAIResponse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    try {
      // Initialize the assistant
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        context.read<LiveAssistantBloc>().add(
              InitializeLiveAssistantEvent(userId: user.uid),
            );
      }
    } catch (e, s) {
      print('Error in initState: $e\n$s');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text('liveVoiceAssistant'.tr()),
        leading: const Icon(Icons.mic),
        actions: [navMenuButton ?? const SizedBox()],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          BlocConsumer<LiveAssistantBloc, LiveAssistantState>(
            listener: (context, state) {
              if (state is LiveAssistantSessionActive) {
                _scrollToBottom();

                // Control animations based on state
                if (state.isListening) {
                  _pulseController.repeat();
                  _waveController.repeat();
                } else {
                  _pulseController.stop();
                  _waveController.stop();
                }

                // Update dynamic UI based on latest AI response
                if (state.messages.isNotEmpty) {
                  final lastMessage = state.messages.last;
                  if (!lastMessage.isUserMessage) {
                    // This is an AI response, check if it contains an action or question
                    _updateDynamicUI(lastMessage.content, null);
                  }
                }
              }

              // Show error messages
              if (state is LiveAssistantError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    action: state.isRecoverable
                        ? SnackBarAction(
                            label: 'Retry',
                            onPressed: () {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                context.read<LiveAssistantBloc>().add(
                                      InitializeLiveAssistantEvent(
                                          userId: user.uid),
                                    );
                              }
                            },
                          )
                        : null,
                  ),
                );
              }

              // Show permission dialog
              if (state is LiveAssistantPermissionRequired) {
                _showPermissionDialog(context, state.message);
              }
            },
            builder: (context, state) {
              return _buildBody(context, state);
            },
          ),
          // Floating Action Panel
          _buildFloatingActionPanel(context),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, LiveAssistantState state) {
    if (state is LiveAssistantInitial || state is LiveAssistantLoading) {
      return _buildLoadingView(state);
    }

    if (state is LiveAssistantReady) {
      return _buildReadyView(context);
    }

    if (state is LiveAssistantSessionActive) {
      return _buildActiveSessionView(context, state);
    }

    if (state is LiveAssistantError) {
      return _buildErrorView(context, state);
    }

    if (state is LiveAssistantPermissionRequired) {
      return _buildPermissionView(context, state);
    }

    return _buildLoadingView(state);
  }

  Widget _buildLoadingView(LiveAssistantState state) {
    String message = 'Initializing...';
    if (state is LiveAssistantLoading && state.message != null) {
      message = state.message!;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/voice_loading.json',
            width: 200,
            height: 200,
            errorBuilder: (context, error, stackTrace) {
              return const CircularProgressIndicator();
            },
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AssistantAvatarWidget(
            isActive: false,
            size: 120,
          ),
          const SizedBox(height: 32),
          Text(
            'Ready to assist you!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Start a voice conversation to get help with:\n• Adding patients\n• Scheduling sessions\n• Recording evaluations\n• Viewing data and reports',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                context.read<LiveAssistantBloc>().add(
                      StartVoiceSessionEvent(userId: user.uid),
                    );
              }
            },
            icon: const Icon(Icons.mic),
            label: const Text('Start Voice Session'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionView(
      BuildContext context, LiveAssistantSessionActive state) {
    return Column(
      children: [
        // Beautiful Status Bar with Gradient
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A11CB), // Purple gradient start
                Color(0xFF2575FC), // Blue gradient end
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Enhanced Avatar with Pulse Animation
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3),
                        blurRadius: state.isBusy ? 20 : 10,
                        spreadRadius: state.isBusy ? 5 : 2,
                      ),
                    ],
                  ),
                  child: AssistantAvatarWidget(
                    isActive: state.isBusy,
                    size: 50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            state.selectedAiModel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: state.isListening
                                  ? Colors.green
                                  : state.isSpeaking
                                      ? Colors.blue
                                      : state.isProcessing
                                          ? Colors.orange
                                          : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(state),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Icons
                Row(
                  children: [
                    if (state.isMuted)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.mic_off,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                      ),
                    if (state.isListening) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),

        // Main content area with conversation and dynamic UI
        Expanded(
          child: Row(
            children: [
              // Conversation area (left side)
              Expanded(
                flex: 3,
                child: state.messages.isEmpty
                    ? _buildEmptyConversationView(context)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length +
                            (state.currentPartialText != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < state.messages.length) {
                            return ConversationBubbleWidget(
                              message: state.messages[index],
                              isUser: state.messages[index].isUserMessage,
                            );
                          } else {
                            // Show partial text
                            return ConversationBubbleWidget.partial(
                              text: state.currentPartialText!,
                              isUser: true,
                            );
                          }
                        },
                      ),
              ),

              // Dynamic Action UI (right side)
              Expanded(
                flex: 2,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  child: DynamicActionUI(
                    currentAction: _currentAction,
                    aiResponse: _currentAIResponse,
                    onActionSubmit: _handleActionSubmit,
                    onUserResponse: _handleUserResponse,
                    onClearAction: _clearCurrentAction,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Voice controls
        VoiceControlsWidget(
          isListening: state.isListening,
          isSpeaking: state.isSpeaking,
          isProcessing: state.isProcessing,
          isMuted: state.isMuted,
          canReceiveInput: state.canReceiveVoiceInput,
          onStartListening: () {
            context.read<LiveAssistantBloc>().add(const StartListeningEvent());
          },
          onStopListening: () {
            context.read<LiveAssistantBloc>().add(const StopListeningEvent());
          },
          onCancelListening: () {
            context.read<LiveAssistantBloc>().add(const CancelListeningEvent());
          },
          onStopSpeaking: () {
            context.read<LiveAssistantBloc>().add(const StopSpeakingEvent());
          },
          onToggleMute: () {
            context.read<LiveAssistantBloc>().add(const ToggleMuteEvent());
          },
          onSendText: (text) {
            context.read<LiveAssistantBloc>().add(ProcessTextInputEvent(text));
          },
        ),

        // Windows voice input alternative (only shows on Windows)
        if (Platform.isWindows)
          WindowsVoiceInputWidget(
            isListening: state.isListening,
            onTextSubmitted: (text) {
              context
                  .read<LiveAssistantBloc>()
                  .add(ProcessTextInputEvent(text));
            },
          ),
      ],
    );
  }

  Widget _buildEmptyConversationView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Beautiful animated icon container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6A11CB), // Purple gradient start
                    Color(0xFF2575FC), // Blue gradient end
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.waving_hand,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to AI Assistant!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: <Color>[
                      Color(0xFF6A11CB), // Gradient start color
                      Color(0xFF2575FC), // Gradient end color
                    ],
                  ).createShader(
                    const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                  ),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation by tapping the microphone\nor typing your message below',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Quick action suggestions
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildSuggestionChip(
                  context,
                  'Ask about symptoms',
                  Icons.medical_services,
                ),
                _buildSuggestionChip(
                  context,
                  'Health advice',
                  Icons.health_and_safety,
                ),
                _buildSuggestionChip(
                  context,
                  'General questions',
                  Icons.help_outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(
      BuildContext context, String label, IconData icon) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          // Handle suggestion tap - could auto-fill text input
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(
                0xFFF0F0F0), // Light grey background like copilot chat
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF6A11CB).withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: const Color(0xFF6A11CB),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6A11CB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, LiveAssistantError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (state.isRecoverable) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    context.read<LiveAssistantBloc>().add(
                          InitializeLiveAssistantEvent(userId: user.uid),
                        );
                  }
                },
                child: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionView(
      BuildContext context, LiveAssistantPermissionRequired state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic_off,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Permission Required',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<LiveAssistantBloc>().add(
                      const RequestMicrophonePermissionEvent(),
                    );
              },
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  String _getStatusText(LiveAssistantSessionActive state) {
    if (state.isListening) return 'Listening...';
    if (state.isSpeaking) return 'Speaking...';
    if (state.isProcessing) return 'Processing...';
    if (state.isMuted) return 'Muted';
    return 'Ready';
  }

  Widget _buildFloatingActionPanel(BuildContext context) {
    return BlocBuilder<LiveAssistantBloc, LiveAssistantState>(
      builder: (context, state) {
        if (state is! LiveAssistantSessionActive) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: 100,
          right: 16,
          child: Column(
            children: [
              // AI Model Selection
              _buildActionButton(
                icon: Icons.psychology,
                label: 'AI Model',
                onTap: () =>
                    _showModelSelectionDialog(context, state.selectedAiModel),
                gradientColors: const [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
              const SizedBox(height: 12),

              // Voice Settings
              _buildActionButton(
                icon: Icons.settings_voice,
                label: 'Voice',
                onTap: () => _showVoiceSettingsDialog(context),
                gradientColors: const [Color(0xFF2575FC), Color(0xFF6A11CB)],
              ),
              const SizedBox(height: 12),

              // Clear Conversation
              _buildActionButton(
                icon: Icons.clear_all,
                label: 'Clear',
                onTap: () => context.read<LiveAssistantBloc>().add(
                      const ClearConversationEvent(),
                    ),
                gradientColors: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
              ),
              const SizedBox(height: 12),

              // End Session
              _buildActionButton(
                icon: Icons.stop_circle,
                label: 'End',
                onTap: () => context.read<LiveAssistantBloc>().add(
                      EndVoiceSessionEvent(state.session.id),
                    ),
                gradientColors: const [Color(0xFFE74C3C), Color(0xFFC0392B)],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required List<Color> gradientColors,
  }) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showModelSelectionDialog(BuildContext context, String currentModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select AI Model'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModelOption('GPT-4', currentModel, context),
            _buildModelOption('Claude', currentModel, context),
            _buildModelOption('Gemini', currentModel, context),
            _buildModelOption('MedPaLM', currentModel, context),
          ],
        ),
      ),
    );
  }

  Widget _buildModelOption(
      String model, String currentModel, BuildContext context) {
    final isSelected = model == currentModel;
    return ListTile(
      title: Text(model),
      leading: Radio<String>(
        value: model,
        groupValue: currentModel,
        onChanged: (value) {
          if (value != null) {
            // Add event to change model
            Navigator.of(context).pop();
          }
        },
      ),
      selected: isSelected,
    );
  }

  void _showVoiceSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Speech Rate'),
              subtitle: Slider(
                value: 1.0,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) {
                  // Handle speech rate change
                },
              ),
            ),
            ListTile(
              title: const Text('Voice Pitch'),
              subtitle: Slider(
                value: 1.0,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                onChanged: (value) {
                  // Handle pitch change
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog(BuildContext context, String message) {
    // Implementation for permission dialog
  }

  // Dynamic UI handlers
  void _handleActionSubmit(Map<String, dynamic> data) {
    // Process the submitted action data
    debugPrint('Action submitted: $data');

    // Clear the current action after submission
    setState(() {
      _currentAction = null;
      _currentAIResponse = null;
    });

    // You can add logic here to:
    // 1. Save the data to the database
    // 2. Navigate to relevant pages
    // 3. Show success messages
    // 4. Trigger other actions

    // Example: Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Action completed successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleUserResponse(String response) {
    // Handle user's text response to AI questions
    debugPrint('User response: $response');

    // Send the response to the AI for processing
    context.read<LiveAssistantBloc>().add(ProcessTextInputEvent(response));

    // Clear the current AI response since user has responded
    setState(() {
      _currentAIResponse = null;
    });
  }

  void _clearCurrentAction() {
    // Clear the current action/response
    setState(() {
      _currentAction = null;
      _currentAIResponse = null;
    });
  }

  // Method to update the dynamic UI based on AI responses
  void _updateDynamicUI(String aiResponse, AssistantActionModel? action) {
    // Parse the AI response to detect actions
    final detectedAction = _parseActionFromResponse(aiResponse);

    setState(() {
      _currentAIResponse = aiResponse;
      _currentAction = action ?? detectedAction;
    });
  }

  // Simple action detection from AI response
  AssistantActionModel? _parseActionFromResponse(String response) {
    final lowerResponse = response.toLowerCase();

    // Check for add patient intent
    if (lowerResponse.contains('add') &&
        (lowerResponse.contains('patient') ||
            lowerResponse.contains('new patient'))) {
      return AssistantActionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: 'current_session',
        actionType: AssistantActionType.addPatient,
        status: ActionExecutionStatus.pending,
        description: 'Add a new patient',
        parameters: {},
        requiresConfirmation: true,
        isConfirmed: false,
        createdAt: DateTime.now(),
      );
    }

    // Check for schedule session intent
    if ((lowerResponse.contains('schedule') || lowerResponse.contains('add')) &&
        (lowerResponse.contains('session') ||
            lowerResponse.contains('appointment'))) {
      return AssistantActionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: 'current_session',
        actionType: AssistantActionType.addSession,
        status: ActionExecutionStatus.pending,
        description: 'Schedule a new session',
        parameters: {},
        requiresConfirmation: true,
        isConfirmed: false,
        createdAt: DateTime.now(),
      );
    }

    // Check for create evaluation intent
    if ((lowerResponse.contains('create') || lowerResponse.contains('add')) &&
        lowerResponse.contains('evaluation')) {
      return AssistantActionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: 'current_session',
        actionType: AssistantActionType.addEvaluation,
        status: ActionExecutionStatus.pending,
        description: 'Create a new evaluation',
        parameters: {},
        requiresConfirmation: true,
        isConfirmed: false,
        createdAt: DateTime.now(),
      );
    }

    // Check for search patients intent
    if (lowerResponse.contains('search') && lowerResponse.contains('patient')) {
      return AssistantActionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: 'current_session',
        actionType: AssistantActionType.searchPatients,
        status: ActionExecutionStatus.pending,
        description: 'Search for patients',
        parameters: {},
        requiresConfirmation: false,
        isConfirmed: true,
        createdAt: DateTime.now(),
      );
    }

    // Check for view appointments intent
    if (lowerResponse.contains('view') &&
        (lowerResponse.contains('appointment') ||
            lowerResponse.contains('calendar'))) {
      return AssistantActionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: 'current_session',
        actionType: AssistantActionType.viewAppointments,
        status: ActionExecutionStatus.pending,
        description: 'View appointments',
        parameters: {},
        requiresConfirmation: false,
        isConfirmed: true,
        createdAt: DateTime.now(),
      );
    }

    // Check for view financials intent
    if (lowerResponse.contains('view') &&
        (lowerResponse.contains('financial') ||
            lowerResponse.contains('billing') ||
            lowerResponse.contains('payment'))) {
      return AssistantActionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: 'current_session',
        actionType: AssistantActionType.viewFinancials,
        status: ActionExecutionStatus.pending,
        description: 'View financial data',
        parameters: {},
        requiresConfirmation: false,
        isConfirmed: true,
        createdAt: DateTime.now(),
      );
    }

    return null; // No action detected
  }
}
