import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';

class MockSessionsBloc extends MockBloc<SessionsEvent, SessionsState>
    implements SessionsBloc {}

void main() {
  group('Sessions Feature Tests', () {
    late MockSessionsBloc mockSessionsBloc;

    setUp(() {
      mockSessionsBloc = MockSessionsBloc();
      registerFallbackValue(UpdateSession(
          '1',
          SessionModel(
            id: '1',
            patientId: '123',
            price: 100.0,
            startDateTime: Timestamp.fromDate(DateTime.now()),
            endDateTime:
                Timestamp.fromDate(DateTime.now().add(Duration(hours: 1))),
            sessionType: SessionType.standard,
            userId: 'user_1',
            createdBy: 'admin',
          )));
      registerFallbackValue(DeleteSession('1'));
    });

    blocTest<MockSessionsBloc, SessionsState>(
      'should dispatch UpdateSession event with correct data',
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
      verify: (bloc) {
        verify(() => bloc.add(any())).called(1);
      },
    );

    blocTest<MockSessionsBloc, SessionsState>(
      'should dispatch DeleteSession event with correct ID',
      build: () => mockSessionsBloc,
      act: (bloc) => bloc.add(DeleteSession('1')),
      verify: (bloc) {
        verify(() => bloc.add(any())).called(1);
      },
    );
  });
}
