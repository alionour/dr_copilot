import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:just_audio/just_audio.dart';

class TextToSpeechDatasource {
  final Deepgram _deepgram;
  final AudioPlayer _audioPlayer;

  TextToSpeechDatasource(this._deepgram, this._audioPlayer);

  Future<void> speak(String text) async {
    final result = await _deepgram.speak.text(text, queryParams: {
      'model': 'aura-asteria-en',
    });

    if (result.data != null) {
      await _audioPlayer.setAudioSource(MyCustomSource(result.data!));
      await _audioPlayer.play();
    }
  }
}

class MyCustomSource extends StreamAudioSource {
  final List<int> bytes;
  MyCustomSource(this.bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
      sourceLength: bytes.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(bytes.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
