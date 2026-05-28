import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_bloc.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_event.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_state.dart';
import 'package:dr_copilot/src/features/teams/presentation/pages/create_edit_team_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class TeamsDashboardPage extends StatefulWidget {
  const TeamsDashboardPage({super.key});

  @override
  State<TeamsDashboardPage> createState() => _TeamsDashboardPageState();
}

class _TeamsDashboardPageState extends State<TeamsDashboardPage> {
  @override
  void initState() {
    super.initState();
    // Load teams initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeams();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload teams whenever dependencies change (e.g., returning from navigation)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTeams();
      }
    });
  }

  void _loadTeams() {
    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (clinicId != null) {
      context.read<TeamsBloc>().add(
            LoadTeamsEvent(clinicId: clinicId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('teamsTitle'.tr()),
        actions: [
          if (OwnerNotifier().hasPermission(AppPermission.createTeam))
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'addTeam'.tr(),
              onPressed: () async {
                final teamsBloc = context.read<TeamsBloc>();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: teamsBloc,
                      child: const CreateEditTeamPage(),
                    ),
                  ),
                );

                // Reload teams if a team was created/updated
                if (result == true) {
                  _loadTeams();
                }
              },
            ),
        ],
      ),
      body: BlocConsumer<TeamsBloc, TeamsState>(
        listener: (context, state) {
          if (state is TeamOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectionArea(child: Text(state.message)),
                backgroundColor: Colors.green,
              ),
            );
            _loadTeams();
          } else if (state is TeamsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectionArea(child: Text(state.message)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TeamsLoading) {
            return const ShimmerList();
          }

          if (state is TeamsLoaded) {
            if (state.teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'noTeamsYet'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'createFirstTeam'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.teams.length,
              itemBuilder: (context, index) {
                final team = state.teams[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(team.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(team.name),
                    subtitle: Text(
                      '${'membersCount'.tr()}: ${team.memberIds.length}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_outlined),
                          onPressed: () => _startTeamChat(context, team),
                          tooltip: 'startChat'.tr(),
                        ),
                        Builder(
                          builder: (context) {
                            final currentUserId = auth.FirebaseAuth.instance.currentUser?.uid;
                            final canEdit = OwnerNotifier().hasPermission(AppPermission.manageTeams) ||
                                            team.ownerId == currentUserId;
                            final canArchive = OwnerNotifier().hasPermission(AppPermission.archiveTeam) ||
                                               team.ownerId == currentUserId;

                            if (!canEdit && !canArchive) {
                              return const SizedBox();
                            }

                            return PopupMenuButton(
                              itemBuilder: (context) => [
                                if (canEdit)
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit_outlined),
                                        const SizedBox(width: 8),
                                        Text('edit'.tr()),
                                      ],
                                    ),
                                  ),
                                if (canArchive)
                                  PopupMenuItem(
                                    value: 'archive',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.archive_outlined,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'archiveTeam'.tr(),
                                          style: const TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final teamsBloc = context.read<TeamsBloc>();
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider.value(
                                        value: teamsBloc,
                                        child: CreateEditTeamPage(team: team),
                                      ),
                                    ),
                                  );

                                  // Reload teams if a team was updated
                                  if (result == true) {
                                    _loadTeams();
                                  }
                                } else if (value == 'archive') {
                                  _showArchiveConfirmation(team.id, team.name);
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(child: Text(''));
        },
      ),
    );
  }

  void _showArchiveConfirmation(String teamId, String teamName) {
    final teamsBloc = context.read<TeamsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('archiveTeam'.tr()),
        content: SelectionArea(child: Text(
          'archiveTeamConfirm'.tr(namedArgs: {'teamName': teamName}),
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              teamsBloc.add(ArchiveTeamEvent(teamId: teamId));
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text('archiveTeam'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _startTeamChat(BuildContext context, dynamic team) async {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthSignedIn || authState.user == null) {
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final currentUserId = authState.user!.uid;

      // 1. Check if user has access to view/open this chat.
      //    Any of these permissions grants access (permission-centric, not role-centric):
      //      - isMember:          direct team member → full access (read + write)
      //      - viewTeamMessages:  explicit message-read grant → read-only chat if not member
      final isMember = team.memberIds.contains(currentUserId);
      final hasGlobalAccess =
          OwnerNotifier().hasPermission(AppPermission.viewTeamMessages);

      if (!isMember && !hasGlobalAccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectionArea(
              child: Text('onlyTeamMembersCanViewThisChat'.tr()),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // 2. Ensure team_conversation document exists with team.id as the document ID
      final conversationRef = firestore.collection('team_conversations').doc(team.id);
      final conversationDoc = await conversationRef.get();

      if (!conversationDoc.exists) {
        await conversationRef.set({
          'clinicId': team.clinicId,
          'participantIds': List<String>.from(team.memberIds),
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'metadata': {
            'teamId': team.id,
            'teamName': team.name,
          },
        });
      }

      if (context.mounted) {
        // Navigate to the chat page
        context.push('/team_chat/${team.id}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectionArea(child: Text('Error: $e')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
