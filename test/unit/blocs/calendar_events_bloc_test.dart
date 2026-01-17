import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/usecases/calendar_events_usecase.dart';
import 'package:dr_copilot/src/features/calendar_events/presentation/bloc/calendar_events_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCalendarEventsUseCase extends Mock implements CalendarEventsUseCase {}

class MockCalendarEventModel extends Mock implements CalendarEventModel {}

class FakeCalendarEventModel extends Fake implements CalendarEventModel {}

void main() {
  late MockCalendarEventsUseCase mockUseCase;

  setUpAll(() {
    registerFallbackValue(FakeCalendarEventModel());
  });

  setUp(() {
    mockUseCase = MockCalendarEventsUseCase();
  });

  group('CalendarEventsBloc', () {
    final tEvent = MockCalendarEventModel();
    final tEvents = [tEvent];

    blocTest<CalendarEventsBloc, CalendarEventsState>(
      'emits [CalendarEventsLoading, CalendarEventsLoaded] when LoadAllEvents succeeds',
      build: () {
        when(() => mockUseCase.getAllEvents())
            .thenAnswer((_) async => Right(tEvents));
        return CalendarEventsBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(LoadAllEvents()),
      expect: () => [
        CalendarEventsLoading(),
        CalendarEventsLoaded(tEvents),
      ],
    );

    blocTest<CalendarEventsBloc, CalendarEventsState>(
      'emits [CalendarEventsLoading, CalendarEventsError] when LoadAllEvents fails',
      build: () {
        when(() => mockUseCase.getAllEvents())
            .thenAnswer((_) async => Left(ServerFailure('Error', 500)));
        return CalendarEventsBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(LoadAllEvents()),
      expect: () => [
        CalendarEventsLoading(),
        CalendarEventsError('Error'),
      ],
    );

    blocTest<CalendarEventsBloc, CalendarEventsState>(
      'emits [CalendarEventsLoading] and triggers reload when AddCalendarEvent succeeds',
      build: () {
        when(() => mockUseCase.addEvent(any()))
            .thenAnswer((_) async => Right(tEvent));
        when(() => mockUseCase.getAllEvents())
            .thenAnswer((_) async => Right(tEvents)); // For subsequent reload
        return CalendarEventsBloc(mockUseCase);
      },
      act: (bloc) => bloc.add(AddCalendarEvent(tEvent)),
      verify: (_) {
        verify(() => mockUseCase.addEvent(tEvent)).called(1);
        // Cannot easily verify subsequent event dispatch with pure bloc_test verify without intricate stream listening,
        // but checking state flow implicitly confirms it if we saw loaded again.
        // However, bloc_test captures states from *the* triggered event. Nested events require `wait`.
      },
      // Since AddCalendarEvent triggers LoadAllEvents, we expect Loading from Add, then Loading from Load, then Loaded
      expect: () => [
        CalendarEventsLoading(), // From AddCalendarEvent start
        CalendarEventsLoading(), // From LoadAllEvents start
        CalendarEventsLoaded(tEvents), // From LoadAllEvents success
      ],
    );
  });
}
