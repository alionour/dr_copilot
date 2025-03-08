part of 'evaluations_bloc.dart';

abstract class EvaluationsState extends Equatable {
  const EvaluationsState();

  @override
  List<Object> get props => [];
}

class EvaluationsInitial extends EvaluationsState {}

class EvaluationsLoading extends EvaluationsState {}

class EvaluationsLoaded extends EvaluationsState {
  final List<EvaluationModel> evaluations;

  const EvaluationsLoaded(this.evaluations);

  @override
  List<Object> get props => [evaluations];
}

class EvaluationsLoadFailure extends EvaluationsState {
  final String error;

  const EvaluationsLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}
