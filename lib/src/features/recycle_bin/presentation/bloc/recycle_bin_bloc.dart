import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/repositories/abstract_calendar_events_repository.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/repositories/abstract_patients_repository.dart';
import 'package:easy_localization/easy_localization.dart';
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
      emit(RecycleBinError('permissionDenied'.tr()));
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
    int failureCount = 0;

    evaluationsResult.fold(
      (failure) {
        errorMessage = failure.message;
        failureCount++;
      },
      (data) => evaluations = data,
    );

    sessionsResult.fold(
      (failure) {
        errorMessage = errorMessage ?? failure.message;
        failureCount++;
      },
      (data) => sessions = data,
    );

    patientsResult.fold(
      (failure) {
        errorMessage = errorMessage ?? failure.message;
        failureCount++;
      },
      (data) => patients = data,
    );

    calendarEventsResult.fold(
      (failure) {
        errorMessage = errorMessage ?? failure.message;
        failureCount++;
      },
      (data) => calendarEvents = data,
    );

    // FAILURE TRACKING (2026-05-30): Track partial failures across 4 sources.
    // If ALL 4 fail → emit error. If only some fail → emit partial success
    // with a warning message so the user sees what they can.
    if (failureCount == 4) {
      emit(RecycleBinError(errorMessage ?? 'failedToLoadDeletedItems'.tr()));
      return;
    }

    emit(
      RecycleBinLoaded(
        deletedEvaluations: evaluations,
        deletedSessions: sessions,
        deletedPatients: patients,
        deletedCalendarEvents: calendarEvents,
        warningMessage:
            failureCount > 0 ? 'someItemsCouldNotBeLoaded'.tr() : null,
      ),
    );
  }

  /// BUG FIX (2026-05-30): Added permission check and localized error
  /// strings (`permissionDenied`, `failedToLoadDeletedItems`,
  /// `someItemsCouldNotBeLoaded`) instead of hardcoded English strings.
  Future<void> _onRestoreItem(
    RestoreItem event,
    Emitter<RecycleBinState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RecycleBinLoaded) return;
    if (!OwnerNotifier().hasPermission(AppPermission.restoreRecycleBinItem)) {
      emit(RecycleBinError('permissionDenied'.tr()));
      add(LoadDeletedItems());
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
      emit(RecycleBinError('permissionDenied'.tr()));
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
