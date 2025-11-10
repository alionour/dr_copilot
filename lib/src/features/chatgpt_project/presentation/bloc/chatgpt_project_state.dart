part of 'chatgpt_project_bloc.dart';

abstract class ChatGptProjectState extends Equatable {
  const ChatGptProjectState();

  @override
  List<Object> get props => [];
}

class ChatGptProjectInitial extends ChatGptProjectState {}

class ChatGptProjectLoading extends ChatGptProjectState {}

class ChatGptProjectLoaded extends ChatGptProjectState {
  final ChatGptProjectModel project;

  const ChatGptProjectLoaded({required this.project});

  @override
  List<Object> get props => [project];
}

class ChatGptProjectError extends ChatGptProjectState {
  final String message;

  const ChatGptProjectError({required this.message});

  @override
  List<Object> get props => [message];
}
