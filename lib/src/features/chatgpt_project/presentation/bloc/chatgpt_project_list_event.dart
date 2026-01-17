import 'package:equatable/equatable.dart';

abstract class ChatGptProjectListEvent extends Equatable {
  const ChatGptProjectListEvent();

  @override
  List<Object> get props => [];
}

class LoadChatGptProjectList extends ChatGptProjectListEvent {
  const LoadChatGptProjectList();
}

