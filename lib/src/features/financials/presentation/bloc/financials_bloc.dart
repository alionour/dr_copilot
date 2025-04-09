import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/financials_usecase.dart';
import '../../domain/models/transaction_model.dart';
import '../../../../core/error/failures.dart';

part 'financials_event.dart';
part 'financials_state.dart';

/// Bloc for managing financial transactions.
class FinancialsBloc extends Bloc<FinancialsEvent, FinancialsState> {
  final FinancialsUseCase financialsUseCase;

  FinancialsBloc({required this.financialsUseCase})
      : super(FinancialsInitial()) {
    on<GetFinancialsEvent>(_onGetFinancials);
    on<AddFinancialEvent>(_onAddFinancial);
    on<DeleteFinancialEvent>(_onDeleteFinancial);
  }

  /// Handles fetching all financial transactions.
  Future<void> _onGetFinancials(
      GetFinancialsEvent event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await financialsUseCase.getTransactions();
    emit(result.fold(
      (failure) => FinancialsError(_mapFailureToMessage(failure)),
      (transactions) => FinancialsLoaded(transactions),
    ));
  }

  /// Handles adding a new financial transaction.
  Future<void> _onAddFinancial(
      AddFinancialEvent event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await financialsUseCase.addTransaction(event.transaction);
    emit(result.fold(
      (failure) => FinancialsError(_mapFailureToMessage(failure)),
      (_) => FinancialsSuccess('Transaction added successfully'),
    ));
  }

  /// Handles deleting a financial transaction.
  Future<void> _onDeleteFinancial(
      DeleteFinancialEvent event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result =
        await financialsUseCase.deleteTransaction(event.transactionId);
    emit(result.fold(
      (failure) => FinancialsError(_mapFailureToMessage(failure)),
      (_) => FinancialsSuccess('Transaction deleted successfully'),
    ));
  }

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred';
      case CacheFailure:
        return 'Cache error occurred';
      default:
        return 'An unexpected error occurred';
    }
  }
}
