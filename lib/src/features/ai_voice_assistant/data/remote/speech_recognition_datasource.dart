import 'dart:async';

import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';

class SpeechRecognitionDatasource {
  final Deepgram _deepgram;

  SpeechRecognitionDatasource(this._deepgram);

  Stream<String> startListening(
      Stream<List<int>> audioStream, String languageCode) {
    final sttStreamParams = {
      'language': languageCode,
      'encoding': 'linear16',
      'sample_rate': 16000,
    };

    final liveListener =
        _deepgram.listen.live(audioStream, queryParams: sttStreamParams);

    return liveListener.map((result) => result.transcript ?? '');
  }
}
