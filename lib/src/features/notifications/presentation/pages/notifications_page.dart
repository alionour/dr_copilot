import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:dr_copilot/src/features/notifications/presentation/pages/admin_send_notification_page.dart';

import 'package:dr_copilot/src/features/notifications/presentation/widgets/notification_list_item.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/send_notification/send_notification_bloc.dart';
import 'package:dr_copilot/src/features/notifications/notifications_injections.dart'
    as notif_sl;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String? _userId;
  bool _isAdmin = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userId == null) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _userId = firebaseUser.uid;
        context.read<NotificationsBloc>().add(
          WatchNotificationsEvent(_userId!),
        );
        _checkIfAdmin();
      }
    }
  }

  void _checkIfAdmin() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();

        if (userDoc.exists && mounted) {
          final user = UserModel.fromJson({
            ...userDoc.data()!,
            'uid': userDoc.id,
          });
          // Check if user is admin in their primary clinic
          if (user.primaryClinicId != null) {
            final isAdmin = await user.isAdminInClinic(user.primaryClinicId!);
            setState(() {
              _isAdmin = isAdmin;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking admin role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
        leading: const Icon(Icons.notifications_outlined),
        actions: [if (navMenuButton != null) navMenuButton],
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: BlocConsumer<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('errorLoadingNotifications'.tr()),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_userId != null) {
                        context.read<NotificationsBloc>().add(
                          RefreshNotificationsEvent(_userId!),
                        );
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: Text('retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (state is NotificationsLoaded) {
            if (state.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'noNotifications'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'noNotificationsDescription'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                if (_userId != null) {
                  context.read<NotificationsBloc>().add(
                    RefreshNotificationsEvent(_userId!),
                  );
                }
              },
              child: Column(
                children: [
                  if (state.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Icon(
                            Icons.notifications_active,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${'youHave'.tr()} ${state.unreadCount} ${'unreadNotifications'.tr()}',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.notifications.length,
                      itemBuilder: (context, index) {
                        final notification = state.notifications[index];
                        return NotificationListItem(
                          notification: notification,
                          onMarkAsRead: () {
                            context.read<NotificationsBloc>().add(
                              MarkNotificationAsReadEvent(notification.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }

          // Initial state or user not signed in
          if (_userId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'pleaseSignIn'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => notif_sl.sl<SendNotificationBloc>(),
                      child: const AdminSendNotificationPage(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.send),
              label: Text('send_notification'.tr()),
            )
          : null,
    );
  }
}
