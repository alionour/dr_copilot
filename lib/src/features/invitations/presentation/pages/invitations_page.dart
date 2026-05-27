import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_event.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_state.dart';
import 'package:dr_copilot/src/features/invitations/presentation/pages/widgets/invitation_list_item.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';

class InvitationsPage extends StatefulWidget {
  final String clinicId;

  const InvitationsPage({super.key, required this.clinicId});

  @override
  State<InvitationsPage> createState() => _InvitationsPageState();
}

class _InvitationsPageState extends State<InvitationsPage> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          sl<InvitationBloc>()..add(LoadInvitations(widget.clinicId)),
      child: FutureBuilder<({UserModel? user, bool isAdmin})>(
        future: () async {
          final userResult = await sl<AuthUseCase>().getCurrentUser();
          final user = userResult.fold((l) => null, (r) => r);

          final isAdmin = user != null
              ? await user.isAdminInClinic(widget.clinicId)
              : false;

          // Debug logging
          if (user != null) {
            final role = await user.getRoleInClinic(widget.clinicId);
            log('========================================');
            log('INVITATIONS PAGE DEBUG:');
            log('User: ${user.email}');
            log('User role in clinic ${widget.clinicId}: $role');
            log('Is Admin: $isAdmin');
            log('========================================');
          }

          return (user: user, isAdmin: isAdmin);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: Text('invitations'.tr()),
              ),
              body: const ShimmerList(),
            );
          }

          final user = snapshot.data?.user;
          final isAdmin = snapshot.data?.isAdmin ?? false;

          return Scaffold(
            appBar: AppBar(
              title: Text('invitations'.tr()),
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => context.push(
                      '/invitations/create',
                      extra: {
                        'clinicId': widget.clinicId,
                        'currentUserId': user!.uid
                      },
                    ),
                  ),
              ],
            ),
            body: BlocConsumer<InvitationBloc, InvitationState>(
              listener: (context, state) {
                if (state is InvitationOperationSuccess) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(
                      content: SelectionArea(child: Text(state.message))));
                  context
                      .read<InvitationBloc>()
                      .add(LoadInvitations(widget.clinicId));
                } else if (state is InvitationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: SelectionArea(child: Text(state.message)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is InvitationLoading) {
                  return const ShimmerList();
                } else if (state is InvitationLoaded) {
                  final filteredInvitations = _selectedStatus == 'all'
                      ? state.invitations
                      : state.invitations
                          .where((i) => i.status == _selectedStatus)
                          .toList();

                  return Column(
                    children: [
                      _buildFilterRow(),
                      Expanded(
                        child: filteredInvitations.isEmpty
                            ? Center(child: Text('noInvitationsFound'.tr()))
                            : RefreshIndicator(
                                onRefresh: () async {
                                  context.read<InvitationBloc>().add(
                                        LoadInvitations(widget.clinicId),
                                      );
                                },
                                child: ListView.builder(
                                  itemCount: filteredInvitations.length,
                                  itemBuilder: (context, index) {
                                    final invitation =
                                        filteredInvitations[index];
                                    return InvitationListItem(
                                      invitation: invitation,
                                      onDelete: () {
                                        // Only admins can delete
                                        if (isAdmin) {
                                          context.read<InvitationBloc>().add(
                                                DeleteInvitation(invitation.id),
                                              );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: SelectionArea(
                                                  child: Text(
                                                      'onlyAdminsCanDelete'
                                                          .tr())),
                                            ),
                                          );
                                        }
                                      },
                                      onResend: () {
                                        // Only admins can resend
                                        if (isAdmin) {
                                          context.read<InvitationBloc>().add(
                                                ResendInvitation(invitation.id),
                                              );
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: SelectionArea(
                                                  child: Text(
                                                      'onlyAdminsCanResend'
                                                          .tr())),
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('all', 'status.all'.tr()),
          const SizedBox(width: 8),
          _buildFilterChip('pending', 'status.pending'.tr()),
          const SizedBox(width: 8),
          _buildFilterChip('accepted', 'status.accepted'.tr()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedStatus = status;
          });
        }
      },
    );
  }
}
