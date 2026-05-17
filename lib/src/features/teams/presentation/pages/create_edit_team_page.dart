import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/teams/domain/models/custom_team_model.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_bloc.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_event.dart';
import 'package:dr_copilot/src/features/teams/presentation/bloc/teams_state.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class CreateEditTeamPage extends StatefulWidget {
  final CustomTeamModel? team;

  const CreateEditTeamPage({super.key, this.team});

  @override
  State<CreateEditTeamPage> createState() => _CreateEditTeamPageState();
}

class _CreateEditTeamPageState extends State<CreateEditTeamPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _selectedMembers = <String>{};
  List<UserModel> _availableUsers = [];
  bool _isLoading = true;

  bool get _isEditing => widget.team != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.team!.name;
      _selectedMembers.addAll(widget.team!.memberIds);
    }
    _loadClinicMembers();
  }

  Future<void> _loadClinicMembers() async {
    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (clinicId == null) {
      return;
    }

    try {
      debugPrint('[Teams] Loading members for clinic: $clinicId');

      final membersSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('members')
          .get();

      debugPrint('[Teams] Found ${membersSnapshot.docs.length} member docs');

      final users = <UserModel>[];
      for (final memberDoc in membersSnapshot.docs) {
        debugPrint('[Teams] Loop iteration for: ${memberDoc.id}');
        // Fetch actual user data from users collection
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberDoc.id)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          try {
            // Add uid to the data since it's not stored as a field
            final userData = userDoc.data()!;
            userData['uid'] = memberDoc.id;
            users.add(UserModel.fromJson(userData));
            debugPrint('[Teams] Added user successfully');
          } catch (e) {
            debugPrint('[Teams] Error parsing: $e');
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableUsers = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading clinic members: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectionArea(child: Text('errorLoadingMembers'.tr())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TeamsBloc, TeamsState>(
      listener: (context, state) {
        if (state is TeamOperationSuccess) {
          // Pop with success result when operation completes
          Navigator.pop(context, true);
        } else if (state is TeamsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text(state.message)), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'editTeam'.tr() : 'createTeam'.tr()),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'teamName'.tr(),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'pleaseEnterTeamName'.tr();
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'selectMembers'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_availableUsers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'noMembersAvailable'.tr(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      else
                        ..._availableUsers.map((user) {
                          final isSelected = _selectedMembers.contains(
                            user.uid,
                          );
                          return CheckboxListTile(
                            title: Text(user.displayName ?? 'Unknown'),
                            subtitle: Text(user.email ?? ''),
                            value: isSelected,
                            onChanged: (selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedMembers.add(user.uid);
                                } else {
                                  _selectedMembers.remove(user.uid);
                                }
                              });
                            },
                          );
                        }),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveTeam,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        child: Text(
                          _isEditing ? 'updateTeam'.tr() : 'createTeam'.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _saveTeam() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check permission for creating new teams (not editing)
    if (!_isEditing &&
        !OwnerNotifier().hasPermission(AppPermission.createTeam)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectionArea(child: Text('noPermissionCreateTeam'.tr())),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: SelectionArea(child: Text('pleaseSelectAtLeastOneMember'.tr())),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (currentUser == null || clinicId == null) {
      return;
    }

    // Include owner in members list
    final memberIds = _selectedMembers.toList();
    if (!memberIds.contains(currentUser.uid)) {
      memberIds.add(currentUser.uid);
    }

    final team = CustomTeamModel(
      id:
          widget.team?.id ??
          FirebaseFirestore.instance.collection('custom_teams').doc().id,
      clinicId: clinicId,
      ownerId: currentUser.uid,
      name: _nameController.text.trim(),
      memberIds: memberIds,
      createdAt: widget.team?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      context.read<TeamsBloc>().add(UpdateTeamEvent(team: team));
    } else {
      context.read<TeamsBloc>().add(CreateTeamEvent(team: team));
    }
    // Navigation handled by BlocListener
  }
}

