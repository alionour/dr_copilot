part of 'financials_bloc.dart';

/// Base class for all financial events.
abstract class FinancialsEvent extends Equatable {
  const FinancialsEvent();
  @override
  List<Object?> get props => [];
}

/// Event to fetch all financial transactions.
class GetTransactionsEvent extends FinancialsEvent {
    final String? lastDocumentID;
  final int limit;

   const GetTransactionsEvent({this.lastDocumentID, this.limit = 20});

  @override
  List<Object?> get props => [lastDocumentID, limit];
}

/// Event to fetch all financial transactions.
class SearchTransactionsEvent extends FinancialsEvent {
  final String description;
  const SearchTransactionsEvent(this.description);
    @override
  List<Object?> get props => [description];
}

/// Event to add a new financial transaction.
class AddTransactionEvent extends FinancialsEvent {
  final TransactionModel transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to delete a financial transaction by ID.
class DeleteTransactionEvent extends FinancialsEvent {
  final String transactionId;

  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}


class GetTransactionsByDate extends FinancialsEvent {
  final DateTime date;


  const GetTransactionsByDate({
    required this.date,

  });

  @override
  List<Object?> get props => [date,];
}

class LoadMoreTransactions extends FinancialsEvent {
  final String query;
  final int? limit;
  final String? lastDocumentId;

  const LoadMoreTransactions(this.query, {this.lastDocumentId, this.limit});

  @override
  List<Object?> get props => [query, lastDocumentId, limit];
}


class UpdateTransactionEvent extends FinancialsEvent {
  final String transactionId;
  final TransactionModel model;

  const UpdateTransactionEvent(this.transactionId, this.model);

  @override
  List<Object> get props => [transactionId, model];
}
