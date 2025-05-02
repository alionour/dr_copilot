part of 'financials_bloc.dart';
/// Base class for all financial states.
abstract class FinancialsState extends Equatable {
  const FinancialsState();

  @override
  List<Object?> get props => [];
}



/// Initial state of the FinancialsBloc.
class FinancialsInitial extends FinancialsState {
  const FinancialsInitial();
}

/// State when financial transactions are being loaded.
class FinancialsLoading extends FinancialsState {
  const FinancialsLoading();
}



/// State when a financial operation is successful.
class FinancialsSuccess extends FinancialsState {
  final String message;

  const FinancialsSuccess( {required this.message});

  @override
  List<Object?> get props => [message];
}


/// State when an error occurs in financial operations.
class FinancialsError extends FinancialsState {
  final String message;

  const FinancialsError({required this.message});

  @override
  List<Object?> get props => [message];
}
