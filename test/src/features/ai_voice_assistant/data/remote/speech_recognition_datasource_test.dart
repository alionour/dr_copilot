import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'speech_recognition_datasource_test.mocks.dart';

@GenerateMocks([SpeechToText])
void main() {
  late MockSpeechToText mockSpeechToText;
  late SpeechRecognitionDatasource datasource;

  setUp(() {
    mockSpeechToText = MockSpeechToText();
    datasource = SpeechRecognitionDatasource(mockSpeechToText);
  });

  group('SpeechRecognitionDatasource', () {
    test('should return true when initialize is successful', () async {
      // arrange
      when(mockSpeechToText.initialize()).thenAnswer((_) async => true);
      // act
      final result = await datasource.initialize();
      // assert
      expect(result, true);
    });

    test('should call listen on speechToText when startListening is called', () {
      // arrange
      when(mockSpeechToText.listen(onResult: anyNamed('onResult'))).thenReturn(null);
      // act
      datasource.startListening(onResult: (_) {});
      // assert
      verify(mockSpeechToText.listen(onResult: anyNamed('onResult')));
    });

    test('should call stop on speechToText when stopListening is called', () {
      // arrange
      when(mockSpeechToText.stop()).thenReturn(null);
      // act
      datasource.stopListening();
      // assert
      verify(mockSpeechToText.stop());
    });

    test('should return true when hasPermission is true', () async {
      // arrange
      when(mockSpeechToText.hasPermission()).thenAnswer((_) async => true);
      // act
      final result = await datasource.hasPermission();
      // assert
      expect(result, true);
    });
  });
}
