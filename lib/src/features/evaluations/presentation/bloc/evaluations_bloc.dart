library evaluations_bloc;

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:equatable/equatable.dart';

part 'evaluations_event.dart';
part 'evaluations_state.dart';

class EvaluationsBloc extends Bloc<EvaluationsEvent, EvaluationsState> {
  final EvaluationsUseCase _evaluationsUseCase;

  EvaluationsBloc(this._evaluationsUseCase) : super(EvaluationsInitial()) {
    on<LoadEvaluations>(_onLoadEvaluations);
    on<AddEvaluation>(_onAddEvaluation);
    on<UpdateEvaluation>(_onUpdateEvaluation);
    on<DeleteEvaluation>(_onDeleteEvaluation);
  }

  void _onLoadEvaluations(
      LoadEvaluations event, Emitter<EvaluationsState> emit) {
    emit(EvaluationsLoading());
    _evaluationsUseCase.getEvaluations().listen((snapshot) {
      emit(EvaluationsLoaded(snapshot.docs));
    });
  }

  void _onAddEvaluation(
      AddEvaluation event, Emitter<EvaluationsState> emit) async {
    await _evaluationsUseCase.addEvaluation(event.evaluationData);
  }

  void _onUpdateEvaluation(
      UpdateEvaluation event, Emitter<EvaluationsState> emit) async {
    await _evaluationsUseCase.updateEvaluation(
        event.evaluationId, event.evaluationData);
  }

  void _onDeleteEvaluation(
      DeleteEvaluation event, Emitter<EvaluationsState> emit) async {
    await _evaluationsUseCase.deleteEvaluation(event.evaluationId);
  }
}
