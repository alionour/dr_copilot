import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import '../cubit/user_discovery_cubit.dart';

class UserSelectionPage extends StatelessWidget {
  const UserSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
    final clinicId = ownerNotifier.clinicId;

    if (currentUser == null || clinicId == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Missing user or clinic info")),
      );
    }

    return BlocProvider(
      create: (context) =>
          sl<UserDiscoveryCubit>()
            ..loadClinicMembers(clinicId, currentUser.uid),
      child: BlocListener<UserDiscoveryCubit, UserDiscoveryState>(
        listener: (context, state) {
          if (state is ChatStarted) {
            // Replace this page with the chat page
            context.pushReplacement('/team_chat/${state.conversationId}');
          } else if (state is UserDiscoveryError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: Text("newMessage".tr())),
          body: BlocBuilder<UserDiscoveryCubit, UserDiscoveryState>(
            builder: (context, state) {
              if (state is UserDiscoveryLoading || state is ChatStarting) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is UserDiscoveryLoaded) {
                if (state.users.isEmpty) {
                  return Center(child: Text("noTeamMembersFound".tr()));
                }
                return ListView.builder(
                  itemCount: state.users.length,
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Text(
                                user.displayName
                                        ?.substring(0, 1)
                                        .toUpperCase() ??
                                    "?",
                              )
                            : null,
                      ),
                      title: Text(user.displayName ?? user.email ?? "Unknown"),
                      subtitle: Text(user.email ?? ""),
                      onTap: () {
                        context.read<UserDiscoveryCubit>().startChat(
                          clinicId,
                          currentUser.uid,
                          user.uid,
                        );
                      },
                    );
                  },
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ),
    );
  }
}

