part of evaluations_bloc;

abstract class EvaluationsEvent extends Equatable {
  const EvaluationsEvent();

  @override
  List<Object> get props => [];
}

class LoadEvaluations extends EvaluationsEvent {}

class AddEvaluation extends EvaluationsEvent {
  final Map<String, dynamic> evaluationData;

  const AddEvaluation(this.evaluationData);

  @override
  List<Object> get props => [evaluationData];
}

class UpdateEvaluation extends EvaluationsEvent {
  final String evaluationId;
  final Map<String, dynamic> evaluationData;

  const UpdateEvaluation(this.evaluationId, this.evaluationData);

  @override
  List<Object> get props => [evaluationId, evaluationData];
}

class DeleteEvaluation extends EvaluationsEvent {
  final String evaluationId;

  const DeleteEvaluation(this.evaluationId);

  @override
  List<Object> get props => [evaluationId];
}
