part of evaluations_bloc;

abstract class EvaluationsState extends Equatable {
  const EvaluationsState();

  @override
  List<Object> get props => [];
}

class EvaluationsInitial extends EvaluationsState {}

class EvaluationsLoading extends EvaluationsState {}

class EvaluationsLoaded extends EvaluationsState {
  final List<QueryDocumentSnapshot> evaluations;

  const EvaluationsLoaded(this.evaluations);

  @override
  List<Object> get props => [evaluations];
}

class EvaluationsError extends EvaluationsState {
  final String message;

  const EvaluationsError(this.message);

  @override
  List<Object> get props => [message];
}
