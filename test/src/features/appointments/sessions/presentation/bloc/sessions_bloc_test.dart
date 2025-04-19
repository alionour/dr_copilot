import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
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
      expect(mockSessionsBloc.state, equals(SessionsInitial([])));
    });

    blocTest<MockSessionsBloc, SessionsState>(
      'emits [SessionsLoading] when UpdateSession is added',
      build: () => mockSessionsBloc,
      act: (bloc) {
        final sessionModel = SessionModel(
          id: '1',
          patientId: '123',
          price: 100.0,
          startDateTime: Timestamp.fromDate(DateTime.now()),
          endDateTime:
              Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
          sessionType: SessionType.standard,
          userId: 'user_1',
          createdBy: 'admin',
        );
        bloc.add(UpdateSession('1', sessionModel));
      },
      expect: () => [
        SessionsLoading([]),
        isA<SessionsSuccess>(),
      ],
    );

    blocTest<MockSessionsBloc, SessionsState>(
      'emits [SessionsLoading, SessionsSuccess] with message sessionDeleted when DeleteSession is added',
      build: () => mockSessionsBloc,
      act: (bloc) => bloc.add(DeleteSession('1')),
      expect: () => [
        SessionsLoading([]),
        isA<SessionsSuccess>(),
      ],
    );
  });
}
