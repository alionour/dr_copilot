part of 'evaluations_bloc.dart';

abstract class EvaluationsState extends Equatable {
  /// The list of evaluations.
  final List<EvaluationModel> evaluations;
  const EvaluationsState(this.evaluations);

  @override
  List<Object?> get props => [evaluations];
}

class EvaluationsInitial extends EvaluationsState {
  const EvaluationsInitial(super.evaluations);

  @override
  List<Object?> get props => [evaluations];
}

class EvaluationsLoading extends EvaluationsState {
  const EvaluationsLoading(super.evaluations);

  @override
  List<Object?> get props => [evaluations];
}

class EvaluationsLoadingMore extends EvaluationsState {
  const EvaluationsLoadingMore(super.evaluations);

  @override
  List<Object?> get props => [evaluations];
}

class EvaluationsLoaded extends EvaluationsState {
  const EvaluationsLoaded(super.evaluations);

  @override
  List<Object> get props => [evaluations];
}

class EvaluationsError extends EvaluationsState {
  final String? message;

  const EvaluationsError(super.evaluations, {this.message});

  @override
  List<Object?> get props => [evaluations, message];
}

class EvaluationsSuccess extends EvaluationsState {
  final String? message;

  const EvaluationsSuccess(super.evaluations, {this.message});

  @override
  List<Object?> get props => [evaluations, message];
}
