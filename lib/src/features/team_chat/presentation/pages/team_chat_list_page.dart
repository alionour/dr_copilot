import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import '../bloc/team_chat_list_bloc.dart';
import '../../data/models/team_conversation_model.dart';


class TeamChatListPage extends StatelessWidget {
  const TeamChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerNotifier = context.watch<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId;

    if (currentUser == null || clinicId == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to view chats")),
      );
    }

    // All authenticated clinic members can see the Messages tab.
    // The BLoC query filters team conversations to only those where the user
    // is in participantIds — so non-team-members will only see their own DMs.
    // Elevated permissions (viewTeamMessages, manageTeams) are checked inside
    // individual chat rooms for admin-level actions, not here.

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
              return const ShimmerList();
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
                    key: ValueKey(conversation.id),
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

class _ConversationTile extends StatefulWidget {
  final dynamic
      conversation; // Can be TeamConversationModel or DirectConversationModel
  final String currentUserId;

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile> {
  static final Map<String, String> _nameCache = {};
  String? _resolvedName;
  bool _loadingName = true;
  String _otherUserId = '';

  @override
  void initState() {
    super.initState();
    _resolveName();
  }

  @override
  void didUpdateWidget(covariant _ConversationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-resolve if the conversation changed (different ID or different list position)
    if (oldWidget.conversation.id != widget.conversation.id) {
      _loadingName = true;
      _resolvedName = null;
      _otherUserId = '';
      _resolveName();
    }
  }

  Future<void> _resolveName() async {
    final isDirectMessage = widget.conversation is! TeamConversationModel;
    if (!isDirectMessage) {
      if (mounted) setState(() => _loadingName = false);
      return;
    }

    final participantIds = widget.conversation.participantIds as List<String>;
    _otherUserId = participantIds.firstWhere(
      (id) => id != widget.currentUserId,
      orElse: () => "Unknown",
    );

    // Check cache first
    if (_nameCache.containsKey(_otherUserId)) {
      _resolvedName = _nameCache[_otherUserId];
      if (mounted) setState(() => _loadingName = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_otherUserId)
          .get();
      if (doc.exists && doc.data() != null) {
        _resolvedName = doc.data()!['displayName'] ??
            doc.data()!['email'] ??
            'User ($_otherUserId)';
      } else {
        _resolvedName = 'User ($_otherUserId)';
      }
    } catch (_) {
      _resolvedName = 'User ($_otherUserId)';
    }
    _nameCache[_otherUserId] = _resolvedName!;
    if (mounted) setState(() => _loadingName = false);
  }

  @override
  Widget build(BuildContext context) {
    // Extract common fields from either type
    final String conversationId;
    final String? lastMessage;
    final DateTime? lastMessageTime;
    final bool isDirectMessage =
        widget.conversation is! TeamConversationModel;

    if (widget.conversation is TeamConversationModel) {
      conversationId = widget.conversation.id;
      lastMessage = widget.conversation.lastMessage;
      lastMessageTime = widget.conversation.lastMessageTimestamp;
    } else {
      // DirectConversationModel
      conversationId = widget.conversation.id;
      lastMessage = widget.conversation.lastMessage;
      lastMessageTime = widget.conversation.lastMessageTimestamp;
    }

    return ListTile(
      leading: CircleAvatar(
        child: isDirectMessage
            ? const Icon(Icons.person_outline)
            : const Icon(Icons.group_outlined),
      ),
      title: Text(
        isDirectMessage
            ? (_loadingName ? 'Loading...' : (_resolvedName ?? _otherUserId))
            : (widget.conversation as TeamConversationModel)
                        .metadata['teamName'] ??
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
