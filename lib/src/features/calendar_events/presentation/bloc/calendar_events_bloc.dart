import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/usecases/calendar_events_usecase.dart';
import 'package:equatable/equatable.dart';

part 'calendar_events_event.dart';
part 'calendar_events_state.dart';

/// BLoC for managing calendar events state
class CalendarEventsBloc
    extends Bloc<CalendarEventsEvent, CalendarEventsState> {
  final CalendarEventsUseCase useCase;

  CalendarEventsBloc(this.useCase) : super(CalendarEventsInitial()) {
    on<LoadEventsByDateRange>(_onLoadEventsByDateRange);
    on<LoadAllEvents>(_onLoadAllEvents);
    on<FilterByType>(_onFilterByType);
    on<AddCalendarEvent>(_onAddCalendarEvent);
    on<UpdateCalendarEvent>(_onUpdateCalendarEvent);
    on<DeleteCalendarEvent>(_onDeleteCalendarEvent);
    on<SearchEvents>(_onSearchEvents);
    on<LoadEventById>(_onLoadEventById);
    on<StreamEventsByDateRange>(_onStreamEventsByDateRange);
  }

  Future<void> _onStreamEventsByDateRange(
    StreamEventsByDateRange event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());
    await emit.forEach<Either<Failure, List<CalendarEventModel>>>(
      useCase.repository.streamEventsByDateRange(
        event.startDate,
        event.endDate,
      ),
      onData: (result) => result.fold(
        (failure) => CalendarEventsError(failure.message),
        (events) => CalendarEventsLoaded(events),
      ),
    );
  }

  Future<void> _onLoadEventsByDateRange(
    LoadEventsByDateRange event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    final result = await useCase.getEventsByDateRange(
      event.startDate,
      event.endDate,
    );

    result.fold(
      (failure) => emit(CalendarEventsError(failure.message)),
      (events) => emit(CalendarEventsLoaded(events)),
    );
  }

  Future<void> _onLoadAllEvents(
    LoadAllEvents event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    final result = await useCase.getAllEvents();

    result.fold(
      (failure) => emit(CalendarEventsError(failure.message)),
      (events) => emit(CalendarEventsLoaded(events)),
    );
  }

  Future<void> _onFilterByType(
    FilterByType event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    if (event.eventType == null || event.eventType!.isEmpty) {
      // Load all events if no filter
      final result = await useCase.getAllEvents();
      result.fold(
        (failure) => emit(CalendarEventsError(failure.message)),
        (events) => emit(CalendarEventsLoaded(events, filter: null)),
      );
    } else {
      final result = await useCase.getEventsByType(event.eventType!);
      result.fold(
        (failure) => emit(CalendarEventsError(failure.message)),
        (events) => emit(CalendarEventsLoaded(events, filter: event.eventType)),
      );
    }
  }

  Future<void> _onAddCalendarEvent(
    AddCalendarEvent event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    final result = await useCase.addEvent(event.event);

    result.fold((failure) => emit(CalendarEventsError(failure.message)), (
      createdEvent,
    ) {
      // Reload events after successful creation
      add(LoadAllEvents());
    });
  }

  Future<void> _onUpdateCalendarEvent(
    UpdateCalendarEvent event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    final result = await useCase.updateEvent(event.id, event.event);

    result.fold((failure) => emit(CalendarEventsError(failure.message)), (
      updatedEvent,
    ) {
      // Reload events after successful update
      add(LoadAllEvents());
    });
  }

  Future<void> _onDeleteCalendarEvent(
    DeleteCalendarEvent event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    final result = await useCase.deleteEvent(event.id);

    result.fold((failure) => emit(CalendarEventsError(failure.message)), (_) {
      // Reload events after successful deletion
      add(LoadAllEvents());
    });
  }

  Future<void> _onSearchEvents(
    SearchEvents event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    final result = await useCase.searchEvents(event.query);

    result.fold(
      (failure) => emit(CalendarEventsError(failure.message)),
      (events) => emit(CalendarEventsLoaded(events)),
    );
  }

  Future<void> _onLoadEventById(
    LoadEventById event,
    Emitter<CalendarEventsState> emit,
  ) async {
    emit(CalendarEventsLoading());

    final result = await useCase.getEventById(event.id);

    result.fold(
      (failure) => emit(CalendarEventsError(failure.message)),
      (eventModel) => emit(CalendarEventsLoaded([eventModel])),
    );
  }
}
