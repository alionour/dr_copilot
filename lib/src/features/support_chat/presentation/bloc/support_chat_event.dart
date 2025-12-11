import 'package:equatable/equatable.dart';

abstract class SupportChatEvent extends Equatable {
  const SupportChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadSupportConversation extends SupportChatEvent {
  final String userId;

  const LoadSupportConversation(this.userId);

  @override
  List<Object?> get props => [userId];
}

class LoadSupportMessages extends SupportChatEvent {
  final String conversationId;

  const LoadSupportMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendSupportMessage extends SupportChatEvent {
  final String conversationId;
  final String senderId;
  final String content;

  const SendSupportMessage({
    required this.conversationId,
    required this.senderId,
    required this.content,
  });

  @override
  List<Object?> get props => [conversationId, senderId, content];
}
