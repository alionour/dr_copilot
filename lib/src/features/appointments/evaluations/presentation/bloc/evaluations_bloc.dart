import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'evaluations_event.dart';
part 'evaluations_state.dart';

class EvaluationsBloc extends Bloc<EvaluationsEvent, EvaluationsState> {
  final EvaluationsUseCase _evaluationsUseCase;

  EvaluationsBloc(this._evaluationsUseCase)
      : super(const EvaluationsInitial([])) {
    on<GetEvaluations>(_onGetEvaluations);
    on<AddEvaluation>(_onAddEvaluation);
    on<UpdateEvaluation>(_onUpdateEvaluation);
    on<DeleteEvaluation>(_onDeleteEvaluation);
    on<SearchEvaluations>(_onSearchEvaluations);
    on<GetEvaluationsByDate>(_onGetEvaluationsByDate);
    on<LoadMoreEvaluations>(_onLoadMoreEvaluations);
  }

  void _onGetEvaluations(
      GetEvaluations event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluations = await _evaluationsUseCase.getEvaluations(
      lastDocumentID: event.lastDocumentID,
      limit: event.limit,
    );
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (evaluations) => EvaluationsLoaded(evaluations),
    ));
  }

  void _onAddEvaluation(
      AddEvaluation event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluation =
        await _evaluationsUseCase.addEvaluation(event.model);
    emit(failureOrEvaluation.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (addedEvaluation) {
        debugPrint('Add successful: $addedEvaluation');
        final evaluations = state.evaluations..add(addedEvaluation);
        emit(EvaluationsSuccess(evaluations,
            message: 'evaluationAddedSuccessfully'.tr()));
        return EvaluationsLoaded(evaluations);
      },
    ));
  }

  void _onUpdateEvaluation(
      UpdateEvaluation event, Emitter<EvaluationsState> emit) async {
    final failureOrEvaluation = await _evaluationsUseCase.updateEvaluation(
        event.evaluationId, event.model);
    emit(failureOrEvaluation.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (updatedEvaluation) {
        debugPrint('Update successful: $updatedEvaluation');
        final evaluations = state.evaluations.map((evaluation) {
          return evaluation.id == updatedEvaluation.id
              ? updatedEvaluation
              : evaluation;
        }).toList();
        emit(EvaluationsSuccess(evaluations,
            message: 'Evaluation updated successfully'));
        return EvaluationsLoaded(evaluations);
      },
    ));
  }

  Future<void> _onDeleteEvaluation(
      DeleteEvaluation event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluation =
        await _evaluationsUseCase.deleteEvaluation(event.evaluationId);
    emit(failureOrEvaluation.fold(
        (failure) => EvaluationsError(state.evaluations,
            message: _mapFailureToMessage(failure)), (deletedEvaluation) {
      debugPrint('Delete successful: ${event.evaluationId}');
      final evaluations = state.evaluations
        ..removeWhere((evaluation) => evaluation.id == event.evaluationId);
      emit(EvaluationsSuccess(evaluations,
          message: 'Evaluation deleted successfully'));
      return EvaluationsLoaded(evaluations);
    }));
  }

  Future<void> _onSearchEvaluations(
      SearchEvaluations event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluations =
        await _evaluationsUseCase.searchEvaluations(name: event.name);
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (evaluations) => EvaluationsLoaded(evaluations),
    ));
  }

  void _onGetEvaluationsByDate(
      GetEvaluationsByDate event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluations =
        await _evaluationsUseCase.getEvaluationsByDate(event.date);
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (evaluations) => EvaluationsLoaded(evaluations),
    ));
  }

  void _onLoadMoreEvaluations(
      LoadMoreEvaluations event, Emitter<EvaluationsState> emit) async {
    if (state is EvaluationsLoaded) {
      final currentState = state as EvaluationsLoaded;
      emit(EvaluationsLoadingMore(currentState.evaluations));

      final failureOrEvaluations = await _evaluationsUseCase.getEvaluations(
        lastDocumentID: event.lastDocumentId,
        limit: event.limit,
      );

      emit(failureOrEvaluations.fold(
        (failure) => EvaluationsError(currentState.evaluations,
            message: _mapFailureToMessage(failure)),
        (newEvaluations) {
          final allEvaluations =
              List<EvaluationModel>.from(currentState.evaluations)
                ..addAll(newEvaluations);
          return EvaluationsLoaded(allEvaluations);
        },
      ));
    }
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server Failure: ${failure.message}';
      case CacheFailure _:
        return 'Cache Failure: ${failure.message}';
      default:
        return 'Unexpected Error: ${failure.message}';
    }
  }
}
