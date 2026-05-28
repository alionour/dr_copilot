import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    on<AddInvoice>(_onAddInvoice);
    on<AddTransaction>(_onAddTransaction);
  }

  void _onGetEvaluations(
      GetEvaluations event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations, totalCount: state.totalCount));
    final failureOrEvaluations = await _evaluationsUseCase.getEvaluations(
      lastDocumentID: event.lastDocumentID,
      limit: event.limit,
    );
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure), totalCount: state.totalCount),
      (evaluations) => EvaluationsLoaded(evaluations, totalCount: state.totalCount),
    ));
  }

  void _onAddEvaluation(
      AddEvaluation event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations, totalCount: state.totalCount));
    final failureOrEvaluation =
        await _evaluationsUseCase.addEvaluation(event.model);
    await failureOrEvaluation.fold(
      (failure) {
        emit(EvaluationsError(state.evaluations,
            message: _mapFailureToMessage(failure), totalCount: state.totalCount));
      },
      (addedEvaluation) async {
        debugPrint('Add successful: $addedEvaluation');
        // Insert the new evaluation in the correct sorted position (descending by startDateTime)
        final evaluations = List<EvaluationModel>.from(state.evaluations)
          ..add(addedEvaluation)
          ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
        emit(EvaluationsLoaded(evaluations, totalCount: state.totalCount));

        // After evaluation is added, create the invoice with referenceId = evaluationId
        final invoice = InvoiceModel(
          id: const Uuid().v4(),
          customerId: addedEvaluation.patientId,
          amount: addedEvaluation.price,
          createdAt: addedEvaluation.createdAt,
          createdBy: addedEvaluation.createdBy,
          title: 'Evaluation Invoice',
          description:
              'Invoice for evaluation with ${addedEvaluation.patientName} at ${addedEvaluation.startDateTime.toDate()}',
          currencyProfileId: event.currencyProfileId,
          issuedAt: addedEvaluation.createdAt,
          dueDate: Timestamp.fromDate(addedEvaluation.startDateTime
              .toDate()
              .add(const Duration(days: 30))),
          ownerId: addedEvaluation.ownerId,
          clinicId: addedEvaluation.clinicId,
          customerType: CustomerType.patient,
          source: InvoiceSource.evaluations,
          status: event.invoiceStatus,
          referenceId: addedEvaluation.id,
        );
        add(AddInvoice(invoice));
      },
    );
  }

  void _onUpdateEvaluation(
      UpdateEvaluation event, Emitter<EvaluationsState> emit) async {
    final failureOrEvaluation = await _evaluationsUseCase.updateEvaluation(
        event.evaluationId, event.model);
    emit(failureOrEvaluation.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure), totalCount: state.totalCount),
      (updatedEvaluation) {
        debugPrint('Update successful: $updatedEvaluation');
        final evaluations = state.evaluations.map((evaluation) {
          return evaluation.id == updatedEvaluation.id
              ? updatedEvaluation
              : evaluation;
        }).toList();
        emit(EvaluationsSuccess(evaluations,
            message: 'evaluationUpdated'.tr(), totalCount: state.totalCount));
        return EvaluationsLoaded(evaluations, totalCount: state.totalCount);
      },
    ));
  }

  Future<void> _onDeleteEvaluation(
      DeleteEvaluation event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations, totalCount: state.totalCount));
    // Always delete the evaluation itself
    final failureOrEvaluation =
        await _evaluationsUseCase.deleteEvaluation(event.evaluationId);
    await failureOrEvaluation.fold(
      (failure) {
        emit(EvaluationsError(state.evaluations,
            message: _mapFailureToMessage(failure), totalCount: state.totalCount));
        return;
      },
      (deletedEvaluation) async {
        debugPrint('Delete successful: ${event.evaluationId}');
        var evaluations = List<EvaluationModel>.from(state.evaluations)
          ..removeWhere((evaluation) => evaluation.id == event.evaluationId);
        emit(
            EvaluationsSuccess(evaluations, message: 'evaluationDeleted'.tr(), totalCount: state.totalCount));
        
        // If requested, also delete the corresponding invoice and transactions
        if (event.deleteInvoiceAndTransaction) {
          final failureOrInvoice = await _financialsUseCase
              .deleteInvoiceByReferenceId(event.evaluationId);
          return failureOrInvoice.fold(
            (failure) {
              return EvaluationsError(state.evaluations,
                  message: _mapFailureToMessage(failure), totalCount: state.totalCount);
            },
            (deletedInvoice) async {
              debugPrint('Invoice Delete successful: ${event.evaluationId}');
              // Now delete the transaction associated with this invoice/session
              final failureOrTransaction = await _financialsUseCase
                  .deleteTransactionByReferenceId(event.evaluationId);
              return failureOrTransaction.fold(
                (failure) => EvaluationsError(state.evaluations,
                    message: _mapFailureToMessage(failure), totalCount: state.totalCount),
                (deletedTransaction) {
                  debugPrint(
                      'Transaction Delete successful: ${event.evaluationId}');
                  return EvaluationsSuccess(state.evaluations,
                      message: 'invoiceAndTransactionDeleted'.tr(), totalCount: state.totalCount);
                },
              );
            },
          );
        }
        emit(EvaluationsLoaded(evaluations, totalCount: state.totalCount));
      },
    );
  }

  Future<void> _onSearchEvaluations(
      SearchEvaluations event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations, totalCount: state.totalCount));
    final failureOrEvaluations =
        await _evaluationsUseCase.searchEvaluations(name: event.name);
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure), totalCount: state.totalCount),
      (evaluations) => EvaluationsLoaded(evaluations, totalCount: state.totalCount),
    ));
  }

  void _onGetEvaluationsByDate(
      GetEvaluationsByDate event, Emitter<EvaluationsState> emit) async {
    emit(EvaluationsLoading(state.evaluations, totalCount: state.totalCount));
    final failureOrEvaluations =
        await _evaluationsUseCase.getEvaluationsByDate(event.date);
    emit(failureOrEvaluations.fold(
      (failure) => EvaluationsError(state.evaluations,
          message: _mapFailureToMessage(failure), totalCount: state.totalCount),
      (evaluations) => EvaluationsLoaded(evaluations, totalCount: state.totalCount),
    ));
  }

  void _onLoadMoreEvaluations(
      LoadMoreEvaluations event, Emitter<EvaluationsState> emit) async {
    if (state is EvaluationsLoaded) {
      final currentState = state as EvaluationsLoaded;
      if (currentState.isLoadingMore) return;

      emit(EvaluationsLoaded(currentState.evaluations, isLoadingMore: true, totalCount: currentState.totalCount));
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
              message: _mapFailureToMessage(failure), totalCount: currentState.totalCount));
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
          emit(EvaluationsLoaded(updatedEvaluations, totalCount: currentState.totalCount));
        },
      );
    }
  }

  Future<void> _onGetEvaluationsCount(
      GetEvaluationsCount event, Emitter<EvaluationsState> emit) async {
    debugPrint('Fetching evaluations count...');
    final result = await _evaluationsUseCase.repository.getEvaluationsCount();
    emit(result.fold(
      (failure) =>
          EvaluationsError(state.evaluations, message: failure.message, totalCount: state.totalCount),
      (evaluationCount) {
        debugPrint('Evaluations count: $evaluationCount');
        final currentState = state;
        if (currentState is EvaluationsLoaded) {
          return EvaluationsLoaded(
            currentState.evaluations,
            isLoadingMore: currentState.isLoadingMore,
            totalCount: evaluationCount,
          );
        } else if (currentState is EvaluationsLoading) {
          return EvaluationsLoading(currentState.evaluations, totalCount: evaluationCount);
        } else if (currentState is EvaluationsLoadingMore) {
          return EvaluationsLoadingMore(currentState.evaluations, totalCount: evaluationCount);
        } else if (currentState is EvaluationsSuccess) {
          return EvaluationsSuccess(currentState.evaluations, message: currentState.message, totalCount: evaluationCount);
        } else if (currentState is EvaluationsError) {
          return EvaluationsError(currentState.evaluations, message: currentState.message, totalCount: evaluationCount);
        }
        return EvaluationsInitial(currentState.evaluations, totalCount: evaluationCount);
      },
    ));
  }

  void _onAddInvoice(AddInvoice event, Emitter<EvaluationsState> emit) async {
    try {
      final failureOrInvoice =
          await _financialsUseCase.addInvoice(invoice: event.invoice);
      failureOrInvoice.fold(
          (failure) => emit(EvaluationsError(state.evaluations,
              message: _mapFailureToMessage(failure))), (invoice) {
        bool transactionAdded = false;
        if (invoice.status == InvoiceStatus.paid) {
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            currencyProfileId: invoice.currencyProfileId,
            transactionSource: TransactionSource.invoice,
            direction:
                TransactionDirection.fromSource(TransactionSource.invoice),
            status: TransactionStatus.completed,
            transactionDate: invoice.createdAt,
            referenceId: invoice.id,
            ownerId: invoice.ownerId,
            clinicId: invoice.clinicId,
            amount: invoice.amount,
            createdAt: invoice.createdAt,
            createdBy: invoice.createdBy,
            description: 'Full payment for invoice ${invoice.id}',
          );

          add(AddTransaction(transaction));
          transactionAdded = true;
        } else if (invoice.status == InvoiceStatus.partiallyPaid) {
          final partialPaymentAmount = event.partialAmount ?? 0.0;
          if (partialPaymentAmount > 0) {
            final transaction = TransactionModel(
              id: const Uuid().v4(),
              currencyProfileId: invoice.currencyProfileId,
              transactionSource: TransactionSource.invoice,
              direction:
                  TransactionDirection.fromSource(TransactionSource.invoice),
              status: TransactionStatus.completed,
              transactionDate: invoice.createdAt,
              referenceId: invoice.id,
              ownerId: invoice.ownerId,
              clinicId: invoice.clinicId,
              amount: partialPaymentAmount,
              createdAt: invoice.createdAt,
              createdBy: invoice.createdBy,
              description: 'Partial payment for invoice ${invoice.id}',
            );
            add(AddTransaction(transaction));
            transactionAdded = true;
          }
        }
        if (!transactionAdded) {
          emit(EvaluationsSuccess(state.evaluations,
              message: 'evaluationAndInvoiceAddedSuccessfully'.tr()));
        }
      });
    } catch (e) {
      emit(EvaluationsError(state.evaluations,
          message: 'failedToAddInvoice'.tr()));
    }
  }

  void _onAddTransaction(
      AddTransaction event, Emitter<EvaluationsState> emit) async {
    try {
      await _financialsUseCase.addTransaction(transaction: event.transaction);
      emit(EvaluationsSuccess(state.evaluations,
          message: 'evaluationInvoiceAndTransactionAddedSuccessfully'.tr()));
      emit(EvaluationsLoaded(state.evaluations));
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

