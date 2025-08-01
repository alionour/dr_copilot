import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'ai_voice_assistant_bloc_test.mocks.dart';

@GenerateMocks([
  SpeechRecognitionDatasource,
  TextToSpeechDatasource,
  CommandParserService
])
void main() {
  late MockSpeechRecognitionDatasource mockSpeechRecognitionDatasource;
  late MockTextToSpeechDatasource mockTextToSpeechDatasource;
  late MockCommandParserService mockCommandParserService;
  late AiVoiceAssistantBloc bloc;

  setUp(() {
    mockSpeechRecognitionDatasource = MockSpeechRecognitionDatasource();
    mockTextToSpeechDatasource = MockTextToSpeechDatasource();
    mockCommandParserService = MockCommandParserService();
    bloc = AiVoiceAssistantBloc(
      mockSpeechRecognitionDatasource,
      mockTextToSpeechDatasource,
      mockCommandParserService,
    );
  });

  group('AiVoiceAssistantBloc', () {
    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantListening] when StartListeningEvent is added and permission is granted',
      build: () {
        when(mockSpeechRecognitionDatasource.hasPermission())
            .thenAnswer((_) async => true);
        when(mockSpeechRecognitionDatasource.initialize())
            .thenAnswer((_) async => true);
        return bloc;
      },
      act: (bloc) => bloc.add(StartListeningEvent()),
      expect: () => [const AiVoiceAssistantListening('')],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantError] when StartListeningEvent is added and permission is not granted',
      build: () {
        when(mockSpeechRecognitionDatasource.hasPermission())
            .thenAnswer((_) async => false);
        return bloc;
      },
      act: (bloc) => bloc.add(StartListeningEvent()),
      expect: () => [const AiVoiceAssistantError('Microphone permission not granted.')],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantProcessing, AiVoiceAssistantSuccess] when ProcessCommandEvent is added',
      build: () {
        when(mockCommandParserService.parseCommand(any))
            .thenAnswer((_) async {});
        when(mockTextToSpeechDatasource.speak(any)).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessCommandEvent('test command')),
      expect: () => [
        AiVoiceAssistantProcessing(),
        const AiVoiceAssistantSuccess('Command processed successfully.'),
      ],
    );
  });
}
