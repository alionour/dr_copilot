import 'package:flutter/material.dart';
import 'package:avatar_glow/avatar_glow.dart';

/// Widget that provides voice control buttons and text input
class VoiceControlsWidget extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isProcessing;
  final bool isMuted;
  final bool canReceiveInput;
  final VoidCallback onStartListening;
  final VoidCallback onStopListening;
  final VoidCallback onCancelListening;
  final VoidCallback onStopSpeaking;
  final VoidCallback onToggleMute;
  final Function(String) onSendText;

  const VoiceControlsWidget({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.isProcessing,
    required this.isMuted,
    required this.canReceiveInput,
    required this.onStartListening,
    required this.onStopListening,
    required this.onCancelListening,
    required this.onStopSpeaking,
    required this.onToggleMute,
    required this.onSendText,
  });

  @override
  State<VoiceControlsWidget> createState() => _VoiceControlsWidgetState();
}

class _VoiceControlsWidgetState extends State<VoiceControlsWidget> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _showTextInput = false;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showTextInput) _buildTextInput(),
            const SizedBox(height: 16),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendTextMessage,
            ),
          ),
          IconButton(
            onPressed: () => _sendTextMessage(_textController.text),
            icon: const Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute/Unmute button
        _buildControlButton(
          icon: widget.isMuted ? Icons.mic_off : Icons.mic,
          onPressed: widget.onToggleMute,
          color: widget.isMuted
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.outline,
          tooltip: widget.isMuted ? 'Unmute' : 'Mute',
        ),

        // Text input toggle
        _buildControlButton(
          icon: _showTextInput ? Icons.keyboard_hide : Icons.keyboard,
          onPressed: () {
            setState(() {
              _showTextInput = !_showTextInput;
              if (_showTextInput) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _textFocusNode.requestFocus();
                });
              }
            });
          },
          color: _showTextInput
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
          tooltip: _showTextInput ? 'Hide keyboard' : 'Show keyboard',
        ),

        // Main voice button
        _buildMainVoiceButton(),

        // Stop speaking button (only visible when speaking)
        if (widget.isSpeaking)
          _buildControlButton(
            icon: Icons.stop,
            onPressed: widget.onStopSpeaking,
            color: Theme.of(context).colorScheme.error,
            tooltip: 'Stop speaking',
          )
        else
          const SizedBox(width: 48), // Placeholder to maintain layout

        // Cancel button (only visible when listening)
        if (widget.isListening)
          _buildControlButton(
            icon: Icons.close,
            onPressed: widget.onCancelListening,
            color: Theme.of(context).colorScheme.error,
            tooltip: 'Cancel',
          )
        else
          const SizedBox(width: 48), // Placeholder to maintain layout
      ],
    );
  }

  Widget _buildMainVoiceButton() {
    IconData iconData;
    Color backgroundColor;
    Color iconColor;
    VoidCallback? onPressed;
    String tooltip;

    if (widget.isProcessing) {
      iconData = Icons.hourglass_empty;
      backgroundColor = Theme.of(context).colorScheme.outline;
      iconColor = Theme.of(context).colorScheme.onSurface;
      onPressed = null;
      tooltip = 'Processing...';
    } else if (widget.isListening) {
      iconData = Icons.mic;
      backgroundColor = Theme.of(context).colorScheme.error;
      iconColor = Theme.of(context).colorScheme.onError;
      onPressed = widget.onStopListening;
      tooltip = 'Stop listening';
    } else if (widget.isSpeaking) {
      iconData = Icons.volume_up;
      backgroundColor = Theme.of(context).colorScheme.primary;
      iconColor = Theme.of(context).colorScheme.onPrimary;
      onPressed = widget.onStopSpeaking;
      tooltip = 'Speaking...';
    } else if (widget.canReceiveInput) {
      iconData = Icons.mic;
      backgroundColor = Theme.of(context).colorScheme.primary;
      iconColor = Theme.of(context).colorScheme.onPrimary;
      onPressed = widget.onStartListening;
      tooltip = 'Start listening';
    } else {
      iconData = Icons.mic_off;
      backgroundColor = Theme.of(context).colorScheme.outline;
      iconColor = Theme.of(context).colorScheme.onSurface;
      onPressed = null;
      tooltip = 'Voice input unavailable';
    }

    Widget button = FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      foregroundColor: iconColor,
      elevation: 4,
      child: widget.isProcessing
          ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: iconColor,
              ),
            )
          : Icon(iconData, size: 28),
    );

    // Add glow effect when listening
    if (widget.isListening) {
      button = AvatarGlow(
        animate: true,
        glowColor: backgroundColor,
        duration: const Duration(milliseconds: 1500),
        repeat: true,
        child: button,
      );
    }

    return Tooltip(
      message: tooltip,
      child: button,
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: color,
        iconSize: 24,
      ),
    );
  }

  void _sendTextMessage(String text) {
    if (text.trim().isEmpty) return;

    widget.onSendText(text.trim());
    _textController.clear();

    // Hide text input after sending
    setState(() {
      _showTextInput = false;
    });
  }
}
