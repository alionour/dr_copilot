part of 'transactions_bloc.dart';

/// Base class for all financial events.
abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();
  @override
  List<Object?> get props => [];
}

/// Event to fetch all financial transactions.
class GetTransactions extends TransactionsEvent {
  final String clinicId;
  final String? lastDocumentID;
  final int limit;

  const GetTransactions(
      {required this.clinicId, this.lastDocumentID, this.limit = 20});

  @override
  List<Object?> get props => [clinicId, lastDocumentID, limit];
}

/// Event to fetch all financial transactions.
class SearchTransactions extends TransactionsEvent {
  final String clinicId;
  final String description;
  const SearchTransactions({required this.clinicId, required this.description});
  @override
  List<Object?> get props => [clinicId, description];
}

/// Event to add a new financial transaction.
class AddTransactionEvent extends TransactionsEvent {
  final TransactionModel transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

/// Event to delete a financial transaction by ID.
class DeleteTransactionEvent extends TransactionsEvent {
  final String transactionId;

  const DeleteTransactionEvent(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class GetTransactionsByDate extends TransactionsEvent {
  final String clinicId;
  final DateTime date;

  const GetTransactionsByDate({
    required this.clinicId,
    required this.date,
  });

  @override
  List<Object?> get props => [clinicId, date];
}

class LoadMoreTransactions extends TransactionsEvent {
  final String clinicId;
  final int? limit;
  final String? lastDocumentId;

  const LoadMoreTransactions(
      {required this.clinicId, this.lastDocumentId, this.limit});

  @override
  List<Object?> get props => [clinicId, lastDocumentId, limit];
}

class UpdateTransactionEvent extends TransactionsEvent {
  final String transactionId;
  final TransactionModel model;

  const UpdateTransactionEvent(this.transactionId, this.model);

  @override
  List<Object> get props => [transactionId, model];
}

/// Event to trigger fetching the count of transactions.
///
/// This event can be dispatched to the [TransactionsBloc] to request
/// the current number of transactions available.
class GetTransactionsCount extends TransactionsEvent {
  final String clinicId;
  const GetTransactionsCount(this.clinicId);

  /// Returns a list of properties that will be used to determine whether two instances are equal.
  ///
  /// This override currently returns an empty list, meaning all instances will be considered equal
  /// unless this list is populated with relevant properties.
  @override
  List<Object?> get props => [clinicId];
}
