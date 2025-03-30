library evaluations_bloc;

import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:equatable/equatable.dart';

part 'evaluations_event.dart';
part 'evaluations_state.dart';

class EvaluationsBloc extends Bloc<EvaluationsEvent, EvaluationsState> {
  final EvaluationsUseCase _useCase;

  EvaluationsBloc(this._useCase) : super(EvaluationsInitial()) {
    on<LoadEvaluations>(_onLoadEvaluations);
    on<AddEvaluation>(_onAddEvaluation);
    on<UpdateEvaluation>(_onUpdateEvaluation);
    on<DeleteEvaluation>(_onDeleteEvaluation);
    add(LoadEvaluations());
  }

  Future<void> _onLoadEvaluations(
      LoadEvaluations event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading());
    try {
      final evaluations = await _useCase.getEvaluations();
      emit(EvaluationsLoaded(evaluations));
    } catch (e) {
      emit(EvaluationsLoadFailure(e.toString()));
    }
  }

  Future<void> _onAddEvaluation(
      AddEvaluation event, Emitter<EvaluationsState> emit) async {
    try {
      await _useCase.addEvaluation(event.evaluationModel);
      add(LoadEvaluations());
    } catch (e) {
      emit(EvaluationsLoadFailure(e.toString()));
    }
  }

  Future<void> _onUpdateEvaluation(
      UpdateEvaluation event, Emitter<EvaluationsState> emit) async {
    try {
      await _useCase.updateEvaluation(event.evaluationModel);
      add(LoadEvaluations());
    } catch (e) {
      emit(EvaluationsLoadFailure(e.toString()));
    }
  }

  Future<void> _onDeleteEvaluation(
      DeleteEvaluation event, Emitter<EvaluationsState> emit) async {
    try {
      await _useCase.deleteEvaluation(event.id);
      add(LoadEvaluations());
    } catch (e) {
      emit(EvaluationsLoadFailure(e.toString()));
    }
  }
}
