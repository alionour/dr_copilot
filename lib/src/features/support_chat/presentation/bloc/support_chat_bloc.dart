import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/support_chat_repository.dart';
import '../../data/models/support_message_model.dart';
import 'support_chat_event.dart';
import 'support_chat_state.dart';

class SupportChatBloc extends Bloc<SupportChatEvent, SupportChatState> {
  final SupportChatRepository repository;
  StreamSubscription? _messagesSubscription;

  SupportChatBloc({required this.repository}) : super(SupportChatInitial()) {
    on<LoadSupportConversation>(_onLoadConversation);
    on<LoadSupportMessages>(_onLoadMessages);
    on<SendSupportMessage>(_onSendMessage);
    on<_MessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onLoadConversation(
    LoadSupportConversation event,
    Emitter<SupportChatState> emit,
  ) async {
    try {
      emit(SupportChatLoading());
      final conversationId = await repository.getOrCreateConversation(
        event.userId,
      );
      add(LoadSupportMessages(conversationId));
    } catch (e) {
      emit(SupportChatError(e.toString()));
    }
  }

  Future<void> _onLoadMessages(
    LoadSupportMessages event,
    Emitter<SupportChatState> emit,
  ) async {
    try {
      await _messagesSubscription?.cancel();
      _messagesSubscription = repository
          .getMessages(event.conversationId)
          .listen(
            (messages) {
              add(_MessagesUpdated(event.conversationId, messages));
            },
            onError: (error) {
              emit(SupportChatError(error.toString()));
            },
          );
    } catch (e) {
      emit(SupportChatError(e.toString()));
    }
  }

  Future<void> _onSendMessage(
    SendSupportMessage event,
    Emitter<SupportChatState> emit,
  ) async {
    try {
      await repository.sendMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        content: event.content,
      );
    } catch (e) {
      emit(SupportChatError(e.toString()));
    }
  }

  void _onMessagesUpdated(
    _MessagesUpdated event,
    Emitter<SupportChatState> emit,
  ) {
    emit(
      SupportChatLoaded(
        conversationId: event.conversationId,
        messages: event.messages,
      ),
    );
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    return super.close();
  }
}

// Internal event for message updates
class _MessagesUpdated extends SupportChatEvent {
  final String conversationId;
  final List<SupportMessageModel> messages;

  const _MessagesUpdated(this.conversationId, this.messages);

  @override
  List<Object?> get props => [conversationId, messages];
}

