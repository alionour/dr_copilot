import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/usecases/evaluations_usecase.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

part 'evaluations_event.dart';
part 'evaluations_state.dart';

class EvaluationsBloc extends Bloc<EvaluationsEvent, EvaluationsState> {
  final EvaluationsUseCase _evaluationsUseCase;
  final FinancialsUseCase _financialsUseCase;

  EvaluationsBloc(this._evaluationsUseCase, this._financialsUseCase)
      : super(const EvaluationsInitial([])) {
    on<GetEvaluations>(_onGetEvaluations);
    on<AddEvaluation>(_onAddEvaluation);
    on<UpdateEvaluation>(_onUpdateEvaluation);
    on<DeleteEvaluation>(_onDeleteEvaluation);
    on<SearchEvaluations>(_onSearchEvaluations);
    on<GetEvaluationsByDate>(_onGetEvaluationsByDate);
    on<LoadMoreEvaluations>(_onLoadMoreEvaluations);
    on<GetEvaluationsCount>(_onGetEvaluationsCount);
  }

  void _onGetEvaluations(
      GetEvaluations event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluations = await _evaluationsUseCase.getEvaluations(
      lastDocumentID: event.lastDocumentID,
      limit: event.limit,
    );
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (evaluations) => EvaluationsLoaded(evaluations),
    ));
  }

  void _onAddEvaluation(
      AddEvaluation event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluation =
        await _evaluationsUseCase.addEvaluation(event.model);
    emit(failureOrEvaluation.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (addedEvaluation) {
        debugPrint('Add successful: $addedEvaluation');
        // Insert the new evaluation in the correct sorted position (descending by startDateTime)
        final evaluations = List<EvaluationModel>.from(state.evaluations)
          ..add(addedEvaluation)
          ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
        emit(EvaluationsSuccess(evaluations,
            message: 'evaluationAddedSuccessfully'.tr()));
        return EvaluationsLoaded(evaluations);
      },
    ));
  }

  void _onUpdateEvaluation(
      UpdateEvaluation event, Emitter<EvaluationsState> emit) async {
    final failureOrEvaluation = await _evaluationsUseCase.updateEvaluation(
        event.evaluationId, event.model);
    emit(failureOrEvaluation.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (updatedEvaluation) {
        debugPrint('Update successful: $updatedEvaluation');
        final evaluations = state.evaluations.map((evaluation) {
          return evaluation.id == updatedEvaluation.id
              ? updatedEvaluation
              : evaluation;
        }).toList();
        emit(EvaluationsSuccess(evaluations,
            message: 'Evaluation updated successfully'));
        return EvaluationsLoaded(evaluations);
      },
    ));
  }

  Future<void> _onDeleteEvaluation(
      DeleteEvaluation event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluation =
        await _evaluationsUseCase.deleteEvaluation(event.evaluationId);
    emit(failureOrEvaluation.fold(
        (failure) => EvaluationsError(state.evaluations,
            message: _mapFailureToMessage(failure)), (deletedEvaluation) {
      debugPrint('Delete successful: ${event.evaluationId}');
      final evaluations = state.evaluations
        ..removeWhere((evaluation) => evaluation.id == event.evaluationId);
      emit(EvaluationsSuccess(evaluations, message: 'evaluationDeleted'.tr()));
      return EvaluationsLoaded(evaluations);
    }));
  }

  Future<void> _onSearchEvaluations(
      SearchEvaluations event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluations =
        await _evaluationsUseCase.searchEvaluations(name: event.name);
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (evaluations) => EvaluationsLoaded(evaluations),
    ));
  }

  void _onGetEvaluationsByDate(
      GetEvaluationsByDate event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations));
    final failureOrEvaluations =
        await _evaluationsUseCase.getEvaluationsByDate(event.date);
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure)),
      (evaluations) => EvaluationsLoaded(evaluations),
    ));
  }

  void _onLoadMoreEvaluations(
      LoadMoreEvaluations event, Emitter<EvaluationsState> emit) async {
    if (state is EvaluationsLoaded) {
      final currentState = state as EvaluationsLoaded;
      if (currentState.isLoadingMore) return;

      emit(EvaluationsLoaded(currentState.evaluations, isLoadingMore: true));
      await Future.delayed(Duration(seconds: 1));
      final result = await _evaluationsUseCase.getEvaluations(
        lastDocumentID: event.lastDocumentId,
        limit: event.limit,
      );

      result.fold(
        (failure) {
          debugPrint(
              'LoadMoreEvaluations failed: ${_mapFailureToMessage(failure)}');
          emit(EvaluationsError(currentState.evaluations,
              message: _mapFailureToMessage(failure)));
        },
        (newEvaluations) {
          debugPrint(
              'Fetched ${newEvaluations.length} new evaluations: ${newEvaluations.map((e) => e.id).toList()}');
          final updatedEvaluations =
              List<EvaluationModel>.from(currentState.evaluations)
                ..addAll(newEvaluations.where((newEvaluation) =>
                    !currentState.evaluations.any((existingEvaluation) =>
                        existingEvaluation.id == newEvaluation.id)));
          debugPrint(
              'Updated evaluations list contains ${updatedEvaluations.length} evaluations.');
          emit(EvaluationsLoaded(updatedEvaluations));
        },
      );
    }
  }

  Future<void> _onGetEvaluationsCount(
      GetEvaluationsCount event, Emitter<EvaluationsState> emit) async {
    debugPrint('Fetching evaluations count...');
    final result = await _evaluationsUseCase.repository.getEvaluationsCount();
    result.fold(
      (failure) =>
          emit(EvaluationsError(state.evaluations, message: failure.message)),
      (count) => emit(EvaluationsCountLoaded(count, state.evaluations)),
    );
    debugPrint('Evaluations count: $result');
  }

  void _onAddInvoice(AddInvoice event, Emitter<EvaluationsState> emit) async {
    try {
      final failureOrInvoice =
          await _financialsUseCase.addInvoice(invoice: event.invoice);
      failureOrInvoice.fold(
          (failure) => emit(EvaluationsError(state.evaluations,
              message: _mapFailureToMessage(failure))), (invoice) {
        emit(EvaluationsSuccess(state.evaluations,
            message: 'invoiceAddedSuccessfully'.tr()));
        if (invoice.status == InvoiceStatus.paid) {
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            currencyProfileId: invoice.currencyProfileId,
            transactionSource: TransactionSource.invoice,
            status: TransactionStatus.completed,
            transactionDate: invoice.createdAt,
            referenceId: invoice.id,
            userId: invoice.userId,
            amount: invoice.amount,
            createdAt: invoice.createdAt,
            createdBy: invoice.createdBy,
            description: 'Full payment for invoice ${invoice.id}',
          );

          add(AddTransaction(transaction));
        } else if (invoice.status == InvoiceStatus.partiallyPaid) {
          final partialPaymentAmount = event.partialAmount ?? 0.0;
          if (partialPaymentAmount > 0) {
            final transaction = TransactionModel(
              id: const Uuid().v4(),
              currencyProfileId: invoice.currencyProfileId,
              transactionSource: TransactionSource.invoice,
              status: TransactionStatus.completed,
              transactionDate: invoice.createdAt,
              referenceId: invoice.id,
              userId: invoice.userId,
              amount: invoice.amount,
              createdAt: invoice.createdAt,
              createdBy: invoice.createdBy,
              description: 'Partial payment for invoice ${invoice.id}',
            );
            add(AddTransaction(transaction));
          }
        }
      });
    } catch (e) {
      emit(EvaluationsError(state.evaluations, message: 'failedToAddInvoice'.tr()));
    }
  }

  void _onAddTransaction(
      AddTransaction event, Emitter<EvaluationsState> emit) async {
    try {
      await _financialsUseCase.addTransaction(transaction: event.transaction);
      emit(EvaluationsSuccess(state.evaluations,
          message: 'transactionAddedSuccessfully'.tr()));
    } catch (e) {
      emit(EvaluationsError(state.evaluations,
          message: 'failedToAddTransaction'.tr()));
    }
  }

  /// Fetches the currency profiles
  Future<Either<Failure, List<CurrencyProfileModel>>>
      getCurrencyProfiles() async {
    final failureOrProfiles = await _financialsUseCase.fetchCurrencyProfiles();
    return failureOrProfiles.fold(
      (failure) => Left(ServerFailure(_mapFailureToMessage(failure), 404)),
      (profiles) => Right(profiles),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server Failure: ${failure.message}';
      case CacheFailure _:
        return 'Cache Failure: ${failure.message}';
      default:
        return 'Unexpected Error: ${failure.message}';
    }
  }
}
