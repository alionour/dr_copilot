library;

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/data/remote/evaluation_firebase_api.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/usecases/sessions_usecase.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/usecases/financials_usecase.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

part 'sessions_event.dart';
part 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {

  final SessionsUseCase _sessionsUseCase;
  final FinancialsUseCase _financialsUseCase;

  SessionsBloc(this._sessionsUseCase, this._financialsUseCase)
      : super(const SessionsInitial([])) {
    on<GetSessions>(_onGetSessions);
    on<AddSession>(_onAddSession);
    on<UpdateSession>(_onUpdateSession);
    on<DeleteSession>(_onDeleteSession);
    on<SearchSessions>(_onSearchSessions);
    on<GetSessionsByDate>(_onGetSessionsByDate);
    on<LoadMoreSessions>(_onLoadMoreSessions);
    on<DetectSessionType>(_onDetectSessionType);
    on<GetSessionsCount>(_onGetSessionsCount);
    on<AddInvoice>(_onAddInvoice);
    on<AddTransaction>(_onAddTransaction);
  }

  void _onGetSessions(GetSessions event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessions = await _sessionsUseCase.getSessions(
      lastDocumentID: event.lastDocumentID,
      limit: event.limit,
    );
    emit(failureOrSessions.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessions) => SessionsLoaded(sessions),
    ));
  }

  void _onAddSession(AddSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSession = await _sessionsUseCase.addSession(event.model);
    emit(failureOrSession.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (addedSession) {
        debugPrint('Add successful: $addedSession');
        // Insert the new session in the correct sorted position (descending by startDateTime)
        final sessions = List<SessionModel>.from(state.sessions)
          ..add(addedSession)
          ..sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
        emit(SessionsSuccess(sessions,
            message: 'sessionAddedSuccessfully'.tr()));
        return SessionsLoaded(sessions);
      },
    ));
  }

  void _onUpdateSession(
      UpdateSession event, Emitter<SessionsState> emit) async {
    final failureOrSession =
        await _sessionsUseCase.updateSession(event.sessionId, event.model);
    debugPrint(': ${event.model.toJson()}');

    emit(failureOrSession.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (updatedSession) {
        debugPrint('Update successful: ${updatedSession.toJson()}');
        final sessions = state.sessions.map((session) {
          return session.id == updatedSession.id ? updatedSession : session;
        }).toList();
        emit(
            SessionsSuccess(sessions, message: 'Session updated successfully'));
        return SessionsLoaded(sessions);
      },
    ));
  }

  Future<void> _onDeleteSession(
      DeleteSession event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSession =
        await _sessionsUseCase.deleteSession(event.sessionId);
    emit(failureOrSession.fold(
        (failure) => SessionsError(state.sessions,
            message: _mapFailureToMessage(failure)), (deletedSession) {
      debugPrint('Delete successful: ${event.sessionId}');
      final sessions = state.sessions
        ..removeWhere((session) => session.id == event.sessionId);
      emit(SessionsSuccess(sessions, message: 'sessionDeleted'.tr()));
      return SessionsLoaded(sessions);
    }));
  }

  Future<void> _onSearchSessions(
      SearchSessions event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessions =
        await _sessionsUseCase.searchSessions(name: event.name);
    emit(failureOrSessions.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessions) => SessionsLoaded(sessions),
    ));
  }

  void _onGetSessionsByDate(
      GetSessionsByDate event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessions =
        await _sessionsUseCase.getSessionsByDate(event.date);
    emit(failureOrSessions.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessions) => SessionsLoaded(sessions),
    ));
  }

  void _onLoadMoreSessions(
      LoadMoreSessions event, Emitter<SessionsState> emit) async {
    if (state is SessionsLoaded) {
      final currentState = state as SessionsLoaded;
      if (currentState.isLoadingMore) return;

      emit(SessionsLoaded(currentState.sessions, isLoadingMore: true));
      await Future.delayed(Duration(seconds: 1));
      final result = await _sessionsUseCase.getSessions(
        lastDocumentID: event.lastDocumentId,
        limit: event.limit,
      );

      result.fold(
        (failure) {
          debugPrint(
              'LoadMoreSessions failed: ${_mapFailureToMessage(failure)}');
          emit(SessionsError(currentState.sessions,
              message: _mapFailureToMessage(failure)));
        },
        (newSessions) {
          debugPrint(
              'Fetched ${newSessions.length} new sessions: ${newSessions.map((s) => s.id).toList()}');
          final updatedSessions = List<SessionModel>.from(currentState.sessions)
            ..addAll(newSessions.where((newSession) => !currentState.sessions
                .any(
                    (existingSession) => existingSession.id == newSession.id)));
          debugPrint(
              'Updated sessions list contains ${updatedSessions.length} sessions.');
          emit(SessionsLoaded(updatedSessions));
        },
      );
    }
  }

  void _onDetectSessionType(
      DetectSessionType event, Emitter<SessionsState> emit) async {
    emit(SessionsLoading(state.sessions));
    final failureOrSessionType =
        await _sessionsUseCase.detectSessionType(event.patientId);
    emit(failureOrSessionType.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (sessionType) => SessionTypeDetected(sessionType),
    ));
  }

  /// Handles the [GetSessionsCount] event by emitting new [SessionsState]s.
  ///
  /// This asynchronous function listens for the [GetSessionsCount] event and updates
  /// the state accordingly using the provided [Emitter]. Typically used to fetch and
  /// emit the count of sessions in the application.
  ///
  /// Parameters:
  /// - [event]: The [GetSessionsCount] event to handle.
  /// - [emit]: The function used to emit new [SessionsState]s.
  void _onGetSessionsCount(
      GetSessionsCount event, Emitter<SessionsState> emit) async {
    final failureOrCount = await _sessionsUseCase.getSessionsCount();
    emit(failureOrCount.fold(
      (failure) =>
          SessionsError(state.sessions, message: _mapFailureToMessage(failure)),
      (acc) {
        debugPrint('Total sessions count: $count');
        return SessionsCountLoaded(acc, state.sessions);
      },
    ));
  }

  void _onAddInvoice(AddInvoice event, Emitter<SessionsState> emit) async {
    try {
      final failureOrInvoice =
          await _financialsUseCase.addInvoice(invoice: event.invoice);
      failureOrInvoice.fold(
          (failure) => emit(SessionsError(state.sessions,
              message: _mapFailureToMessage(failure))), (invoice) {
        emit(SessionsSuccess(state.sessions,
            message: 'invoiceAddedSuccessfully'.tr()));
        if (invoice.status == InvoiceStatus.paid) {
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            currencyProfileId: invoice.currencyProfileId,
            direction:
                TransactionDirection.fromSource(TransactionSource.invoice),
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
              direction:
                  TransactionDirection.fromSource(TransactionSource.invoice),
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
      emit(SessionsError(state.sessions, message: 'failedToAddInvoice'.tr()));
    }
  }

  void _onAddTransaction(
      AddTransaction event, Emitter<SessionsState> emit) async {
    try {
      await _financialsUseCase.addTransaction(transaction: event.transaction);
      emit(SessionsSuccess(state.sessions,
          message: 'transactionAddedSuccessfully'.tr()));
    } catch (e) {
      emit(SessionsError(state.sessions,
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

  void processSessions(BuildContext context) async {
    try {
      debugPrint('Starting processSessions function');

      // Step 1: Fetch all sessions
      debugPrint('Fetching all sessions');
      final failureOrSessions = await _sessionsUseCase.getSessions(
          limit: 1000); // Adjust limit as needed

      failureOrSessions.fold(
        (failure) {
          debugPrint('Failed to fetch sessions: ${failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to fetch sessions: ${failure.message}'.tr())),
          );
        },
        (sessions) async {
          debugPrint('Fetched ${sessions.length} sessions');
          for (final session in sessions) {
            debugPrint('Processing session with ID: ${session.id}');

            // Step 2: Create an invoice for each session
            final invoice = InvoiceModel(
              id: const Uuid().v4(),
              customerId: session.patientId,
              amount: session.price,
              createdAt: session.startDateTime,
              createdBy: session.createdBy,
              title: 'Session Invoice',
              description:
                  'Invoice for session with ${session.patientId} at ${session.startDateTime}',
              currencyProfileId: '38Ft2Q4TM0PwuUdZq8Q9',
              issuedAt: session.startDateTime,
              dueDate: Timestamp.fromDate(
                  session.startDateTime.toDate().add(const Duration(days: 2))),
              userId: session.userId,
              customerType: CustomerType.patient,
              source: InvoiceSource.sessions,
              status: InvoiceStatus.paid, // Store as `InvoiceStatus`
            );

            debugPrint('Creating invoice for session ID: ${session.id}');
            final failureOrInvoice =
                await _financialsUseCase.addInvoice(invoice: invoice);

            failureOrInvoice.fold(
              (failure) {
                debugPrint(
                    'Failed to add invoice for session ${session.id}: ${failure.message}');
              },
              (addedInvoice) async {
                debugPrint('Invoice created with ID: ${addedInvoice.id}');

                // Step 3: Create a transaction based on the invoice status
                if (addedInvoice.status == InvoiceStatus.paid) {
                  debugPrint(
                      'Creating full payment transaction for invoice ID: ${addedInvoice.id}');
                  final transaction = TransactionModel(
                    id: const Uuid().v4(),
                    currencyProfileId: addedInvoice.currencyProfileId,
                    transactionSource: TransactionSource.invoice,
                    direction: TransactionDirection.fromSource(
                        TransactionSource.invoice),
                    status: TransactionStatus.completed,
                    transactionDate: addedInvoice.createdAt,
                    referenceId: addedInvoice.id,
                    userId: addedInvoice.userId,
                    amount: addedInvoice.amount,
                    createdAt: addedInvoice.createdAt,
                    createdBy: addedInvoice.createdBy,
                    description: 'Full payment for invoice ${addedInvoice.id}',
                  );
                  await _financialsUseCase.addTransaction(
                      transaction: transaction);
                  debugPrint(
                      'Transaction created for invoice ID: ${addedInvoice.id}');
                } else if (addedInvoice.status == InvoiceStatus.partiallyPaid) {
                  debugPrint(
                      'Creating partial payment transaction for invoice ID: ${addedInvoice.id}');
                  final partialPaymentAmount =
                      50.0; // Example partial payment amount
                  final transaction = TransactionModel(
                    id: const Uuid().v4(),
                    currencyProfileId: addedInvoice.currencyProfileId,
                    transactionSource: TransactionSource.invoice,
                    status: TransactionStatus.completed,
                    direction: TransactionDirection.fromSource(
                        TransactionSource.invoice),
                    transactionDate: addedInvoice.createdAt,
                    referenceId: addedInvoice.id,
                    userId: addedInvoice.userId,
                    amount: partialPaymentAmount,
                    createdAt: addedInvoice.createdAt,
                    createdBy: addedInvoice.createdBy,
                    description:
                        'Partial payment for invoice ${addedInvoice.id}',
                  );
                  await _financialsUseCase.addTransaction(
                      transaction: transaction);
                  debugPrint(
                      'Partial payment transaction created for invoice ID: ${addedInvoice.id}');
                }
              },
            );
          }

          debugPrint('All sessions processed successfully');
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Processed all sessions successfully!'.tr())),
          );
        },
      );
    } catch (e) {
      debugPrint('Error in processSessions: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process sessions'.tr())),
      );

    }
  }

  final EvaluationsFirebaseApi _evaluationsFirebaseApi =
      EvaluationsFirebaseApi();
  void processEvaluations(BuildContext context) async {
    try {
      debugPrint('Starting processEvaluations function');

      // Step 1: Fetch all sessions
      debugPrint('Fetching all evaluations');
      final failureOrSessions = await _evaluationsFirebaseApi.getEvaluations(
          limit: 1000); // Adjust limit as needed

      failureOrSessions.fold(
        (failure) {
          debugPrint('Failed to fetch sessions: ${failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed to fetch sessions: ${failure.message}'.tr())),
          );
        },
        (sessions) async {
          debugPrint('Fetched ${sessions.length} sessions');
          for (final session in sessions) {
            debugPrint('Processing session with ID: ${session.id}');

            // Step 2: Create an invoice for each session
            final invoice = InvoiceModel(
              id: const Uuid().v4(),
              customerId: session.patientId,
              amount: session.price,
              createdAt: session.startDateTime,
              createdBy: session.createdBy,
              title: 'Evaluation Invoice',
              description:
                  'Invoice for evaluation with ${session.patientId} at ${session.startDateTime}',
              currencyProfileId: '38Ft2Q4TM0PwuUdZq8Q9',
              issuedAt: session.startDateTime,
              dueDate: Timestamp.fromDate(
                  session.startDateTime.toDate().add(const Duration(days: 2))),
              userId: session.userId,
              customerType: CustomerType.patient,
              source: InvoiceSource.evaluations,
              status: InvoiceStatus.paid, // Store as `InvoiceStatus`
            );

            debugPrint('Creating invoice for session ID: ${session.id}');
            final failureOrInvoice =
                await _financialsUseCase.addInvoice(invoice: invoice);

            failureOrInvoice.fold(
              (failure) {
                debugPrint(
                    'Failed to add invoice for session ${session.id}: ${failure.message}');
              },
              (addedInvoice) async {
                debugPrint('Invoice created with ID: ${addedInvoice.id}');

                // Step 3: Create a transaction based on the invoice status
                if (addedInvoice.status == InvoiceStatus.paid) {
                  debugPrint(
                      'Creating full payment transaction for invoice ID: ${addedInvoice.id}');
                  final transaction = TransactionModel(
                    id: const Uuid().v4(),
                    currencyProfileId: addedInvoice.currencyProfileId,
                    transactionSource: TransactionSource.invoice,
                    direction: TransactionDirection.fromSource(
                        TransactionSource.invoice),
                    status: TransactionStatus.completed,
                    transactionDate: addedInvoice.createdAt,
                    referenceId: addedInvoice.id,
                    userId: addedInvoice.userId,
                    amount: addedInvoice.amount,
                    createdAt: addedInvoice.createdAt,
                    createdBy: addedInvoice.createdBy,
                    description: 'Full payment for invoice ${addedInvoice.id}',
                  );
                  await _financialsUseCase.addTransaction(
                      transaction: transaction);
                  debugPrint(
                      'Transaction created for invoice ID: ${addedInvoice.id}');
                } else if (addedInvoice.status == InvoiceStatus.partiallyPaid) {
                  debugPrint(
                      'Creating partial payment transaction for invoice ID: ${addedInvoice.id}');
                  final partialPaymentAmount =
                      50.0; // Example partial payment amount
                  final transaction = TransactionModel(
                    id: const Uuid().v4(),
                    currencyProfileId: addedInvoice.currencyProfileId,
                    transactionSource: TransactionSource.invoice,
                    status: TransactionStatus.completed,
                    direction: TransactionDirection.fromSource(
                        TransactionSource.invoice),
                    transactionDate: addedInvoice.createdAt,
                    referenceId: addedInvoice.id,
                    userId: addedInvoice.userId,
                    amount: partialPaymentAmount,
                    createdAt: addedInvoice.createdAt,
                    createdBy: addedInvoice.createdBy,
                    description:
                        'Partial payment for invoice ${addedInvoice.id}',
                  );
                  await _financialsUseCase.addTransaction(
                      transaction: transaction);
                  debugPrint(
                      'Partial payment transaction created for invoice ID: ${addedInvoice.id}');
                }
              },
            );
          }

          debugPrint('All sessions processed successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Processed all sessions successfully!'.tr())),
          );
        },
      );
    } catch (e) {
      debugPrint('Error in processSessions: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process sessions'.tr())),
      );
      
    }
  }
}
