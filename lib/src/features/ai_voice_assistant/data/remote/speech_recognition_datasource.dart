import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechRecognitionDatasource {
  final stt.SpeechToText _speech;

  SpeechRecognitionDatasource(this._speech);

  Future<bool> initialize() async {
    return await _speech.initialize();
  }

  void startListening({required Function(String) onResult}) {
    _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
    );
  }

  void stopListening() {
    _speech.stop();
  }

  Future<bool> hasPermission() async {
    return await _speech.hasPermission;
  }
}
