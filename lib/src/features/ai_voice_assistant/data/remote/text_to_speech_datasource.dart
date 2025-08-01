import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechDatasource {
  final FlutterTts _flutterTts;

  TextToSpeechDatasource(this._flutterTts);

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
