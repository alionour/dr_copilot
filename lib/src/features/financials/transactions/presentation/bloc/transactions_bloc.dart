import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import '../../domain/usecases/transactions_usecase.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

/// Bloc for managing financial transactions.
class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionsUseCase _transactionsUseCase;

  TransactionsBloc(
    TransactionsUseCase transactionsUseCase,
  )   : _transactionsUseCase = transactionsUseCase,
        super(TransactionsInitial()) {
    on<GetTransactions>(_onGetTransactions);
    on<AddTransactionEvent>(_onAddTransaction);
    on<DeleteTransactionEvent>(_onDeleteTransaction);

    on<GetTransactionsByDate>(_onGetTransactionsByDate);
    on<SearchTransactions>(_onSearchTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<UpdateTransactionEvent>(_onUpdateTransaction);
    on<GetTransactionsCount>(_onGetTransactionsCount);

    /// Initial event to fetch transactions when the bloc is created.
    /// Used in [DashboardPage].
    /// Adds a [GetTransactions] event to the bloc with the following parameters:
    /// - [lastDocumentID]: `null`, indicating that transactions should be fetched from the beginning.
    /// - [limit]: `3`, specifying the maximum number of transactions to retrieve.
    add(GetTransactions(
      lastDocumentID: null,
      limit: 3,
    ));
  }

  /// Handles fetching all financial transactions.
  void _onGetTransactions(
      GetTransactions event, Emitter<TransactionsState> emit) async {
    emit(TransactionsLoading(state.transactions));
    final failureOrTransactions = await _transactionsUseCase.getTransactions(
      lastDocumentId: event.lastDocumentID,
      limit: event.limit,
    );
    emit(failureOrTransactions.fold(
      (failure) {
        debugPrint(
            'Bloc: _onGetTransactions failed: ${_mapFailureToMessage(failure)}');

        return TransactionsError(state.transactions,
            message: _mapFailureToMessage(failure));
      },
      (transactions) => TransactionsLoaded(transactions),
    ));
  }

  /// Handles adding a new financial transaction.
  Future<void> _onAddTransaction(
      AddTransactionEvent event, Emitter<TransactionsState> emit) async {
    emit(TransactionsLoading(state.transactions));
    final result = await _transactionsUseCase.addTransaction(event.transaction);
    emit(result.fold(
      (failure) => TransactionsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (_) {
        // Insert the new transaction in the correct sorted position (descending by transactionDate)
        final transactions = List<TransactionModel>.from(state.transactions)
          ..add(event.transaction)
          ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
        emit(TransactionsSuccess(transactions,
            message: 'transactionAdded'.tr()));
        return TransactionsLoaded(transactions);
      },
    ));
  }

  Future<void> _onUpdateTransaction(
      UpdateTransactionEvent event, Emitter<TransactionsState> emit) async {
    final failureOrTransaction = await _transactionsUseCase.updateTransaction(
        event.transactionId, event.model);
    emit(failureOrTransaction.fold(
      (failure) => TransactionsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (updatedTransaction) {
        final transactions = state.transactions.map((transaction) {
          return transaction.id == updatedTransaction.id
              ? updatedTransaction
              : transaction;
        }).toList();
        emit(TransactionsSuccess(transactions,
            message: 'transactionUpdated'.tr()));
        return TransactionsLoaded(transactions);
      },
    ));
  }

  /// Handles deleting a financial transaction.
  Future<void> _onDeleteTransaction(
      DeleteTransactionEvent event, Emitter<TransactionsState> emit) async {
    emit(TransactionsLoading(state.transactions));
    final failureOrResult =
        await _transactionsUseCase.deleteTransaction(event.transactionId);
    emit(failureOrResult.fold(
      (failure) => TransactionsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (_) {
        final updatedTransactions = state.transactions
            .where((transaction) => transaction.id != event.transactionId)
            .toList();
        emit(TransactionsSuccess(updatedTransactions,
            message: 'transactionDeleted'.tr()));
        return TransactionsLoaded(updatedTransactions);
      },
    ));
  }

  Future<void> _onSearchTransactions(
      SearchTransactions event, Emitter<TransactionsState> emit) async {
    emit(TransactionsLoading(state.transactions));

    final failureOrTransactions = await _transactionsUseCase.searchTransactions(
      description: event.description,
    );

    emit(failureOrTransactions.fold(
      (failure) => TransactionsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (transactions) => TransactionsLoaded(transactions),
    ));
  }

  Future<void> _onLoadMoreTransactions(
      LoadMoreTransactions event, Emitter<TransactionsState> emit) async {
    debugPrint(
        'Bloc: _onLoadMoreTransactions called with lastDocumentId: ${event.lastDocumentId}, limit: ${event.limit}');
    debugPrint('Bloc: Current state is ${state.runtimeType}');
    if (state is TransactionsLoaded) {
      final currentState = state as TransactionsLoaded;
      debugPrint(
          'Bloc: TransactionsLoaded, isLoadingMore: ${currentState.isLoadingMore}');
      if (currentState.isLoadingMore) {
        debugPrint('Bloc: Already loading more, returning');
        return;
      }

      emit(TransactionsLoaded(currentState.transactions, isLoadingMore: true));
      await Future.delayed(Duration(seconds: 1));
      final result = await _transactionsUseCase.getTransactions(
        lastDocumentId: event.lastDocumentId,
        limit: event.limit,
      );

      result.fold(
        (failure) {
          debugPrint(
              'LoadMoreTransactions failed: ${_mapFailureToMessage(failure)}');
          emit(TransactionsError(currentState.transactions,
              message: _mapFailureToMessage(failure)));
        },
        (newTransactions) {
          debugPrint(
              'Fetched ${newTransactions.length} new transactions: ${newTransactions.map((s) => s.id).toList()}');
          final updatedTransactions =
              List<TransactionModel>.from(currentState.transactions)
                ..addAll(newTransactions.where((newSession) =>
                    !currentState.transactions.any((existingTransaction) =>
                        existingTransaction.id == newSession.id)));
          debugPrint(
              'Updated transactions list contains ${updatedTransactions.length} transactions.');
          emit(TransactionsLoaded(updatedTransactions));
        },
      );
    } else {
      debugPrint('Bloc: State is not TransactionsLoaded, skipping load more');
    }
  }

  Future<void> _onGetTransactionsByDate(
      GetTransactionsByDate event, Emitter<TransactionsState> emit) async {
    emit(TransactionsLoading(state.transactions));

    final result = await _transactionsUseCase.getTransactionsByDate(
      event.date,
    );
    emit(result.fold(
      (failure) => TransactionsError(
        state.transactions,
        message: _mapFailureToMessage(failure),
      ),
      (transactions) => TransactionsLoaded(transactions),
    ));
  }

  /// Handles the [GetTransactionsCount] event by emitting new [Tr]s.
  ///
  /// This asynchronous function listens for the [GetTransactionsCount] event and updates
  /// the state accordingly using the provided [Emitter]. Typically used to fetch and
  /// emit the count of transactions in the application.
  ///
  /// Parameters:
  /// - [event]: The [GetTransactionsCount] event to handle.
  /// - [emit]: The function used to emit new [Tr]s.
  void _onGetTransactionsCount(
      GetTransactionsCount event, Emitter<TransactionsState> emit) async {
    final failureOrCount = await _transactionsUseCase.getTransactionsCount();
    emit(failureOrCount.fold(
      (failure) => TransactionsError(state.transactions,
          message: _mapFailureToMessage(failure)),
      (acc) {
        debugPrint('Total transactions count: $count');

        emit(TransactionsCountLoaded(acc, state.transactions));
        return TransactionsLoaded(state.transactions);
      },
    ));
  }

  /// Validates the provided reference ID and fetches the corresponding
  /// document snapshot from the remote data source.
  ///
  /// This method checks if the given [referenceId] is valid and attempts
  /// to retrieve the associated document. If the operation is successful,
  /// it returns a [DocumentSnapshot] wrapped in a [Right]. If there is a
  /// failure, it returns a [Failure] wrapped in a [Left].
  ///
  /// - Parameters:
  ///   - referenceId: The unique identifier of the reference to validate
  ///     and fetch.
  ///
  /// - Returns: A [Future] containing an [Either] with a [Failure] on the
  ///   left side if an error occurs, or a [DocumentSnapshot?] on the right
  ///   side if the operation is successful.
  Future<Either<Failure, DocumentSnapshot?>> validateAndFetchReferenceId({
    required String referenceId,
    required TransactionSource transactionSource,
  }) {
    return _transactionsUseCase.validateAndFetchReferenceId(
      referenceId: referenceId,
      transactionSource: transactionSource,
    );
  }

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server error occurred';
      case CacheFailure _:
        return 'Cache error occurred';
      default:
        return 'An unexpected error occurred ${failure.message}';
    }
  }
}
