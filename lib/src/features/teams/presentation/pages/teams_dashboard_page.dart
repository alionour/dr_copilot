import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_bloc.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_event.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_state.dart';
import 'package:dr_copilot/src/features/teams/presentation/pages/create_edit_team_page.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
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
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSignedIn && authState.user?.primaryClinicId != null) {
      context.read<TeamsBloc>().add(
        LoadTeamsEvent(clinicId: authState.user!.primaryClinicId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('teamsTitle'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: BlocConsumer<TeamsBloc, TeamsState>(
        listener: (context, state) {
          if (state is TeamOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            _loadTeams();
          } else if (state is TeamsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TeamsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is TeamsLoaded) {
            if (state.teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey[400]),
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
                          icon: const Icon(Icons.chat),
                          onPressed: () => _startTeamChat(context, team),
                          tooltip: 'startChat'.tr(),
                        ),
                        PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit),
                                  const SizedBox(width: 8),
                                  Text('edit'.tr()),
                                ],
                              ),
                            ),
                            if (OwnerNotifier().hasPermission(
                              AppPermission.archiveTeam,
                            ))
                              PopupMenuItem(
                                value: 'archive',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.archive,
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
      floatingActionButton:
          OwnerNotifier().hasPermission(AppPermission.createTeam)
          ? FloatingActionButton.extended(
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
              icon: const Icon(Icons.add),
              label: Text('createTeam'.tr()),
            )
          : null,
    );
  }

  void _showArchiveConfirmation(String teamId, String teamName) {
    final teamsBloc = context.read<TeamsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('archiveTeam'.tr()),
        content: Text(
          'archiveTeamConfirm'.tr(namedArgs: {'teamName': teamName}),
        ),
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

      // Try to find existing conversation for this team
      final existingConversations = await firestore
          .collection('team_conversations')
          .where('metadata.teamId', isEqualTo: team.id)
          .limit(1)
          .get();

      String conversationId;

      if (existingConversations.docs.isNotEmpty) {
        // Use existing conversation
        conversationId = existingConversations.docs.first.id;
      } else {
        // Create new conversation
        conversationId = firestore.collection('team_conversations').doc().id;

        await firestore
            .collection('team_conversations')
            .doc(conversationId)
            .set({
              'clinicId': team.clinicId,
              'participantIds': team.memberIds,
              'createdAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
              'metadata': {'teamId': team.id, 'teamName': team.name},
            });
      }

      if (context.mounted) {
        // Navigate to the chat page
        context.push('/team_chat/$conversationId');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('errorStartingChat'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

