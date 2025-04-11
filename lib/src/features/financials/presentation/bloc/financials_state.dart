part of 'financials_bloc.dart';

/// Base class for all financial states.
abstract class FinancialsState extends Equatable {
  final List<TransactionModel> transactions;

  const FinancialsState(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

/// Initial state of the FinancialsBloc.
class FinancialsInitial extends FinancialsState {
  const FinancialsInitial(super.transactions);
}

/// State when financial transactions are being loaded.
class FinancialsLoading extends FinancialsState {
  const FinancialsLoading(super.transactions);
}

/// State when financial transactions are successfully loaded.
class TransactionsLoaded extends FinancialsState {
  const TransactionsLoaded(super.transactions);
}

/// State when a financial operation is successful.
class FinancialsSuccess extends FinancialsState {
  final String message;

  const FinancialsSuccess(super.transactions, {required this.message});

  @override
  List<Object?> get props => [message, transactions];
}

/// State when an error occurs in financial operations.
class FinancialsError extends FinancialsState {
  final String message;

  const FinancialsError(super.transactions, {required this.message});

  @override
  List<Object?> get props => [message, transactions];
}


class TransactionsLoadingMore extends FinancialsState {


  const TransactionsLoadingMore(super.transactions);

  @override
  List<Object?> get props => [transactions];
}
