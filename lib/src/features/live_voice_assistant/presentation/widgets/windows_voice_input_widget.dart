
import 'package:flutter/material.dart';

class WindowsVoiceInputWidget extends StatelessWidget {
  final bool isListening;
  final Function(String) onTextSubmitted;

  const WindowsVoiceInputWidget({
    super.key,
    required this.isListening,
    required this.onTextSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
