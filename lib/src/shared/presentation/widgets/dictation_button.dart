import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get_it/get_it.dart';
import '../../../features/copilot_chat/data/services/abstract_speech_recognition_service.dart';

/// A reusable dictation button widget that enables voice-to-text input.
///
/// This widget provides a microphone button that starts/stops speech recognition
/// and streams the transcribed text back to the parent widget via [onTextTranscribed].
class DictationButton extends StatefulWidget {
  /// Callback fired when text is transcribed from speech
  final ValueChanged<String> onTextTranscribed;

  /// Optional icon to display (defaults to microphone icon)
  final IconData? icon;

  /// Optional size for the button
  final double? size;

  /// Whether the button is enabled
  final bool enabled;

  const DictationButton({
    super.key,
    required this.onTextTranscribed,
    this.icon,
    this.size,
    this.enabled = true,
  });

  @override
  State<DictationButton> createState() => _DictationButtonState();
}

class _DictationButtonState extends State<DictationButton>
    with SingleTickerProviderStateMixin {
  final AbstractSpeechRecognitionService _speechService =
      GetIt.instance<AbstractSpeechRecognitionService>();

  bool _isListening = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleDictation() async {
    if (!widget.enabled) return;

    if (_isListening) {
      // Stop listening
      final result = await _speechService.stopListening();
      result.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('dictationError'.tr())),
            );
          }
        },
        (finalText) {
          if (finalText.isNotEmpty) {
            widget.onTextTranscribed(finalText);
          }
        },
      );

      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    } else {
      // Start listening
      final initResult = await _speechService.initialize();

      initResult.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(failure.message)),
            );
          }
        },
        (_) async {
          final startResult = await _speechService.startListening();

          startResult.fold(
            (failure) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('dictationError'.tr())),
                );
              }
            },
            (_) {
              if (mounted) {
                setState(() {
                  _isListening = true;
                });

                // Listen to real-time transcription
                _speechService.getRealtimeRecognitionStream().listen(
                  (either) {
                    either.fold(
                      (failure) =>
                          debugPrint('Transcription error: ${failure.message}'),
                      (text) {
                        if (!text.startsWith('__FINAL__:')) {
                          // Real-time update
                          widget.onTextTranscribed(text);
                        }
                      },
                    );
                  },
                );
              }
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Icon(
            widget.icon ?? Icons.mic,
            color: _isListening
                ? Colors.red.withValues(
                    alpha: 0.5 + (_animationController.value * 0.5),
                  )
                : null,
            size: widget.size,
          );
        },
      ),
      onPressed: widget.enabled ? _toggleDictation : null,
      tooltip: _isListening ? 'stopDictation'.tr() : 'startDictation'.tr(),
    );
  }
}
