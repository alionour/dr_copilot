import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/team_message_model.dart';
import '../../data/repositories/unified_chat_repository.dart';

// Events
abstract class ChatRoomEvent extends Equatable {
  const ChatRoomEvent();
  @override
  List<Object?> get props => [];
}

class LoadMessages extends ChatRoomEvent {
  final String conversationId;
  const LoadMessages(this.conversationId);
  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends ChatRoomEvent {
  final String conversationId;
  final String senderId;
  final String content;
  final MessageType type;

  const SendMessage({
    required this.conversationId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
  });

  @override
  List<Object?> get props => [conversationId, senderId, content, type];
}

class MessagesUpdated extends ChatRoomEvent {
  final List<TeamMessageModel> messages;
  const MessagesUpdated(this.messages);
  @override
  List<Object?> get props => [messages];
}

// States
abstract class ChatRoomState extends Equatable {
  const ChatRoomState();
  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<TeamMessageModel> messages;
  const ChatRoomLoaded(this.messages);
  @override
  List<Object?> get props => [messages];
}

class ChatRoomError extends ChatRoomState {
  final String message;
  const ChatRoomError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class ChatRoomBloc extends Bloc<ChatRoomEvent, ChatRoomState> {
  final UnifiedChatRepository _repository;
  StreamSubscription? _messagesSubscription;

  ChatRoomBloc(this._repository) : super(ChatRoomInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessagesUpdated>(_onMessagesUpdated);
  }

  void _onLoadMessages(LoadMessages event, Emitter<ChatRoomState> emit) {
    emit(ChatRoomLoading());
    _messagesSubscription?.cancel();
    _messagesSubscription =
        _repository.getMessages(event.conversationId).listen(
              (messages) => add(MessagesUpdated(messages)),
              onError: (e) => add(MessagesUpdated([])),
            );
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatRoomState> emit,
  ) async {
    try {
      await _repository.sendMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        content: event.content,
        type: event.type,
      );
    } catch (e) {
      debugPrint('[ChatRoomBloc] Error sending message: $e');
      debugPrint('[ChatRoomBloc] Conversation ID was: ${event.conversationId}');
      emit(ChatRoomError('Failed to send message: $e'));
    }
  }

  void _onMessagesUpdated(MessagesUpdated event, Emitter<ChatRoomState> emit) {
    emit(ChatRoomLoaded(event.messages));
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}
