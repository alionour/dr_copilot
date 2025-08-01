import 'dart:convert';

import 'package:dr_copilot/src/features/ai_voice_assistant/domain/services/command_parser_service.dart';
import 'package:dr_copilot/src/features/copilot/services/gemini_service.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'command_parser_service_test.mocks.dart';

@GenerateMocks([GeminiService, PatientsUseCase, FirebaseAuth, User])
void main() {
  late MockGeminiService mockGeminiService;
  late MockPatientsUseCase mockPatientsUseCase;
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;
  late CommandParserService service;

  setUp(() {
    mockGeminiService = MockGeminiService();
    mockPatientsUseCase = MockPatientsUseCase();
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    service = CommandParserService(
        mockGeminiService, mockPatientsUseCase, mockFirebaseAuth);
  });

  group('CommandParserService', () {
    test(
        'should call addPatient on patientsUseCase when intent is add_patient',
        () async {
      // arrange
      final command = 'Add a new patient named John Doe, age 35';
      final jsonResponse = {
        "intent": "add_patient",
        "entities": {
          "name": "John Doe",
          "age": 35,
        }
      };
      final geminiResponse = GeminiResponse([TextPart(jsonEncode(jsonResponse))]);

      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('123');
      when(mockGeminiService.getGeminiResponse(any))
          .thenAnswer((_) async => geminiResponse);
      when(mockPatientsUseCase.addPatient(any))
          .thenAnswer((_) async => Right(PatientModel(id: '1', name: 'John Doe', userId: '123')));

      // act
      await service.parseCommand(command);

      // assert
      verify(mockGeminiService.getGeminiResponse(any));
      verify(mockPatientsUseCase.addPatient(any));
    });
  });
}
