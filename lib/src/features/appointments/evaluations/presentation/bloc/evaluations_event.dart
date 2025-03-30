part of 'evaluations_bloc.dart';

abstract class EvaluationsEvent extends Equatable {
  const EvaluationsEvent();

  @override
  List<Object> get props => [];
}

class LoadEvaluations extends EvaluationsEvent {}

class AddEvaluation extends EvaluationsEvent {
  final EvaluationModel evaluationModel;

  const AddEvaluation(this.evaluationModel);

  @override
  List<Object> get props => [evaluationModel];
}

class UpdateEvaluation extends EvaluationsEvent {
  final EvaluationModel evaluationModel;

  const UpdateEvaluation(this.evaluationModel);

  @override
  List<Object> get props => [evaluationModel];
}

class DeleteEvaluation extends EvaluationsEvent {
  final String id;

  const DeleteEvaluation(this.id);

  @override
  List<Object> get props => [id];
}
