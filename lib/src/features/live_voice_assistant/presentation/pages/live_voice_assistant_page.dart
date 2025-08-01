import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:lottie/lottie.dart';
import '../bloc/live_assistant_bloc.dart';
import '../widgets/conversation_bubble_widget.dart';
import '../widgets/voice_controls_widget.dart';
import '../widgets/assistant_avatar_widget.dart';

/// Main page for the Live Voice Assistant feature
class LiveVoiceAssistantPage extends StatefulWidget {
  const LiveVoiceAssistantPage({super.key});

  @override
  State<LiveVoiceAssistantPage> createState() => _LiveVoiceAssistantPageState();
}

class _LiveVoiceAssistantPageState extends State<LiveVoiceAssistantPage>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

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

    // Initialize the assistant
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      context.read<LiveAssistantBloc>().add(
            InitializeLiveAssistantEvent(userId: user.uid),
          );
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Live Voice Assistant'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          BlocBuilder<LiveAssistantBloc, LiveAssistantState>(
            builder: (context, state) {
              if (state is LiveAssistantSessionActive) {
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'change_model':
                        _showModelSelectionDialog(
                            context, state.selectedAiModel);
                        break;
                      case 'voice_settings':
                        _showVoiceSettingsDialog(context);
                        break;
                      case 'clear_conversation':
                        context.read<LiveAssistantBloc>().add(
                              const ClearConversationEvent(),
                            );
                        break;
                      case 'end_session':
                        context.read<LiveAssistantBloc>().add(
                              EndVoiceSessionEvent(state.session.id),
                            );
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'change_model',
                      child: Row(
                        children: [
                          Icon(Icons.psychology),
                          SizedBox(width: 8),
                          Text('Change AI Model'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'voice_settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_voice),
                          SizedBox(width: 8),
                          Text('Voice Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'clear_conversation',
                      child: Row(
                        children: [
                          Icon(Icons.clear_all),
                          SizedBox(width: 8),
                          Text('Clear Conversation'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'end_session',
                      child: Row(
                        children: [
                          Icon(Icons.stop),
                          SizedBox(width: 8),
                          Text('End Session'),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<LiveAssistantBloc, LiveAssistantState>(
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
        // Status bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              AssistantAvatarWidget(
                isActive: state.isBusy,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Assistant (${state.selectedAiModel})',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      _getStatusText(state),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (state.isMuted)
                Icon(
                  Icons.mic_off,
                  color: Theme.of(context).colorScheme.error,
                ),
            ],
          ),
        ),

        // Conversation area
        Expanded(
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
      ],
    );
  }

  Widget _buildEmptyConversationView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Start the conversation!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the microphone to speak or type a message',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
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

  void _showModelSelectionDialog(BuildContext context, String currentModel) {
    // Implementation for model selection dialog
  }

  void _showVoiceSettingsDialog(BuildContext context) {
    // Implementation for voice settings dialog
  }

  void _showPermissionDialog(BuildContext context, String message) {
    // Implementation for permission dialog
  }
}
