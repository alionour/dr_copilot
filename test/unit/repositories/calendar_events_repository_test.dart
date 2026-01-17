import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/features/calendar_events/data/remote/calendar_events_firebase_api.dart';
import 'package:dr_copilot/src/features/calendar_events/data/repositories/calendar_events_repository_impl.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarEventsFirebaseApi extends Mock
    implements CalendarEventsFirebaseApi {}

class MockCalendarEventModel extends Mock implements CalendarEventModel {}

class FakeCalendarEventModel extends Fake implements CalendarEventModel {}

void main() {
  late CalendarEventsRepositoryImpl repository;
  late MockCalendarEventsFirebaseApi mockApi;

  setUpAll(() {
    registerFallbackValue(FakeCalendarEventModel());
  });

  setUp(() {
    mockApi = MockCalendarEventsFirebaseApi();
    repository = CalendarEventsRepositoryImpl(mockApi);
  });

  group('CalendarEventsRepositoryImpl', () {
    final tEvent = MockCalendarEventModel();
    final tEvents = [tEvent];

    test('getEventsByDateRange delegates to API', () async {
      final startDate = DateTime.now();
      final endDate = DateTime.now().add(const Duration(days: 1));

      when(() => mockApi.getEventsByDateRange(any(), any()))
          .thenAnswer((_) async => Right(tEvents));

      final result = await repository.getEventsByDateRange(startDate, endDate);

      verify(() => mockApi.getEventsByDateRange(startDate, endDate)).called(1);
      expect(result.isRight(), true);
    });

    test('addEvent delegates to API', () async {
      when(() => mockApi.addEvent(any()))
          .thenAnswer((_) async => Right(tEvent));

      final result = await repository.addEvent(tEvent);

      verify(() => mockApi.addEvent(tEvent)).called(1);
      expect(result.isRight(), true);
    });

    test('deleteEvent delegates to API', () async {
      const id = '123';
      when(() => mockApi.deleteEvent(id))
          .thenAnswer((_) async => const Right(null));

      final result = await repository.deleteEvent(id);

      verify(() => mockApi.deleteEvent(id)).called(1);
      expect(result.isRight(), true);
    });
  });
}
