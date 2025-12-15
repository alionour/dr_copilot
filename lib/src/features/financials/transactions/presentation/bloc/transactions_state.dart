part of 'transactions_bloc.dart';

/// Base class for all financial states.
abstract class TransactionsState extends Equatable {
  final List<TransactionModel> transactions;

  const TransactionsState(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// Initial state of the TransactionsBloc.
class TransactionsInitial extends TransactionsState {
  const TransactionsInitial() : super(const []);
}

class TransactionsLoadingMore extends TransactionsState {
  const TransactionsLoadingMore(super.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// State representing that the count of transactions has been loaded.
class TransactionsCountLoaded extends TransactionsState {
  /// The total count of transactions.
  final int count;

  /// Creates a state with the loaded [count] and [transactions].
  const TransactionsCountLoaded(this.count, super.transactions);

  @override
  List<Object?> get props => [count, transactions];
}

/// State when financial transactions are successfully loaded.
class TransactionsLoaded extends TransactionsState {
  final bool isLoadingMore;
  const TransactionsLoaded(super.transactions, {this.isLoadingMore = false});

  @override
  List<Object> get props => [transactions, isLoadingMore];
}

/// State when financial transactions are being loaded.
class TransactionsLoading extends TransactionsState {
  const TransactionsLoading(super.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// State when a financial operation is successful.
class TransactionsSuccess extends TransactionsState {
  final String message;

  const TransactionsSuccess(super.transactions, {required this.message});

  @override
  List<Object?> get props => [message];
}

/// State when an error occurs in transactions operations.
class TransactionsError extends TransactionsState {
  final String message;

  const TransactionsError(super.transactions, {required this.message});

  @override
  List<Object?> get props => [super.transactions, message];
}

