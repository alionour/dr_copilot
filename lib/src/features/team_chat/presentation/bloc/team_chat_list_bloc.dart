import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/team_conversation_model.dart';
import '../../data/models/direct_conversation_model.dart';
import '../../data/repositories/team_chat_repository.dart';
import '../../data/repositories/direct_messages_repository.dart';

import 'package:flutter/foundation.dart'; // For debugPrint

// Events
abstract class TeamChatListEvent extends Equatable {
  const TeamChatListEvent();
  @override
  List<Object?> get props => [];
}

class LoadTeamChats extends TeamChatListEvent {
  final String userId;
  final String clinicId;
  const LoadTeamChats(this.userId, this.clinicId);
  @override
  List<Object?> get props => [userId, clinicId];
}

class AllChatsUpdated extends TeamChatListEvent {
  final List<dynamic>
      conversations; // Mix of TeamConversation and DirectConversation
  const AllChatsUpdated(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

// States
abstract class TeamChatListState extends Equatable {
  const TeamChatListState();
  @override
  List<Object?> get props => [];
}

class TeamChatListInitial extends TeamChatListState {}

class TeamChatListLoading extends TeamChatListState {}

class TeamChatListLoaded extends TeamChatListState {
  final List<dynamic> conversations; // Mix of both types
  const TeamChatListLoaded(this.conversations);
  @override
  List<Object?> get props => [conversations];
}

class TeamChatListError extends TeamChatListState {
  final String message;
  const TeamChatListError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TeamChatListBloc extends Bloc<TeamChatListEvent, TeamChatListState> {
  final TeamChatRepository _teamChatRepository;
  final DirectMessagesRepository _directMessagesRepository;
  StreamSubscription? _teamChatsSubscription;
  StreamSubscription? _directMessagesSubscription;

  // Store latest data from each stream
  List<TeamConversationModel> _latestTeamChats = [];
  List<DirectConversationModel> _latestDirectMessages = [];

  TeamChatListBloc(this._teamChatRepository, this._directMessagesRepository)
      : super(TeamChatListInitial()) {
    on<LoadTeamChats>(_onLoadTeamChats);
    on<AllChatsUpdated>(_onAllChatsUpdated);
  }

  void _onLoadTeamChats(LoadTeamChats event, Emitter<TeamChatListState> emit) {
    emit(TeamChatListLoading());
    _teamChatsSubscription?.cancel();
    _directMessagesSubscription?.cancel();

    // Listen to team chats
    _teamChatsSubscription = _teamChatRepository
        .getConversations(event.userId, event.clinicId)
        .listen(
      (teamChats) {
        debugPrint(
            'TeamChatListBloc: Chat details - ID: ${teamChats.isNotEmpty ? teamChats.first.id : "none"}, Clinic: ${teamChats.isNotEmpty ? teamChats.first.clinicId : "none"}');
        _latestTeamChats = teamChats;
        _mergeAndEmit();
      },
      onError: (e) {
        debugPrint('TeamChats error: $e');
        _latestTeamChats = [];
        _mergeAndEmit();
      },
    );

    // Listen to direct messages
    _directMessagesSubscription =
        _directMessagesRepository.getDirectConversations(event.userId).listen(
      (directMessages) {
        debugPrint('DirectMessages received: ${directMessages.length}');
        _latestDirectMessages = directMessages;
        _mergeAndEmit();
      },
      onError: (e) {
        debugPrint('DirectMessages error: $e');
        _latestDirectMessages = [];
        _mergeAndEmit();
      },
    );
  }

  void _mergeAndEmit() {
    // Deduplicate by conversation ID, preferring team chat over DM for same ID
    final Map<String, dynamic> dedup = {};
    for (final conv in _latestDirectMessages) {
      dedup[conv.id] = conv;
    }
    for (final conv in _latestTeamChats) {
      dedup[conv.id] = conv; // team chat wins for same ID
    }
    final List<dynamic> allConversations = dedup.values.toList();

    debugPrint(
      'Merged conversations: ${allConversations.length} (${_latestDirectMessages.length} direct + ${_latestTeamChats.length} team)',
    );

    // Sort by updatedAt descending
    if (allConversations.isNotEmpty) {
      allConversations.sort((a, b) {
        final aTime = a is TeamConversationModel
            ? a.updatedAt
            : (a as DirectConversationModel).updatedAt;
        final bTime = b is TeamConversationModel
            ? b.updatedAt
            : (b as DirectConversationModel).updatedAt;
        return bTime.compareTo(aTime);
      });
    }

    add(AllChatsUpdated(allConversations));
  }

  void _onAllChatsUpdated(
    AllChatsUpdated event,
    Emitter<TeamChatListState> emit,
  ) {
    emit(TeamChatListLoaded(event.conversations));
  }

  @override
  Future<void> close() {
    _teamChatsSubscription?.cancel();
    _directMessagesSubscription?.cancel();
    return super.close();
  }
}
