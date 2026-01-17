import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSessionsUseCase extends Mock implements SessionsUseCase {}

class MockFinancialsUseCase extends Mock implements FinancialsUseCase {}

class MockSessionModel extends Mock implements SessionModel {}

void main() {
  late MockSessionsUseCase mockSessionsUseCase;
  late MockFinancialsUseCase mockFinancialsUseCase;

  setUp(() {
    mockSessionsUseCase = MockSessionsUseCase();
    mockFinancialsUseCase = MockFinancialsUseCase();
  });

  group('SessionsBloc', () {
    test('initial state is SessionsInitial', () {
      expect(
        SessionsBloc(mockSessionsUseCase, mockFinancialsUseCase).state,
        const SessionsInitial([]),
      );
    });

    final tSession = MockSessionModel();
    final tSessionsList = [tSession];

    blocTest<SessionsBloc, SessionsState>(
      'emits [SessionsLoading, SessionsLoaded] when GetSessions succeeds',
      build: () {
        when(
          () => mockSessionsUseCase.getSessions(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Right(tSessionsList));
        return SessionsBloc(mockSessionsUseCase, mockFinancialsUseCase);
      },
      act: (bloc) => bloc.add(const GetSessions()),
      expect: () => [const SessionsLoading([]), SessionsLoaded(tSessionsList)],
    );

    blocTest<SessionsBloc, SessionsState>(
      'emits [SessionsLoading, SessionsError] when GetSessions fails',
      build: () {
        when(
          () => mockSessionsUseCase.getSessions(limit: any(named: 'limit')),
        ).thenAnswer((_) async => Left(ServerFailure('Error', 500)));
        return SessionsBloc(mockSessionsUseCase, mockFinancialsUseCase);
      },
      act: (bloc) => bloc.add(const GetSessions()),
      expect: () => [const SessionsLoading([]), isA<SessionsError>()],
    );
  });
}
