import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'text_to_speech_datasource_test.mocks.dart';

@GenerateMocks([FlutterTts])
void main() {
  late MockFlutterTts mockFlutterTts;
  late TextToSpeechDatasource datasource;

  setUp(() {
    mockFlutterTts = MockFlutterTts();
    datasource = TextToSpeechDatasource(mockFlutterTts);
  });

  group('TextToSpeechDatasource', () {
    test('should call speak on flutterTts when speak is called', () async {
      // arrange
      when(mockFlutterTts.speak(any)).thenAnswer((_) async => null);
      // act
      await datasource.speak('hello');
      // assert
      verify(mockFlutterTts.speak('hello'));
    });

    test('should call stop on flutterTts when stop is called', () async {
      // arrange
      when(mockFlutterTts.stop()).thenAnswer((_) async => null);
      // act
      await datasource.stop();
      // assert
      verify(mockFlutterTts.stop());
    });
  });
}
