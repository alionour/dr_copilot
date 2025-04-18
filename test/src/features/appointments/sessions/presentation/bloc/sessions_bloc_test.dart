import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';

class MockSessionsBloc extends MockBloc<SessionsEvent, SessionsState>
    implements SessionsBloc {}

void main() {
  group('SessionsBloc Tests', () {
    late MockSessionsBloc mockSessionsBloc;

    setUp(() {
      mockSessionsBloc = MockSessionsBloc();
    });

    test('initial state should be SessionsInitial', () {
      expect(mockSessionsBloc.state, equals(SessionsInitial()));
    });

    blocTest<MockSessionsBloc, SessionsState>(
      'emits [SessionsLoading, SessionsUpdated] when UpdateSession is added',
      build: () => mockSessionsBloc,
      act: (bloc) {
        final sessionModel = SessionModel(
          id: '1',
          patientId: '123',
          price: 100.0,
          startDateTime: DateTime.now(),
          endDateTime: DateTime.now().add(Duration(hours: 1)),
          sessionType: SessionType.consultation,
        );
        bloc.add(UpdateSession('1', sessionModel));
      },
      expect: () => [
        SessionsLoading(),
        isA<SessionsUpdated>(),
      ],
    );

    blocTest<MockSessionsBloc, SessionsState>(
      'emits [SessionsLoading, SessionsDeleted] when DeleteSession is added',
      build: () => mockSessionsBloc,
      act: (bloc) => bloc.add(DeleteSession('1')),
      expect: () => [
        SessionsLoading(),
        isA<SessionsDeleted>(),
      ],
    );
  });
}
