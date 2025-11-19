import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/send_notification/send_notification_bloc.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSendNotificationPage extends StatefulWidget {
  const AdminSendNotificationPage({super.key});

  @override
  State<AdminSendNotificationPage> createState() => _AdminSendNotificationPageState();
}

class _AdminSendNotificationPageState extends State<AdminSendNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  NotificationType _selectedType = NotificationType.system;
  NotificationTargetType _selectedTarget = NotificationTargetType.ownerClinics;
  final List<AppRole> _selectedRoles = [];
  final List<String> _selectedClinicIds = [];
  List<ClinicModel> _userClinics = [];
  UserModel? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserClinics();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUserClinics() async {
    setState(() => _isLoading = true);
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromJson({...userDoc.data()!, 'uid': userDoc.id});
        
        final clinicsSnapshot = await FirebaseFirestore.instance
            .collection('clinics')
            .where('ownerId', isEqualTo: _currentUser!.uid)
            .get();
        
        setState(() {
          _userClinics = clinicsSnapshot.docs
              .map((doc) => ClinicModel.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading clinics: $e')),
        );
      }
    }
  }

  void _sendNotification() {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    if (_selectedTarget == NotificationTargetType.specificRoles && _selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_at_least_one_role'.tr())),
      );
      return;
    }

    if (_selectedTarget == NotificationTargetType.specificClinic && _selectedClinicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('select_at_least_one_clinic'.tr())),
      );
      return;
    }

    final template = NotificationTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      type: _selectedType,
      sender: NotificationSender(
        type: NotificationSenderType.clinicOwner,
        senderId: _currentUser!.uid,
        senderName: _currentUser!.displayName ?? _currentUser!.email,
      ),
      target: NotificationTarget(
        type: _selectedTarget,
        targetRoles: _selectedTarget == NotificationTargetType.specificRoles ? _selectedRoles : null,
        ownerId: _selectedTarget == NotificationTargetType.ownerClinics || 
                 _selectedTarget == NotificationTargetType.specificClinic 
                 ? _currentUser!.uid : null,
        clinicIds: _selectedTarget == NotificationTargetType.specificClinic ? _selectedClinicIds : null,
      ),
    );

    context.read<SendNotificationBloc>().add(SendNotificationEvent(template));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('send_notification'.tr()),
      ),
      body: BlocListener<SendNotificationBloc, SendNotificationState>(
        listener: (context, state) {
          if (state is SendNotificationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('notification_sent_to_users'.tr()
                    .replaceAll('{count}', state.recipientCount.toString())),
                backgroundColor: Colors.green,
              ),
            );
            _titleController.clear();
            _messageController.clear();
            setState(() {
              _selectedRoles.clear();
              _selectedClinicIds.clear();
            });
          } else if (state is SendNotificationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'error'.tr()}: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildTitleField(),
                      const SizedBox(height: 16),
                      _buildMessageField(),
                      const SizedBox(height: 16),
                      _buildTypeDropdown(),
                      const SizedBox(height: 16),
                      _buildTargetDropdown(),
                      const SizedBox(height: 16),
                      if (_selectedTarget == NotificationTargetType.specificRoles)
                        _buildRolesSelection(),
                      if (_selectedTarget == NotificationTargetType.specificClinic)
                        _buildClinicsSelection(),
                      const SizedBox(height: 24),
                      _buildSendButton(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'notification_info'.tr(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'notification_info_message'.tr(),
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'title'.tr(),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'title_required'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildMessageField() {
    return TextFormField(
      controller: _messageController,
      decoration: InputDecoration(
        labelText: 'message'.tr(),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.message),
        alignLabelWithHint: true,
      ),
      maxLines: 5,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'message_required'.tr();
        }
        return null;
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<NotificationType>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'notification_type'.tr(),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.category),
      ),
      items: NotificationType.values.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(_getTypeLabel(type)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedType = value);
        }
      },
    );
  }

  Widget _buildTargetDropdown() {
    return DropdownButtonFormField<NotificationTargetType>(
      value: _selectedTarget,
      decoration: InputDecoration(
        labelText: 'target_audience'.tr(),
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.people),
      ),
      items: [
        NotificationTargetType.ownerClinics,
        NotificationTargetType.specificClinic,
        NotificationTargetType.specificRoles,
      ].map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(_getTargetLabel(type)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTarget = value;
            _selectedRoles.clear();
            _selectedClinicIds.clear();
          });
        }
      },
    );
  }

  Widget _buildRolesSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_roles'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...AppRole.values.map((role) {
              return CheckboxListTile(
                title: Text(_getRoleLabel(role)),
                value: _selectedRoles.contains(role),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedRoles.add(role);
                    } else {
                      _selectedRoles.remove(role);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildClinicsSelection() {
    if (_userClinics.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('no_clinics_found'.tr()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_clinics'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ..._userClinics.map((clinic) {
              return CheckboxListTile(
                title: Text(clinic.name),
                subtitle: clinic.location != null ? Text(clinic.location!) : null,
                value: _selectedClinicIds.contains(clinic.id),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedClinicIds.add(clinic.id);
                    } else {
                      _selectedClinicIds.remove(clinic.id);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return BlocBuilder<SendNotificationBloc, SendNotificationState>(
      builder: (context, state) {
        final isLoading = state is SendNotificationLoading;
        return ElevatedButton.icon(
          onPressed: isLoading ? null : _sendNotification,
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(
            isLoading
                ? 'sending'.tr()
                : 'send_notification'.tr(),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        );
      },
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return 'appointment'.tr();
      case NotificationType.message:
        return 'message'.tr();
      case NotificationType.reminder:
        return 'reminder'.tr();
      case NotificationType.system:
        return 'system'.tr();
      case NotificationType.payment:
        return 'payment'.tr();
      case NotificationType.report:
        return 'report'.tr();
      case NotificationType.alert:
        return 'alert'.tr();
    }
  }

  String _getTargetLabel(NotificationTargetType type) {
    switch (type) {
      case NotificationTargetType.ownerClinics:
        return 'all_my_clinic_members'.tr();
      case NotificationTargetType.specificClinic:
        return 'specific_clinic_members'.tr();
      case NotificationTargetType.specificRoles:
        return 'specific_roles'.tr();
      default:
        return type.toString();
    }
  }

  String _getRoleLabel(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 'admin'.tr();
      case AppRole.doctor:
        return 'doctor'.tr();
      case AppRole.staff:
        return 'staff'.tr();
      case AppRole.financial:
        return 'financial'.tr();
      case AppRole.readonly:
        return 'readonly'.tr();
    }
  }
}

