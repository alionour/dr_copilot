import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/speech_recognition_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/data/remote/text_to_speech_datasource.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/models/command_model.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/correction_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/user_preferences_service.dart';
import 'package:dr_copilot/src/features/ai_voice_assistant/presentation/bloc/ai_voice_assistant_bloc.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';

class MockSpeechRecognitionDatasource extends Mock
    implements SpeechRecognitionDatasource {}

class MockTextToSpeechDatasource extends Mock
    implements TextToSpeechDatasource {}

class MockCommandParserService extends Mock implements CommandParserService {}

class MockAudioRecorder extends Mock implements AudioRecorder {}

class MockPatientsUseCase extends Mock implements PatientsUseCase {}

class MockSessionsUseCase extends Mock implements SessionsUseCase {}

class MockEvaluationsUseCase extends Mock implements EvaluationsUseCase {}

class MockFinancialsUseCase extends Mock implements FinancialsUseCase {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserPreferencesService extends Mock
    implements UserPreferencesService {}

class MockCorrectionService extends Mock implements CorrectionService {}

void main() {
  late AiVoiceAssistantBloc bloc;
  late MockSpeechRecognitionDatasource mockSpeechRecognitionDatasource;
  late MockTextToSpeechDatasource mockTextToSpeechDatasource;
  late MockCommandParserService mockCommandParserService;
  late MockAudioRecorder mockAudioRecorder;
  late MockPatientsUseCase mockPatientsUseCase;
  late MockSessionsUseCase mockSessionsUseCase;
  late MockEvaluationsUseCase mockEvaluationsUseCase;
  late MockFinancialsUseCase mockFinancialsUseCase;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUserPreferencesService mockUserPreferencesService;
  late MockCorrectionService mockCorrectionService;

  setUp(() {
    mockSpeechRecognitionDatasource = MockSpeechRecognitionDatasource();
    mockTextToSpeechDatasource = MockTextToSpeechDatasource();
    mockCommandParserService = MockCommandParserService();
    mockAudioRecorder = MockAudioRecorder();
    mockPatientsUseCase = MockPatientsUseCase();
    mockSessionsUseCase = MockSessionsUseCase();
    mockEvaluationsUseCase = MockEvaluationsUseCase();
    mockFinancialsUseCase = MockFinancialsUseCase();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUserPreferencesService = MockUserPreferencesService();
    mockCorrectionService = MockCorrectionService();

    bloc = AiVoiceAssistantBloc(
      mockSpeechRecognitionDatasource,
      mockTextToSpeechDatasource,
      mockCommandParserService,
      mockAudioRecorder,
      mockPatientsUseCase,
      mockSessionsUseCase,
      mockEvaluationsUseCase,
      mockFinancialsUseCase,
      mockFirebaseAuth,
      mockUserPreferencesService,
      mockCorrectionService,
    );
  });

  group('AiVoiceAssistantBloc', () {
    test('initial state is AiVoiceAssistantInitial', () {
      expect(bloc.state, const AiVoiceAssistantInitial());
    });

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantProcessing, AiVoiceAssistantAskingForInformation] when command is missing information',
      build: () {
        when(() => mockCommandParserService.parseCommand(any(), any(), any(), any()))
            .thenAnswer((_) async => {
                  'intent': 'ask_for_information',
                  'entities': {'question': 'For which patient?'}
                });
        when(() => mockTextToSpeechDatasource.speak(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessCommandEvent('schedule a session')),
      expect: () => [
        isA<AiVoiceAssistantProcessing>(),
        isA<AiVoiceAssistantAskingForInformation>().having(
          (state) => state.question,
          'question',
          'For which patient?',
        ),
      ],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantProcessing, AiVoiceAssistantIdle] when command is conversational chat',
      build: () {
        when(() => mockCommandParserService.parseCommand(any(), any(), any(), any()))
            .thenAnswer((_) async => {
                  'intent': 'conversational_chat',
                  'entities': {'response': 'Hello there!'}
                });
        when(() => mockTextToSpeechDatasource.speak(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessCommandEvent('hello')),
      expect: () => [
        isA<AiVoiceAssistantProcessing>(),
        isA<AiVoiceAssistantIdle>(),
      ],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantProcessing, AiVoiceAssistantCommandConfirmation] when command is schedule_session and a single patient is found',
      build: () {
        when(() => mockCommandParserService.parseCommand(any(), any(), any(), any()))
            .thenAnswer((_) async => {
                  'intent': 'schedule_session',
                  'entities': {
                    'patient_name': 'John Doe',
                    'date': '2025-08-09',
                    'time': '10:00'
                  }
                });
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessCommandEvent(
          'schedule a session for John Doe tomorrow at 10am')),
      expect: () => [
        isA<AiVoiceAssistantProcessing>(),
        isA<AiVoiceAssistantCommandConfirmation>(),
      ],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantProcessing, AiVoiceAssistantPatientSelection] when command is schedule_session and multiple patients are found',
      build: () {
        when(() => mockCommandParserService.parseCommand(any(), any(), any(), any()))
            .thenAnswer((_) async => {
                  'intent': 'schedule_session',
                  'entities': {
                    'patient_name': 'John Doe',
                    'date': '2025-08-09',
                    'time': '10:00'
                  }
                });
        when(() => mockPatientsUseCase.searchPatients(name: 'John Doe'))
            .thenAnswer((_) async => const Right([
                  PatientModel(id: '1', name: 'John Doe'),
                  PatientModel(id: '2', name: 'John Doe'),
                ]));
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessCommandEvent(
          'schedule a session for John Doe tomorrow at 10am')),
      expect: () => [
        isA<AiVoiceAssistantProcessing>(),
        isA<AiVoiceAssistantPatientSelection>(),
      ],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantProcessing, AiVoiceAssistantAskingForInformation] when command is schedule_session and no patients are found',
      build: () {
        when(() => mockCommandParserService.parseCommand(any(), any(), any(), any()))
            .thenAnswer((_) async => {
                  'intent': 'schedule_session',
                  'entities': {
                    'patient_name': 'John Doe',
                    'date': '2025-08-09',
                    'time': '10:00'
                  }
                });
        when(() => mockPatientsUseCase.searchPatients(name: 'John Doe'))
            .thenAnswer((_) async => const Right([]));
        when(() => mockTextToSpeechDatasource.speak(any())).thenAnswer((_) async {});
        return bloc;
      },
      act: (bloc) => bloc.add(const ProcessCommandEvent(
          'schedule a session for John Doe tomorrow at 10am')),
      expect: () => [
        isA<AiVoiceAssistantProcessing>(),
        isA<AiVoiceAssistantAskingForInformation>(),
      ],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'calls _executeCommand when ConfirmCommandEvent is added',
      build: () {
        when(() => mockCommandParserService.generateResponse(any()))
            .thenAnswer((_) async => 'Success!');
        when(() => mockTextToSpeechDatasource.speak(any())).thenAnswer((_) async {});
        when(() => mockPatientsUseCase.addPatient(any())).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const ConfirmCommandEvent(Command(
        intent: 'add_patient',
        entities: {
          'name': 'John Doe',
          'age': 30,
          'phone': '1234567890',
          'address': '123 Main St',
          'gender': 'Male',
        },
      ))),
      verify: (_) {
        verify(() => mockPatientsUseCase.addPatient(any())).called(1);
      },
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantIdle] when CancelCommandEvent is added',
      build: () => bloc,
      act: (bloc) => bloc.add(CancelCommandEvent()),
      expect: () => [isA<AiVoiceAssistantIdle>()],
    );

    blocTest<AiVoiceAssistantBloc, AiVoiceAssistantState>(
      'emits [AiVoiceAssistantCommandConfirmation] when SelectPatientEvent is added',
      build: () => bloc,
      act: (bloc) => bloc.add(const SelectPatientEvent(PatientModel(id: '1', name: 'John Doe'))),
      expect: () => [isA<AiVoiceAssistantCommandConfirmation>()],
    );
  });
}
