import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  
  // Optional: A callback to notify listeners when playing state changes
  Function(bool)? onStateChanged;

  TextToSpeechService() {
    _initTts();
  }

  void _initTts() {
    _flutterTts.setStartHandler(() {
      _isPlaying = true;
      onStateChanged?.call(_isPlaying);
    });

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      onStateChanged?.call(_isPlaying);
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      onStateChanged?.call(_isPlaying);
      debugPrint("TTS Error: $msg");
    });
    
    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      onStateChanged?.call(_isPlaying);
    });
  }

  /// Strips basic markdown characters from the text to make speech more natural
  String _stripMarkdown(String text) {
    // Remove headers (#)
    String stripped = text.replaceAll(RegExp(r'#+\s'), '');
    // Remove bold/italic (* and _)
    stripped = stripped.replaceAll(RegExp(r'[\*_]{1,2}'), '');
    // Remove code blocks
    stripped = stripped.replaceAll(RegExp(r'`{1,3}.*?`{1,3}', dotAll: true), 'code block');
    return stripped;
  }

  Future<void> speak(String text) async {
    // Stop any existing playback before starting new one
    if (_isPlaying) {
      await stop();
    }
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5); // Default rate
    await _flutterTts.setPitch(1.0);

    final cleanText = _stripMarkdown(text);
    await _flutterTts.speak(cleanText);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  bool get isPlaying => _isPlaying;
}
