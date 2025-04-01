part of 'sessions_bloc.dart';

abstract class SessionsEvent extends Equatable {
  const SessionsEvent();

  @override
  List<Object?> get props => [];
}

class GetSessions extends SessionsEvent {
    final String query;

  const GetSessions(this.query);

  @override
  List<Object> get props => [query];
}


class SearchSessions extends SessionsEvent {
    final String query;

  const SearchSessions(this.query);

  @override
  List<Object> get props => [query];
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
