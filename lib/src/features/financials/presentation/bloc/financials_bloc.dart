import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/financials_usecase.dart';
import '../../domain/models/transaction_model.dart';
import '../../../../core/error/failures.dart';

part 'financials_event.dart';
part 'financials_state.dart';

/// Bloc for managing financial transactions.
class FinancialsBloc extends Bloc<FinancialsEvent, FinancialsState> {
  final FinancialsUseCase _financialsUseCase;

  FinancialsBloc({required FinancialsUseCase financialsUseCase})
      : _financialsUseCase = financialsUseCase,
        super(FinancialsInitial([])) {
    on<GetTransactionsEvent>(_onGetTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);

    on<GetTransactionsByDate>(_onGetTransactionsByDate);
    on<SearchTransactionsEvent>(_onSearchTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
  }

  /// Handles fetching all financial transactions.
  Future<void> _onGetTransactions(
      GetTransactionsEvent event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading(state.transactions));
    final result = await _financialsUseCase.getTransactions();
    emit(result.fold(
      (failure) => FinancialsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (transactions) => TransactionsLoaded(transactions),
    ));
  }

  /// Handles adding a new financial transaction.
  Future<void> _onAddTransaction(
      AddTransactionEvent event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading(state.transactions));
    final result = await _financialsUseCase.addTransaction(event.transaction);
    emit(result.fold(
      (failure) => FinancialsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (_) => FinancialsSuccess(
        List.from(state.transactions)..add(event.transaction),
        message: 'transactionAdded'.tr(),
      ),
    ));
  }

    Future<void> _onUpdateTransaction(
      UpdateTransactionEvent event, Emitter<FinancialsState> emit) async {
    final failureOrTransaction =
        await _financialsUseCase.updateTransaction(event.transactionId, event.model);
    emit(failureOrTransaction.fold(
      (failure) =>
          FinancialsError(state.transactions, message: _mapFailureToMessage(failure)),
      (updatedTransaction) {
        final transactions = state.transactions.map((transaction) {
          return transaction.id == updatedTransaction.id ? updatedTransaction : transaction;
        }).toList();
        emit(FinancialsSuccess(transactions, message: 'transactionUpdated'.tr()));
        return TransactionsLoaded(transactions);
      },
    ));
  }

  /// Handles deleting a financial transaction.
  Future<void> _onDeleteTransaction(
      DeleteTransactionEvent event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading(state.transactions));
    final failureOrResult =
        await _financialsUseCase.deleteTransaction(event.transactionId);
    emit(failureOrResult.fold(
      (failure) => FinancialsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (_) {
        final updatedTransactions = state.transactions
            .where((transaction) => transaction.id != event.transactionId)
            .toList();
        emit(FinancialsSuccess(updatedTransactions,
            message: 'transactionDeleted'.tr()));
        return TransactionsLoaded(updatedTransactions);
      },
    ));
  }

  Future<void> _onSearchTransactions(
      SearchTransactionsEvent event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading(state.transactions));

    final failureOrTransactions = await _financialsUseCase.searchTransactions(
      description: event.description,
    );

    emit(failureOrTransactions.fold(
      (failure) => FinancialsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (transactions) => TransactionsLoaded(transactions),
    ));
  }

  Future<void> _onLoadMoreTransactions(
      LoadMoreTransactions event, Emitter<FinancialsState> emit) async {
    if (state is TransactionsLoaded || state is TransactionsLoadingMore) {
      final currentTransactions = state.transactions;
      emit(TransactionsLoadingMore(currentTransactions));

      final result = await _financialsUseCase.getTransactions(
        lastDocumentId: event.lastDocumentId,
        limit: event.limit,
      );

      emit(result.fold(
        (failure) => FinancialsError(currentTransactions,
            message: _mapFailureToMessage(failure)),
        (newTransactions) {
          final updatedTransactions =
              List<TransactionModel>.from(currentTransactions)
                ..addAll(newTransactions);
          return TransactionsLoaded(updatedTransactions);
        },
      ));
    }
  }

  Future<void> _onGetTransactionsByDate(
      GetTransactionsByDate event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading(state.transactions));

    final result = await _financialsUseCase.getTransactionsByDate(
      event.date,
    );
    emit(result.fold(
      (failure) => FinancialsError(
        state.transactions,
        message: _mapFailureToMessage(failure),
      ),
      (transactions) => TransactionsLoaded(transactions),
    ));
  }

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server error occurred';
      case CacheFailure _:
        return 'Cache error occurred';
      default:
        return 'An unexpected error occurred';
    }
  }
}
