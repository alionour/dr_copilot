import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';

class MockSessionsBloc extends Mock implements SessionsBloc {}

void main() {
  group('Sessions Feature Tests', () {
    late MockSessionsBloc mockSessionsBloc;

    setUp(() {
      mockSessionsBloc = MockSessionsBloc();
    });

    test('should dispatch UpdateSession event with correct data', () {
      final sessionModel = SessionModel(
        id: '1',
        patientId: '123',
        price: 100.0,
        startDateTime: DateTime.now(),
        endDateTime: DateTime.now().add(Duration(hours: 1)),
        sessionType: SessionType.consultation,
      );

      when(mockSessionsBloc.add(any)).thenReturn(null);

      mockSessionsBloc.add(UpdateSession('1', sessionModel));

      verify(mockSessionsBloc.add(UpdateSession('1', sessionModel))).called(1);
    });

    test('should dispatch DeleteSession event with correct ID', () {
      const sessionId = '1';

      when(mockSessionsBloc.add(any)).thenReturn(null);

      mockSessionsBloc.add(DeleteSession(sessionId));

      verify(mockSessionsBloc.add(DeleteSession(sessionId))).called(1);
    });
  });
}
