import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/repositories/abstract_calendar_events_repository.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

part 'recycle_bin_event.dart';
part 'recycle_bin_state.dart';

class RecycleBinBloc extends Bloc<RecycleBinEvent, RecycleBinState> {
  final AbstractEvaluationsRepository evaluationsRepository;
  final AbstractSessionsRepository sessionsRepository;
  final AbstractPatientsRepository patientsRepository;
  final AbstractCalendarEventsRepository calendarEventsRepository;

  RecycleBinBloc({
    required this.evaluationsRepository,
    required this.sessionsRepository,
    required this.patientsRepository,
    required this.calendarEventsRepository,
  }) : super(RecycleBinInitial()) {
    on<LoadDeletedItems>(_onLoadDeletedItems);
    on<RestoreItem>(_onRestoreItem);
    on<PermanentlyDeleteItem>(_onPermanentlyDeleteItem);
  }

  Future<void> _onLoadDeletedItems(
    LoadDeletedItems event,
    Emitter<RecycleBinState> emit,
  ) async {
    if (!OwnerNotifier().hasPermission(AppPermission.viewRecycleBin)) {
      emit(const RecycleBinError('Permission denied'));
      return;
    }
    emit(RecycleBinLoading());

    // Fetch deleted items from all repositories
    final evaluationsResult =
        await evaluationsRepository.getDeletedEvaluations();
    final sessionsResult = await sessionsRepository.getDeletedSessions();
    final patientsResult = await patientsRepository.getDeletedPatients();
    final calendarEventsResult =
        await calendarEventsRepository.getDeletedEvents();

    List<EvaluationModel> evaluations = [];
    List<SessionModel> sessions = [];
    List<PatientModel> patients = [];
    List<CalendarEventModel> calendarEvents = [];
    String? errorMessage;

    evaluationsResult.fold(
      (failure) => errorMessage = failure.message,
      (data) => evaluations = data,
    );

    sessionsResult.fold(
      (failure) => errorMessage = errorMessage ?? failure.message,
      (data) => sessions = data,
    );

    patientsResult.fold(
      (failure) => errorMessage = errorMessage ?? failure.message,
      (data) => patients = data,
    );

    calendarEventsResult.fold(
      (failure) => errorMessage = errorMessage ?? failure.message,
      (data) => calendarEvents = data,
    );

    // Check if all failed
    if (evaluationsResult.isLeft() &&
        sessionsResult.isLeft() &&
        patientsResult.isLeft() &&
        calendarEventsResult.isLeft()) {
      emit(RecycleBinError(errorMessage ?? 'Failed to load deleted items'));
      return;
    }

    emit(
      RecycleBinLoaded(
        deletedEvaluations: evaluations,
        deletedSessions: sessions,
        deletedPatients: patients,
        deletedCalendarEvents: calendarEvents,
      ),
    );
  }

  Future<void> _onRestoreItem(
    RestoreItem event,
    Emitter<RecycleBinState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RecycleBinLoaded) return;
    if (!OwnerNotifier().hasPermission(AppPermission.restoreRecycleBinItem)) {
      emit(RecycleBinError('Permission denied'));
      add(LoadDeletedItems()); // Refresh to clear error state eventually or handle in UI
      return;
    }

    if (event.type == RecycleBinItemType.evaluation) {
      final result = await evaluationsRepository.restoreEvaluation(event.id);
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else if (event.type == RecycleBinItemType.session) {
      final result = await sessionsRepository.restoreSession(event.id);
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else if (event.type == RecycleBinItemType.patient) {
      final result = await patientsRepository.restorePatient(event.id);
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else if (event.type == RecycleBinItemType.calendarEvent) {
      final result = await calendarEventsRepository.restoreEvent(event.id);
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    }
  }

  Future<void> _onPermanentlyDeleteItem(
    PermanentlyDeleteItem event,
    Emitter<RecycleBinState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RecycleBinLoaded) return;
    if (!OwnerNotifier()
        .hasPermission(AppPermission.permanentDeleteRecycleBinItem)) {
      emit(RecycleBinError('Permission denied'));
      add(LoadDeletedItems());
      return;
    }

    if (event.type == RecycleBinItemType.evaluation) {
      final result = await evaluationsRepository.permanentlyDeleteEvaluation(
        event.id,
      );
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else if (event.type == RecycleBinItemType.session) {
      final result = await sessionsRepository.permanentlyDeleteSession(
        event.id,
      );
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else if (event.type == RecycleBinItemType.patient) {
      final result = await patientsRepository.permanentlyDeletePatient(
        event.id,
      );
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else if (event.type == RecycleBinItemType.calendarEvent) {
      final result = await calendarEventsRepository.permanentlyDeleteEvent(
        event.id,
      );
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    }
  }
}
