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

  const AddSession(this.model);

  @override
  List<Object> get props => [model];
}

class UpdateSession extends SessionsEvent {
  final String sessionId;
  final SessionModel model;

  const UpdateSession(this.sessionId, this.model);

  @override
  List<Object> get props => [sessionId, model];
}

class DeleteSession extends SessionsEvent {
  final String sessionId;

  const DeleteSession(this.sessionId);

  @override
  List<Object> get props => [sessionId];
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
