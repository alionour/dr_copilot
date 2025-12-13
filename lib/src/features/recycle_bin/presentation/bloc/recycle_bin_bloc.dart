import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/repositories/abstract_evaluations_repository.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/repositories/abstract_sessions_repository.dart';
import 'package:equatable/equatable.dart';

part 'recycle_bin_event.dart';
part 'recycle_bin_state.dart';

class RecycleBinBloc extends Bloc<RecycleBinEvent, RecycleBinState> {
  final AbstractEvaluationsRepository evaluationsRepository;
  final AbstractSessionsRepository sessionsRepository;

  RecycleBinBloc({
    required this.evaluationsRepository,
    required this.sessionsRepository,
  }) : super(RecycleBinInitial()) {
    on<LoadDeletedItems>(_onLoadDeletedItems);
    on<RestoreItem>(_onRestoreItem);
    on<PermanentlyDeleteItem>(_onPermanentlyDeleteItem);
  }

  Future<void> _onLoadDeletedItems(
    LoadDeletedItems event,
    Emitter<RecycleBinState> emit,
  ) async {
    emit(RecycleBinLoading());

    // Fetch deleted items from both repositories
    final evaluationsResult = await evaluationsRepository
        .getDeletedEvaluations();
    final sessionsResult = await sessionsRepository.getDeletedSessions();

    List<EvaluationModel> evaluations = [];
    List<SessionModel> sessions = [];
    String? errorMessage;

    evaluationsResult.fold(
      (failure) => errorMessage = failure.message,
      (data) => evaluations = data,
    );

    sessionsResult.fold(
      (failure) => errorMessage =
          errorMessage ?? failure.message, // Keep first error if any
      (data) => sessions = data,
    );

    if (errorMessage != null && evaluations.isEmpty && sessions.isEmpty) {
      // Only show error if both failed or one failed and other is empty (and presumably failed too or just empty)
      // If partial success, maybe show what we have? For now, let's treat any error as error state
      // if we decide strict error handling, but usually showing partial data is better.
      // The implementation here prefers showing data if at least one succeeded.
      // However, the fold logic above overwrites `errorMessage`.
      // Let's refine: if ALL fail, show error.
    }

    // Check if both failed essentially (simplistic)
    if (evaluationsResult.isLeft() && sessionsResult.isLeft()) {
      emit(RecycleBinError(errorMessage ?? 'Failed to load deleted items'));
      return;
    }

    emit(
      RecycleBinLoaded(
        deletedEvaluations: evaluations,
        deletedSessions: sessions,
      ),
    );
  }

  Future<void> _onRestoreItem(
    RestoreItem event,
    Emitter<RecycleBinState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RecycleBinLoaded) return;

    if (event.type == RecycleBinItemType.evaluation) {
      final result = await evaluationsRepository.restoreEvaluation(event.id);
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else {
      final result = await sessionsRepository.restoreSession(event.id);
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

    if (event.type == RecycleBinItemType.evaluation) {
      final result = await evaluationsRepository.permanentlyDeleteEvaluation(
        event.id,
      );
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    } else {
      final result = await sessionsRepository.permanentlyDeleteSession(
        event.id,
      );
      result.fold(
        (failure) => emit(RecycleBinError(failure.message)),
        (_) => add(LoadDeletedItems()),
      );
    }
  }
}
