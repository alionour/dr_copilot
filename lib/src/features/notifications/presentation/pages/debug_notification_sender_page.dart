import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DebugNotificationSenderPage extends StatefulWidget {
  const DebugNotificationSenderPage({super.key});

  @override
  State<DebugNotificationSenderPage> createState() =>
      _DebugNotificationSenderPageState();
}

class _DebugNotificationSenderPageState
    extends State<DebugNotificationSenderPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _userIdController = TextEditingController();

  NotificationType _selectedType = NotificationType.system;
  bool _isLoading = false;
  List<String> _recentUserIds = [];

  @override
  void initState() {
    super.initState();
    _loadRecentUsers();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _userIdController.text = currentUser.uid;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentUsers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();

      final userIds = snapshot.docs
          .map((doc) => doc.data()['userId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      setState(() {
        _recentUserIds = userIds;
      });
    } catch (e) {
      debugPrint('Error loading recent users: $e');
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final notification = NotificationModel(
        id: '',
        userId: _userIdController.text.trim(),
        title: _titleController.text.trim(),
        message: _bodyController.text.trim(),
        type: _selectedType,
        isRead: false,
        createdAt: DateTime.now(),
        sender: NotificationSender(
          type: NotificationSenderType.programmer,
          senderId: 'debug',
          senderName: 'Debug Mode',
        ),
        target: NotificationTarget(
          type: NotificationTargetType.allClinicOwners,
        ),
      );

      await FirebaseFirestore.instance
          .collection('notifications')
          .add(notification.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('notificationSent'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendToAllUsers() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm'.tr()),
        content: Text('sendToAllUsersConfirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('send'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      final batch = FirebaseFirestore.instance.batch();
      final now = DateTime.now();

      for (var userDoc in usersSnapshot.docs) {
        final notification = NotificationModel(
          id: '',
          userId: userDoc.id,
          title: _titleController.text.trim(),
          message: _bodyController.text.trim(),
          type: _selectedType,
          isRead: false,
          createdAt: now,
          sender: NotificationSender(
            type: NotificationSenderType.programmer,
            senderId: 'debug',
            senderName: 'Debug Mode',
          ),
          target: NotificationTarget(
            type: NotificationTargetType.allClinicOwners,
          ),
        );

        final docRef =
            FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(docRef, notification.toJson());
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'sentToUsers'.tr(args: [usersSnapshot.docs.length.toString()]),
            ),
            backgroundColor: Colors.green,
          ),
        );

        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error'.tr()}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('debugNotificationSender'.tr()),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'debugModeWarning'.tr(),
                                style: TextStyle(
                                  color: Colors.orange[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // User ID
                    TextFormField(
                      controller: _userIdController,
                      decoration: InputDecoration(
                        labelText: 'userIdLabel'.tr(),
                        hintText: 'userIdHint'.tr(),
                        border: const OutlineInputBorder(),
                        suffixIcon: _recentUserIds.isNotEmpty
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down),
                                onSelected: (value) {
                                  _userIdController.text = value;
                                },
                                itemBuilder: (context) => _recentUserIds
                                    .map(
                                      (id) => PopupMenuItem(
                                        value: id,
                                        child: Text(id),
                                      ),
                                    )
                                    .toList(),
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'pleaseEnterUserId'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notification Type
                    DropdownButtonFormField<NotificationType>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'notificationTypeLabel'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      items: NotificationType.values.map((type) {
                        IconData icon;
                        Color color;
                        switch (type) {
                          case NotificationType.appointment:
                            icon = Icons.calendar_today_outlined;
                            color = Colors.purple;
                            break;
                          case NotificationType.message:
                            icon = Icons.chat_bubble_outline;
                            color = Colors.indigo;
                            break;
                          case NotificationType.reminder:
                            icon = Icons.alarm_outlined;
                            color = Colors.teal;
                            break;
                          case NotificationType.system:
                            icon = Icons.info_outline;
                            color = Colors.blue;
                            break;
                          case NotificationType.payment:
                            icon = Icons.payment_outlined;
                            color = Colors.green;
                            break;
                          case NotificationType.report:
                            icon = Icons.assessment_outlined;
                            color = Colors.orange;
                            break;
                          case NotificationType.alert:
                            icon = Icons.warning_amber_rounded;
                            color = Colors.red;
                            break;
                          case NotificationType.task:
                            icon = Icons.task_alt_rounded;
                            color = Colors.blueGrey;
                            break;
                        }
                        // Use translation for enum if possible, or just capitalize
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(icon, color: color, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                type.toString().split('.').last.toUpperCase(),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'titleLabel'.tr(),
                        hintText: 'titleHint'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'pleaseEnterTitle'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Body
                    TextFormField(
                      controller: _bodyController,
                      decoration: InputDecoration(
                        labelText: 'bodyLabel'.tr(),
                        hintText: 'bodyHint'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'pleaseEnterBody'
                              .tr(); // I might need to add this key or reuse message_required? message_required exists.
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Quick Templates
                    ExpansionTile(
                      title: Text('quickTemplates'.tr()),
                      leading: const Icon(Icons.auto_awesome_outlined),
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_today_outlined,
                            color: Colors.purple,
                          ),
                          title: Text('appointmentReminder'.tr()),
                          onTap: () {
                            _titleController.text = 'Upcoming Appointment';
                            _bodyController.text =
                                'You have an appointment with Dr. Smith tomorrow at 10:00 AM';
                            _selectedType = NotificationType.appointment;
                            setState(() {});
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.medication_outlined,
                            color: Colors.red,
                          ),
                          title: Text('medicationReminder'.tr()),
                          onTap: () {
                            _titleController.text = 'Time to Take Medicine';
                            _bodyController.text =
                                'Don\'t forget to take your prescribed medication';
                            _selectedType = NotificationType.reminder;
                            setState(() {});
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.assessment,
                            color: Colors.orange,
                          ),
                          title: Text('testResultsReady'.tr()),
                          onTap: () {
                            _titleController.text = 'Test Results Available';
                            _bodyController.text =
                                'Your recent test results are now ready to view';
                            _selectedType = NotificationType.report;
                            setState(() {});
                          },
                        ),
                        ListTile(
                          leading: const Icon(
                            Icons.message,
                            color: Colors.indigo,
                          ),
                          title: Text('newMessage'.tr()),
                          onTap: () {
                            _titleController.text = 'New Message from Doctor';
                            _bodyController.text =
                                'Dr. Smith has sent you a message';
                            _selectedType = NotificationType.message;
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Send Buttons
                    ElevatedButton.icon(
                      onPressed: _sendNotification,
                      icon: const Icon(Icons.send),
                      label: Text('sendToUser'.tr()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _sendToAllUsers,
                      icon: const Icon(Icons.group_outlined),
                      label: Text('sendToAllUsers'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
