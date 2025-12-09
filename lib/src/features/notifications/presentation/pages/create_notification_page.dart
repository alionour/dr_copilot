import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';

class CreateNotificationPage extends StatefulWidget {
  const CreateNotificationPage({super.key});

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _actionUrlController = TextEditingController();

  NotificationType _selectedType = NotificationType.system;
  NotificationSenderType _selectedSenderType =
      NotificationSenderType.programmer;
  NotificationTargetType _selectedTargetType =
      NotificationTargetType.allClinicOwners;

  final Set<AppRole> _selectedRoles = {};
  String? _ownerId;
  final List<String> _selectedClinicIds = [];

  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _actionUrlController.dispose();
    super.dispose();
  }

  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final template = NotificationTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      message: _messageController.text,
      type: _selectedType,
      sender: NotificationSender(
        type: _selectedSenderType,
        senderId: 'debug_sender',
        senderName: 'Debug Mode',
      ),
      target: NotificationTarget(
        type: _selectedTargetType,
        targetRoles: _selectedTargetType == NotificationTargetType.specificRoles
            ? _selectedRoles.toList()
            : null,
        ownerId: _selectedTargetType == NotificationTargetType.ownerClinics
            ? _ownerId
            : null,
        clinicIds: _selectedTargetType == NotificationTargetType.specificClinic
            ? _selectedClinicIds
            : null,
      ),
      actionUrl: _actionUrlController.text.isEmpty
          ? null
          : _actionUrlController.text,
    );

    context.read<NotificationsBloc>().add(SendBulkNotificationEvent(template));

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('createNotificationDebugTitle'.tr()),
        backgroundColor: Colors.orange,
      ),
      body: BlocListener<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationSentSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'notificationSentToUsers'.tr(args: [state.count.toString()]),
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
          } else if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'debugModeInfo'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'titleLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'pleaseEnterTitle'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    labelText: 'messageLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'pleaseEnterMessage'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<NotificationType>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'notificationTypeLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: NotificationType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<NotificationSenderType>(
                  value: _selectedSenderType,
                  decoration: InputDecoration(
                    labelText: 'senderTypeLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: NotificationSenderType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSenderType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<NotificationTargetType>(
                  value: _selectedTargetType,
                  decoration: InputDecoration(
                    labelText: 'targetAudienceLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: NotificationTargetType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTargetTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTargetType = value!;
                      _selectedRoles.clear();
                      _ownerId = null;
                      _selectedClinicIds.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedTargetType == NotificationTargetType.specificRoles)
                  _buildRoleSelector(),
                if (_selectedTargetType == NotificationTargetType.ownerClinics)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'ownerIdLabel'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _ownerId = value;
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'pleaseEnterOwnerId'.tr();
                      }
                      return null;
                    },
                  ),
                if (_selectedTargetType ==
                    NotificationTargetType.specificClinic)
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'clinicIdsLabel'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _selectedClinicIds.clear();
                      _selectedClinicIds.addAll(
                        value
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty),
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'pleaseEnterClinicIds'.tr();
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _actionUrlController,
                  decoration: InputDecoration(
                    labelText: 'actionUrlLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendNotification,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                        )
                      : Text(
                          'sendNotificationButton'.tr(),
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

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectTargetRoles'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AppRole.values.map((role) {
            return FilterChip(
              label: Text(role.name),
              selected: _selectedRoles.contains(role),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedRoles.add(role);
                  } else {
                    _selectedRoles.remove(role);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  String _getTargetTypeName(NotificationTargetType type) {
    switch (type) {
      case NotificationTargetType.allUsers:
        return 'allUsers'.tr();
      case NotificationTargetType.allClinicOwners:
        return 'allClinicOwners'.tr();
      case NotificationTargetType.allDoctors:
        return 'allDoctors'.tr();
      case NotificationTargetType.allStaff:
        return 'allStaff'.tr();
      case NotificationTargetType.specificRoles:
        return 'specificRoles'.tr();
      case NotificationTargetType.ownerClinics:
        return 'ownerClinics'.tr();
      case NotificationTargetType.specificClinic:
        return 'specificClinic'.tr();
    }
  }
}
