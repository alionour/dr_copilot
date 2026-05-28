part of 'evaluations_bloc.dart';

abstract class EvaluationsState extends Equatable {
  /// The list of evaluations.
  final List<EvaluationModel> evaluations;
  final int? totalCount;
  const EvaluationsState(this.evaluations, {this.totalCount});

  @override
  List<Object?> get props => [evaluations, totalCount];
}

class EvaluationsInitial extends EvaluationsState {
  const EvaluationsInitial(super.evaluations, {super.totalCount});

  @override
  List<Object?> get props => [evaluations, totalCount];
}

class EvaluationsLoading extends EvaluationsState {
  const EvaluationsLoading(super.evaluations, {super.totalCount});

  @override
  List<Object?> get props => [evaluations, totalCount];
}

class EvaluationsLoadingMore extends EvaluationsState {
  const EvaluationsLoadingMore(super.evaluations, {super.totalCount});

  @override
  List<Object?> get props => [evaluations, totalCount];
}

class EvaluationsLoaded extends EvaluationsState {
  final bool isLoadingMore;

  const EvaluationsLoaded(super.evaluations, {this.isLoadingMore = false, super.totalCount});

  @override
  List<Object?> get props => [evaluations, isLoadingMore, totalCount];
}

class EvaluationsError extends EvaluationsState {
  final String? message;

  const EvaluationsError(super.evaluations, {this.message, super.totalCount});

  @override
  List<Object?> get props => [evaluations, message, totalCount];
}

class EvaluationsSuccess extends EvaluationsState {
  final String? message;

  const EvaluationsSuccess(super.evaluations, {this.message, super.totalCount});

  @override
  List<Object?> get props => [evaluations, message, totalCount];
}

class EvaluationsCountLoaded extends EvaluationsState {
  final int count;
  const EvaluationsCountLoaded(this.count, super.evaluations, {super.totalCount});

  @override
  List<Object?> get props => [count, evaluations, totalCount];
}

