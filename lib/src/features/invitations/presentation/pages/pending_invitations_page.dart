import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/auth/domain/usecases/login_usecase.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_event.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class PendingInvitationsPage extends StatefulWidget {
  const PendingInvitationsPage({super.key});

  @override
  State<PendingInvitationsPage> createState() => _PendingInvitationsPageState();
}

class _PendingInvitationsPageState extends State<PendingInvitationsPage> {
  @override
  void initState() {
    super.initState();
    final user = auth.FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      context.read<InvitationBloc>().add(LoadInvitationsForEmail(user.email!));
    }
  }

  Future<void> _acceptInvitation(String invitationId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result =
        await sl<AuthUseCase>().acceptInvitationForUser(invitationId);

    if (!mounted) return;
    Navigator.of(context).pop(); // Dismiss loading

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text(failure.message))),
        );
      },
      (_) async {
        // Success
        await context.read<OwnerNotifier>().loadOwnerIdAndClinicId();
        if (mounted) context.go('/home');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Invitations'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AuthBloc>().add(SignOutEvent());
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: BlocBuilder<InvitationBloc, InvitationState>(
        builder: (context, state) {
          if (state is InvitationLoading) {
            return const ShimmerList(itemCount: 5);
          }

          if (state is InvitationError) {
            return Center(
              child: SelectionArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Error: ${state.message}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        final user = auth.FirebaseAuth.instance.currentUser;
                        if (user != null && user.email != null) {
                          context
                              .read<InvitationBloc>()
                              .add(LoadInvitationsForEmail(user.email!));
                        }
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is InvitationLoaded) {
            final invitations = state.invitations;
            if (invitations.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mail_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 24),
                      const Text(
                        'No pending invitations found.',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'We couldn\'t find any invitations for your email address. Please ask your clinic administrator to send you an invitation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => context.go('/onboarding-choice'),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: invitations.length,
              itemBuilder: (context, index) {
                final invite = invitations[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(Icons.business, color: Colors.white),
                    ),
                    title: Text(
                      'Invitation to join ${invite.clinicName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Role: ${invite.roles.join(", ")}'),
                        Text(
                          'Sent on: ${invite.createdAt.toLocal().toString().split(' ')[0]}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            final user = auth.FirebaseAuth.instance.currentUser;
                            if (user != null && user.email != null) {
                              context.read<InvitationBloc>().add(
                                    RejectInvitation(invite.id, user.email!),
                                  );
                            }
                          },
                          child: const Text('Reject'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _acceptInvitation(invite.id),
                          child: const Text('Accept'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
