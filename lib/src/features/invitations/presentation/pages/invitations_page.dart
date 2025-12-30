import 'dart:developer';

import 'package:flutter/material.dart';
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

class InvitationsPage extends StatelessWidget {
  final String clinicId;

  const InvitationsPage({super.key, required this.clinicId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<InvitationBloc>()..add(LoadInvitations(clinicId)),
      child: FutureBuilder<({UserModel? user, bool isAdmin})>(
        future: () async {
          final userResult = await sl<AuthUseCase>().getCurrentUser();
          final user = userResult.fold((l) => null, (r) => r);

          final isAdmin =
              user != null ? await user.isAdminInClinic(clinicId) : false;

          // Debug logging
          if (user != null) {
            final role = await user.getRoleInClinic(clinicId);
            log('========================================');
            log('INVITATIONS PAGE DEBUG:');
            log('User: ${user.email}');
            log('User role in clinic $clinicId: $role');
            log('Is Admin: $isAdmin');
            log('========================================');
          }

          return (user: user, isAdmin: isAdmin);
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
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
                      extra: {'clinicId': clinicId, 'currentUserId': user!.uid},
                    ),
                  ),
              ],
            ),
            body: BlocConsumer<InvitationBloc, InvitationState>(
              listener: (context, state) {
                if (state is InvitationOperationSuccess) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.message)));
                  context.read<InvitationBloc>().add(LoadInvitations(clinicId));
                } else if (state is InvitationError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is InvitationLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is InvitationLoaded) {
                  if (state.invitations.isEmpty) {
                    return Center(child: Text('noInvitationsFound'.tr()));
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<InvitationBloc>().add(
                            LoadInvitations(clinicId),
                          );
                    },
                    child: ListView.builder(
                      itemCount: state.invitations.length,
                      itemBuilder: (context, index) {
                        final invitation = state.invitations[index];
                        return InvitationListItem(
                          invitation: invitation,
                          onDelete: () {
                            // Only admins can delete
                            if (isAdmin) {
                              context.read<InvitationBloc>().add(
                                    DeleteInvitation(invitation.id),
                                  );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('onlyAdminsCanDelete'.tr()),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('onlyAdminsCanResend'.tr()),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
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
}
