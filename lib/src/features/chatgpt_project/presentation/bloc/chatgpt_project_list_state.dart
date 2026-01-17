import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/chatgpt_project/domain/entities/chatgpt_project.dart';

abstract class ChatGptProjectListState extends Equatable {
  const ChatGptProjectListState();

  @override
  List<Object> get props => [];
}

class ChatGptProjectListInitial extends ChatGptProjectListState {}

class ChatGptProjectListLoading extends ChatGptProjectListState {}

class ChatGptProjectListLoaded extends ChatGptProjectListState {
  final List<ChatGptProject> projects;

  const ChatGptProjectListLoaded(this.projects);

  @override
  List<Object> get props => [projects];
}

class ChatGptProjectListError extends ChatGptProjectListState {
  final String message;

  const ChatGptProjectListError(this.message);

  @override
  List<Object> get props => [message];
}

class ChatGptProjectListApiKeyMissing extends ChatGptProjectListState {}

