part of 'evaluations_bloc.dart';

abstract class EvaluationsEvent extends Equatable {
  const EvaluationsEvent();

  @override
  List<Object?> get props => [];
}

class GetEvaluations extends EvaluationsEvent {
  final String? lastDocumentID;
  final int limit;

  const GetEvaluations({this.lastDocumentID, this.limit = 20});

  @override
  List<Object?> get props => [lastDocumentID, limit];
}

class SearchEvaluations extends EvaluationsEvent {
  final String? name;

  const SearchEvaluations({this.name});

  @override
  List<Object?> get props => [name];
}

class AddEvaluation extends EvaluationsEvent {
  final EvaluationModel model;

  const AddEvaluation(this.model);

  @override
  List<Object> get props => [model];
}

class UpdateEvaluation extends EvaluationsEvent {
  final String evaluationId;
  final EvaluationModel model;

  const UpdateEvaluation(this.evaluationId, this.model);

  @override
  List<Object> get props => [evaluationId, model];
}

class DeleteEvaluation extends EvaluationsEvent {
  final String evaluationId;

  const DeleteEvaluation(this.evaluationId);

  @override
  List<Object> get props => [evaluationId];
}

class GetEvaluationsByDate extends EvaluationsEvent {
  final DateTime date;

  const GetEvaluationsByDate({required this.date});

  @override
  List<Object> get props => [date];
}

class LoadMoreEvaluations extends EvaluationsEvent {
  final String query;
  final int? limit;
  final String? lastDocumentId;

  const LoadMoreEvaluations(this.query, {this.lastDocumentId, this.limit});

  @override
  List<Object?> get props => [query, lastDocumentId, limit];
}
