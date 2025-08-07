import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';

class TextToSpeechDatasource {
  final Deepgram _deepgram;

  TextToSpeechDatasource(this._deepgram);

  Future<DeepgramSpeakResult> speak(String text) async {
    return await _deepgram.speak.text(text, queryParams: {
      'model': 'aura-asteria-en',
    });
  }
}
