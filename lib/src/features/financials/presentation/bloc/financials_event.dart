part of 'financials_bloc.dart';


/// Base class for all financial events.
abstract class FinancialsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Event to fetch all financial transactions.
class GetFinancialsEvent extends FinancialsEvent {}

/// Event to add a new financial transaction.
class AddFinancialEvent extends FinancialsEvent {
  final TransactionModel transaction;

  AddFinancialEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to delete a financial transaction by ID.
class DeleteFinancialEvent extends FinancialsEvent {
  final String transactionId;

  DeleteFinancialEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}
