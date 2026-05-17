import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/team_chat/data/repositories/team_chat_repository.dart';
import '../bloc/chat_room_bloc.dart';
import 'package:timeago/timeago.dart' as timeago;

class TeamChatPage extends StatefulWidget {
  final String conversationId;

  const TeamChatPage({required this.conversationId, super.key});

  @override
  State<TeamChatPage> createState() => _TeamChatPageState();
}

class _TeamChatPageState extends State<TeamChatPage> {
  // Controllers
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _memberSearchController = TextEditingController();

  // Side panel state
  bool _showMembersPanel = false;

  // In-chat search
  bool _searchMode = false;
  String _searchQuery = '';

  // Member search filter
  String _memberSearchQuery = '';

  // Cached conversation data
  List<String> _participantIds = [];
  bool _isMember = true;
  String _teamOwnerId = '';
  String _teamName = '';
  List<String> _teamAdminIds = []; // team-level admins (not clinic admins)

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _memberSearchController.addListener(() {
      setState(() => _memberSearchQuery = _memberSearchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _memberSearchController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleMembersPanel() {
    setState(() => _showMembersPanel = !_showMembersPanel);
  }

  void _toggleSearch() {
    setState(() {
      _searchMode = !_searchMode;
      if (!_searchMode) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("Error: No user")));
    }

    // Gate the members button — permission-centric:
    //   - Team members can always see who else is in their team.
    //   - Any non-member who has been explicitly granted a team visibility
    //     permission (viewTeamMembers, viewTeamMessages, viewTeams, manageTeams)
    //     can also see the panel.
    bool canViewMembers() {
      return _isMember ||
          OwnerNotifier().hasPermission(AppPermission.viewTeamMembers) ||
          OwnerNotifier().hasPermission(AppPermission.viewTeamMessages) ||
          OwnerNotifier().hasPermission(AppPermission.viewTeams) ||
          OwnerNotifier().hasPermission(AppPermission.manageTeams);
    }

    return BlocProvider(
      create: (context) =>
          sl<ChatRoomBloc>()..add(LoadMessages(widget.conversationId)),
      child: Scaffold(
        appBar: AppBar(
          // In search mode the title becomes a search field
          title: _searchMode
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search messages…',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                )
              : Text(_teamName.isNotEmpty ? _teamName : 'chat'.tr()),
          actions: [
            // Search toggle
            IconButton(
              icon: Icon(_searchMode ? Icons.close : Icons.search),
              onPressed: _toggleSearch,
              tooltip: _searchMode ? 'Close search' : 'Search messages',
            ),
            // Members panel toggle — driven by authoritative custom_teams.memberIds
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('custom_teams')
                  .doc(widget.conversationId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  final memberIds = List<String>.from(data?['memberIds'] ?? []);
                  _participantIds = memberIds;
                  _isMember = memberIds.contains(currentUser.uid);
                  _teamAdminIds = List<String>.from(data?['adminIds'] ?? []);
                  if (_teamOwnerId.isEmpty || _teamOwnerId != (data?['ownerId'] ?? '')) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _teamOwnerId = data?['ownerId'] ?? '');
                    });
                  }
                  // Fetch team name from conversation metadata once
                  if (_teamName.isEmpty) {
                    FirebaseFirestore.instance
                        .collection('team_conversations')
                        .doc(widget.conversationId)
                        .get()
                        .then((doc) {
                      if (doc.exists && mounted) {
                        final meta = (doc.data()?['metadata'] as Map<String, dynamic>?);
                        setState(() => _teamName = meta?['teamName'] ?? '');
                      }
                    }).ignore();
                  }
                }
                if (!canViewMembers()) return const SizedBox();
                return IconButton(
                  icon: Icon(_showMembersPanel ? Icons.people : Icons.people_outline),
                  onPressed: _toggleMembersPanel,
                  tooltip: _showMembersPanel ? 'Hide Members' : 'View Members',
                );
              },
            ),
          ],
        ),
        body: Builder(
          builder: (context) {
            return Row(
              children: [
                // ── Main chat column ──────────────────────────────────────
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: BlocConsumer<ChatRoomBloc, ChatRoomState>(
                          listener: (context, state) {
                            if (state is ChatRoomLoaded) {
                              _scrollToBottom();
                            }
                          },
                          builder: (context, state) {
                            if (state is ChatRoomLoading) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (state is ChatRoomError) {
                              return Center(child: Text(state.message));
                            } else if (state is ChatRoomLoaded) {
                              // Apply search filter
                              final messages = _searchQuery.isEmpty
                                  ? state.messages
                                  : state.messages
                                      .where((m) => m.content
                                          .toLowerCase()
                                          .contains(_searchQuery))
                                      .toList();
                              if (messages.isEmpty) {
                                return Center(
                                    child: Text(_searchQuery.isNotEmpty
                                        ? 'No messages match "${_searchController.text}"'
                                        : "sayHello".tr()));
                              }
                              return ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe =
                                      message.senderId == currentUser.uid;
                                  final canPin =
                                      _isMember && (_teamOwnerId == currentUser.uid ||
                                      OwnerNotifier().hasPermission(AppPermission.manageTeams));
                                  return GestureDetector(
                                    onLongPress: () => _showMessageOptions(
                                        context, message.id, message.content,
                                        isMe: isMe, canPin: canPin),
                                    child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: isMe
                                          ? MainAxisAlignment.end
                                          : MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (!isMe) ...[
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            child: Text(
                                              message.senderId
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Container(
                                          margin: EdgeInsets.zero,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .surfaceContainerHighest,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          constraints: BoxConstraints(
                                            maxWidth:
                                                MediaQuery.of(context).size.width *
                                                    0.65,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                message.content,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: isMe
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .onPrimaryContainer
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                timeago.format(
                                                    message.timestamp),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      fontSize: 10,
                                                      color: isMe
                                                          ? Theme.of(context)
                                                              .colorScheme
                                                              .onPrimaryContainer
                                                              .withValues(
                                                                  alpha: 0.7)
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .onSurfaceVariant
                                                              .withValues(
                                                                  alpha: 0.7),
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 8),
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundImage:
                                                currentUser.photoURL != null
                                                    ? NetworkImage(
                                                        currentUser.photoURL!)
                                                    : null,
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primaryContainer,
                                            child: currentUser.photoURL == null
                                                ? Text(
                                                    (currentUser.displayName ??
                                                            currentUser.email ??
                                                            'U')
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ), // Padding
                                  ); // GestureDetector
                                },
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      // Message input — guards against stale participantIds by
                      // reading from custom_teams.memberIds (authoritative source).
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('custom_teams')
                            .doc(widget.conversationId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          bool isMember = false; // fail-closed: default no access
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data()
                                as Map<String, dynamic>?;
                            final List<dynamic> memberIds =
                                data?['memberIds'] ?? [];
                            isMember = memberIds.contains(currentUser.uid);
                          } else if (!snapshot.hasData) {
                            // Doc not yet loaded, fallback to participantIds
                            isMember = _isMember;
                          }
                          return _buildMessageInput(context, currentUser.uid,
                              isMember: isMember);
                        },
                      ),
                    ],
                  ),
                ),

                // ── Animated members side panel ───────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  width: _showMembersPanel ? 280 : 0,
                  child: _showMembersPanel
                      ? _buildMembersSidePanel(context, currentUser.uid)
                      : const SizedBox(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Enriched side panel ──────────────────────────────────────────────────

  Widget _buildMembersSidePanel(BuildContext context, String currentUserId) {
    final repo = sl<TeamChatRepository>();
    final canManage = _teamOwnerId == currentUserId ||
        _teamAdminIds.contains(currentUserId) ||
        OwnerNotifier().hasPermission(AppPermission.manageTeams);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _teamName.isNotEmpty ? _teamName[0].toUpperCase() : 'T',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _teamName.isNotEmpty ? _teamName : 'Team',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${_participantIds.length} members',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                  onPressed: _toggleMembersPanel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ── Members section ───────────────────────────────────────
                _sectionHeader(context, 'Members', Icons.people_outline,
                    trailing: canManage
                        ? IconButton(
                            icon: const Icon(Icons.person_add_outlined, size: 18),
                            onPressed: () {},
                            tooltip: 'Add member',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          )
                        : null),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    controller: _memberSearchController,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search members…',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 16),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _fetchParticipantDetails(_participantIds),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final all = snap.data ?? [];
                    final users = _memberSearchQuery.isEmpty
                        ? all
                        : all.where((u) {
                            final n = ((u['displayName'] ?? u['email'] ?? '') as String).toLowerCase();
                            return n.contains(_memberSearchQuery);
                          }).toList();
                    return Column(
                      children: users.map((user) {
                        final name = user['displayName'] ?? user['email'] ?? 'Unknown';
                        final email = user['email'] as String? ?? '';
                        final uid = user['uid'] as String? ?? '';
                        final isOwner = uid == _teamOwnerId;
                        final isAdmin = _teamAdminIds.contains(uid);
                        final isYou = uid == currentUserId;
                        return ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Text(name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                          title: Text(name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          subtitle: email.isNotEmpty
                              ? Text(email,
                                  style: TextStyle(fontSize: 11,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOwner) _badge(context, '👑 Owner', Colors.amber),
                              if (isAdmin && !isOwner) _badge(context, '🛡️ Admin', Colors.blue),
                              if (isYou && !isOwner && !isAdmin) _badge(context, 'You', Theme.of(context).colorScheme.primary),
                              if (canManage && !isYou && !isOwner &&
                                  (_teamOwnerId == currentUserId ||
                                   OwnerNotifier().hasPermission(AppPermission.manageTeams) ||
                                   !isAdmin))
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 16, color: Colors.red),
                                  onPressed: () => _confirmRemoveMember(context, uid, name, repo),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Remove',
                                ),
                            ],
                          ),
                          onTap: () => _showMemberProfile(context, user),
                        );
                      }).toList(),
                    );
                  },
                ),
                const Divider(),

                // ── Pinned messages ───────────────────────────────────────
                _sectionHeader(context, 'Pinned Messages', Icons.push_pin_outlined),
                FutureBuilder<List<dynamic>>(
                  future: repo.getPinnedMessages(widget.conversationId),
                  builder: (context, snap) {
                    final pins = snap.data ?? [];
                    if (pins.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text('No pinned messages',
                            style: TextStyle(fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      );
                    }
                    return Column(
                      children: pins.map<Widget>((msg) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.push_pin, size: 16),
                        title: Text(msg.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                        trailing: canManage
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 14),
                                onPressed: () => repo.unpinMessage(widget.conversationId, msg.id),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              )
                            : null,
                      )).toList(),
                    );
                  },
                ),
                const Divider(),

                // ── Mute notifications ────────────────────────────────────
                _sectionHeader(context, 'Notifications', Icons.notifications_outlined),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('team_conversations')
                      .doc(widget.conversationId)
                      .snapshots(),
                  builder: (context, snap) {
                    bool muted = false;
                    if (snap.hasData && snap.data!.exists) {
                      final d = snap.data!.data() as Map<String, dynamic>?;
                      muted = List<String>.from(d?['mutedBy'] ?? []).contains(currentUserId);
                    }
                    return SwitchListTile(
                      dense: true,
                      title: const Text('Mute this team', style: TextStyle(fontSize: 13)),
                      value: muted,
                      onChanged: (val) => val
                          ? repo.muteConversation(widget.conversationId, currentUserId)
                          : repo.unmuteConversation(widget.conversationId, currentUserId),
                    );
                  },
                ),
                const Divider(),

                // ── Leave team (members only) ─────────────────────────────
                if (_isMember)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.exit_to_app, color: Colors.red),
                      label: const Text('Leave Team',
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red)),
                      onPressed: () => _confirmLeaveTeam(context, currentUserId, repo),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, IconData icon,
      {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.5,
                )),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  void _showMemberProfile(BuildContext context, Map<String, dynamic> user) {
    final name = user['displayName'] ?? user['email'] ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final uid = user['uid'] as String? ?? '';
    final isOwner = uid == _teamOwnerId;
    final isAdmin = _teamAdminIds.contains(uid);
    final isYou = uid == FirebaseAuth.instance.currentUser?.uid;
    final repo = sl<TeamChatRepository>();

    // Only team owner or clinic admin with global manageTeams permission can manage team admins
    final canManageAdmins = _teamOwnerId == (FirebaseAuth.instance.currentUser?.uid) ||
        OwnerNotifier().hasPermission(AppPermission.manageTeams);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 24,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  )),
            ),
            const SizedBox(height: 12),
            Text(name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (email.isNotEmpty) ...[const SizedBox(height: 4), Text(email)],
            const SizedBox(height: 16),
            if (canManageAdmins && !isOwner && !isYou) ...[
              const Divider(),
              ListTile(
                leading: Icon(isAdmin ? Icons.security_outlined : Icons.verified_user_outlined),
                title: Text(isAdmin ? 'Demote from Admin' : 'Promote to Admin'),
                onTap: () {
                  Navigator.pop(context);
                  if (isAdmin) {
                    repo.demoteFromAdmin(widget.conversationId, uid);
                  } else {
                    repo.promoteToAdmin(widget.conversationId, uid);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(BuildContext context, String uid, String name,
      TeamChatRepository repo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove $name from this team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              repo.leaveTeam(widget.conversationId, uid);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveTeam(BuildContext context, String uid,
      TeamChatRepository repo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Team'),
        content: const Text('Are you sure you want to leave this team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              repo.leaveTeam(widget.conversationId, uid);
              setState(() => _showMembersPanel = false);
            },
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ── Message input / read-only banner ─────────────────────────────────────

  Widget _buildMessageInput(BuildContext context, String currentUserId,
      {required bool isMember}) {
    if (!isMember) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        color: Theme.of(context)
            .colorScheme
            .errorContainer
            .withValues(alpha: 0.08),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Only team members can send messages to this team.",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: "typeMessage".tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(context, currentUserId),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => _sendMessage(context, currentUserId),
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showMessageOptions(BuildContext context, String messageId,
      String content, {required bool isMe, required bool canPin}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        final repo = sl<TeamChatRepository>();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copy text'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')));
                },
              ),
              if (canPin)
                ListTile(
                  leading: const Icon(Icons.push_pin_outlined),
                  title: const Text('Pin message'),
                  onTap: () {
                    repo.pinMessage(widget.conversationId, messageId);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage(BuildContext context, String currentUserId) {
    if (_textController.text.trim().isEmpty) return;

    context.read<ChatRoomBloc>().add(
          SendMessage(
            conversationId: widget.conversationId,
            senderId: currentUserId,
            content: _textController.text.trim(),
          ),
        );
    _textController.clear();
  }

  Future<List<Map<String, dynamic>>> _fetchParticipantDetails(
      List<String> uids) async {
    final list = <Map<String, dynamic>>[];
    for (final uid in uids) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        data['uid'] = uid;
        list.add(data);
      } else {
        list.add({'uid': uid, 'displayName': 'User ($uid)', 'email': ''});
      }
    }
    return list;
  }
}
