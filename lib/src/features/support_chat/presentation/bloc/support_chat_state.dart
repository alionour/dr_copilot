import 'package:equatable/equatable.dart';
import '../../data/models/support_message_model.dart';

abstract class SupportChatState extends Equatable {
  const SupportChatState();

  @override
  List<Object?> get props => [];
}

class SupportChatInitial extends SupportChatState {}

class SupportChatLoading extends SupportChatState {}

class SupportChatLoaded extends SupportChatState {
  final String conversationId;
  final List<SupportMessageModel> messages;

  const SupportChatLoaded({
    required this.conversationId,
    required this.messages,
  });

  @override
  List<Object?> get props => [conversationId, messages];
}

class SupportChatError extends SupportChatState {
  final String message;

  const SupportChatError(this.message);

  @override
  List<Object?> get props => [message];
}

