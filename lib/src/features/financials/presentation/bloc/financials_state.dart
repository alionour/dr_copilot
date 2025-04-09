part of 'financials_bloc.dart';

/// Base class for all financial states.
abstract class FinancialsState extends Equatable {
  final List<TransactionModel> transactions;

  FinancialsState({this.transactions = const []});

  @override
  List<Object?> get props => [transactions];
}

/// Initial state of the FinancialsBloc.
class FinancialsInitial extends FinancialsState {}

/// State when financial transactions are being loaded.
class FinancialsLoading extends FinancialsState {}

/// State when financial transactions are successfully loaded.
class FinancialsLoaded extends FinancialsState {
  FinancialsLoaded(List<TransactionModel> transactions)
      : super(transactions: transactions);
}

/// State when a financial operation is successful.
class FinancialsSuccess extends FinancialsState {
  final String message;

  FinancialsSuccess(this.message,
      {List<TransactionModel> transactions = const []})
      : super(transactions: transactions);

  @override
  List<Object?> get props => [message, transactions];
}

/// State when an error occurs in financial operations.
class FinancialsError extends FinancialsState {
  final String error;

  FinancialsError(this.error, {List<TransactionModel> transactions = const []})
      : super(transactions: transactions);

  @override
  List<Object?> get props => [error, transactions];
}
