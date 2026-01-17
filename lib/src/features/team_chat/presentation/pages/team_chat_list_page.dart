import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import '../bloc/team_chat_list_bloc.dart';
import '../../data/models/team_conversation_model.dart';

class TeamChatListPage extends StatelessWidget {
  const TeamChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Get provider and auth state
    final authState = context.read<AuthBloc>().state;
    final userModel = authState is AuthSignedIn ? authState.user : null;
    final clinicId = userModel?.primaryClinicId;

    if (currentUser == null || clinicId == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view chats")),
      );
    }

    return BlocProvider(
      create: (context) =>
          sl<TeamChatListBloc>()..add(LoadTeamChats(currentUser.uid, clinicId)),
      child: Scaffold(
        appBar: AppBar(title: Text("teamChat".tr())),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            context.push('/team_chat/new');
          },
          child: const Icon(Icons.add),
        ),
        body: BlocBuilder<TeamChatListBloc, TeamChatListState>(
          builder: (context, state) {
            if (state is TeamChatListLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TeamChatListError) {
              return Center(child: Text(state.message));
            } else if (state is TeamChatListLoaded) {
              if (state.conversations.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text("noChatsYet".tr()),
                      TextButton(
                        onPressed: () => context.push('/team_chat/new'),
                        child: Text("startNewChat".tr()),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                itemCount: state.conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final conversation = state.conversations[index];
                  return _ConversationTile(
                    conversation: conversation,
                    currentUserId: currentUser.uid,
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final dynamic
      conversation; // Can be TeamConversationModel or DirectConversationModel
  final String currentUserId;

  const _ConversationTile({
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    // Extract common fields from either type
    final String conversationId;
    final List<String> participantIds;
    final String? lastMessage;
    final DateTime? lastMessageTime;
    final bool isDirectMessage = conversation is! TeamConversationModel;

    if (conversation is TeamConversationModel) {
      conversationId = conversation.id;
      participantIds = conversation.participantIds;
      lastMessage = conversation.lastMessage;
      lastMessageTime = conversation.lastMessageTimestamp;
    } else {
      // DirectConversationModel
      conversationId = conversation.id;
      participantIds = conversation.participantIds;
      lastMessage = conversation.lastMessage;
      lastMessageTime = conversation.lastMessageTimestamp;
    }

    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => "Unknown",
    );

    return ListTile(
      leading: CircleAvatar(
        child: isDirectMessage
            ? const Icon(Icons.person_outline)
            : const Icon(Icons.group_outlined),
      ),
      title: Text(
        isDirectMessage
            ? otherUserId // Direct message - show other user
            : (conversation as TeamConversationModel).metadata['teamName'] ??
                'Team Chat',
      ),
      subtitle: lastMessage != null
          ? Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: lastMessageTime != null
          ? Text(
              _formatTime(lastMessageTime),
              style: Theme.of(context).textTheme.bodySmall,
            )
          : null,
      onTap: () {
        context.push('/team_chat/$conversationId');
      },
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
