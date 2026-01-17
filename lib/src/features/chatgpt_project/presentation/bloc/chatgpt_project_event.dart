part of 'chatgpt_project_bloc.dart';

abstract class ChatGptProjectEvent extends Equatable {
  const ChatGptProjectEvent();

  @override
  List<Object> get props => [];
}

class GetProject extends ChatGptProjectEvent {
  final String name;

  const GetProject({required this.name});

  @override
  List<Object> get props => [name];
}

