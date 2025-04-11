part of 'financials_bloc.dart';

/// Base class for all financial events.
abstract class FinancialsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event to fetch all financial transactions.
class GetTransactionsEvent extends FinancialsEvent {}

/// Event to add a new financial transaction.
class AddTransactionEvent extends FinancialsEvent {
  final TransactionModel transaction;

  AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to delete a financial transaction by ID.
class DeleteTransactionEvent extends FinancialsEvent {
  final String transactionId;

  DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
