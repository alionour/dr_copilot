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
  final bool deleteInvoiceAndTransaction;

  const DeleteEvaluation(this.evaluationId, {this.deleteInvoiceAndTransaction = false});

  @override
  List<Object> get props => [evaluationId, deleteInvoiceAndTransaction];
}

class GetEvaluationsByDate extends EvaluationsEvent {
  final DateTime date;

  const GetEvaluationsByDate({required this.date});

  @override
  List<Object> get props => [date];
}

class LoadMoreEvaluations extends EvaluationsEvent {
  final int? limit;
  final String? lastDocumentId;

  const LoadMoreEvaluations({this.lastDocumentId, this.limit});

  @override
  List<Object?> get props => [lastDocumentId, limit];
}

class GetEvaluationsCount extends EvaluationsEvent {
  const GetEvaluationsCount();

  @override
  List<Object?> get props => [];
}



/// Event to add an invoice in the sessions feature.
///
/// This event is part of the `SessionsEvent` hierarchy and is used to trigger
/// the addition of a new invoice within the appointments or sessions context.
class AddInvoice extends EvaluationsEvent {
  final InvoiceModel invoice;

  final double? partialAmount;

  /// Constructor for the [AddInvoice] event.
  /// Takes an [InvoiceModel] object as a parameter.
  const AddInvoice(this.invoice, {this.partialAmount});

  @override
  List<Object?> get props => [invoice];
}

/// Event to add a transaction in the sessions feature.
///
/// This event is part of the `SessionsEvent` hierarchy and is used to
/// trigger the addition of a new transaction within the appointments
/// sessions context.
class AddTransaction extends EvaluationsEvent {
  final TransactionModel transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}
