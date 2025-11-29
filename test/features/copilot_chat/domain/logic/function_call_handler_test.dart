import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/copilot_chat/domain/logic/function_call_handler.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([
  PatientsUseCase,
  SessionsUseCase,
  EvaluationsUseCase,
  BuildContext,
  OwnerNotifier,
])
import 'function_call_handler_test.mocks.dart';

void main() {
  late FunctionCallHandler handler;
  late MockPatientsUseCase mockPatientsUseCase;
  late MockSessionsUseCase mockSessionsUseCase;
  late MockEvaluationsUseCase mockEvaluationsUseCase;

  late MockOwnerNotifier mockOwnerNotifier;

  setUp(() {
    mockPatientsUseCase = MockPatientsUseCase();
    mockSessionsUseCase = MockSessionsUseCase();
    mockEvaluationsUseCase = MockEvaluationsUseCase();

    mockOwnerNotifier = MockOwnerNotifier();

    handler = FunctionCallHandler(
      patientsUseCase: mockPatientsUseCase,
      sessionsUseCase: mockSessionsUseCase,
      evaluationsUseCase: mockEvaluationsUseCase,
      ownerNotifier: mockOwnerNotifier,
    );
  });

  test('FunctionCallHandler should be initialized', () {
    expect(handler, isNotNull);
  });
}
