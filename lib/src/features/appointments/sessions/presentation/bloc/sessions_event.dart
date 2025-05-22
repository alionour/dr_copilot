part of 'sessions_bloc.dart';

abstract class SessionsEvent extends Equatable {
  const SessionsEvent();

  @override
  List<Object?> get props => [];
}

class GetSessions extends SessionsEvent {
  final String? lastDocumentID;
  final int limit;

  const GetSessions({this.lastDocumentID, this.limit = 20});

  @override
  List<Object?> get props => [lastDocumentID, limit];
}

class SearchSessions extends SessionsEvent {
  final String? name;

  const SearchSessions({this.name});

  @override
  List<Object?> get props => [name];
}

class AddSession extends SessionsEvent {
  final SessionModel model;
  final InvoiceStatus invoiceStatus;
  final String currencyProfileId;

  const AddSession(
    this.model, {
    required this.invoiceStatus,
    required this.currencyProfileId,
  });

  @override
  List<Object> get props => [model, invoiceStatus, currencyProfileId];
}

class UpdateSession extends SessionsEvent {
  final String sessionId;
  final SessionModel model;

  const UpdateSession(this.sessionId, this.model);

  @override
  List<Object> get props => [sessionId, model];
}

/// Event to delete a session in the [SessionsBloc].
///
/// This event should be dispatched when a session needs to be removed.
/// The associated session information should be provided as part of the event's properties.
class DeleteSession extends SessionsEvent {
  /// The unique identifier for the session.
  final String sessionId;

  /// Indicates whether the invoice associated with the session should be deleted.
  ///
  /// If set to `true`, the invoice will be deleted; otherwise, it will be retained.
  final bool deleteInvoiceAndTransaction;

  const DeleteSession(
    this.sessionId, {
    required this.deleteInvoiceAndTransaction,
  });

  @override
  List<Object> get props => [sessionId, deleteInvoiceAndTransaction];
}

class GetSessionsByDate extends SessionsEvent {
  final DateTime date;

  const GetSessionsByDate({required this.date});

  @override
  List<Object> get props => [date];
}

class LoadMoreSessions extends SessionsEvent {
  final int? limit;
  final String? lastDocumentId;

  const LoadMoreSessions({this.lastDocumentId, this.limit});

  @override
  List<Object?> get props => [lastDocumentId, limit];
}

class DetectSessionType extends SessionsEvent {
  final String patientId;

  const DetectSessionType(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

/// Event to trigger fetching the count of sessions.
///
/// This event can be dispatched to the [SessionsBloc] to request
/// the current number of sessions available.
class GetSessionsCount extends SessionsEvent {
  const GetSessionsCount();

  @override
  List<Object?> get props => [];
}

/// Event to add an invoice in the sessions feature.
///
/// This event is part of the `SessionsEvent` hierarchy and is used to trigger
/// the addition of a new invoice within the appointments or sessions context.
class AddInvoice extends SessionsEvent {
  final InvoiceModel invoice;

  final double? partialAmount;

  /// Constructor for the [AddInvoice] event.
  /// Takes an [InvoiceModel] object as a parameter.
  const AddInvoice(this.invoice, {this.partialAmount});

  @override
  List<Object?> get props => [invoice];
}

/// Event to add a transaction in the sessions feature.
///
/// This event is part of the `SessionsEvent` hierarchy and is used to
/// trigger the addition of a new transaction within the appointments
/// sessions context.
class AddTransaction extends SessionsEvent {
  final TransactionModel transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}
