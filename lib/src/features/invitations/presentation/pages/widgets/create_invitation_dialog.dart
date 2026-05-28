import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_event.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
import 'package:dr_copilot/src/core/helper/safe_click.dart';


class CreateInvitationDialog extends StatefulWidget {
  final String clinicId;
  final String currentUserId;

  const CreateInvitationDialog({
    super.key,
    required this.clinicId,
    required this.currentUserId,
  });

  @override
  State<CreateInvitationDialog> createState() => _CreateInvitationDialogState();
}

class _CreateInvitationDialogState extends State<CreateInvitationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final List<String> _selectedRoles = [];
  final List<String> _selectedPermissions = [];

  final List<String> _availableRoles = [
    'doctor',
    'nurse',
    'receptionist',
    'admin',
  ];

  final Map<String, List<String>> _rolePermissions = {
    'doctor': [
      'view_patients',
      'edit_patients',
      'view_appointments',
      'edit_appointments',
      'view_medical_records',
      'edit_medical_records',
    ],
    'nurse': ['view_patients', 'view_appointments', 'view_medical_records'],
    'receptionist': [
      'view_patients',
      'edit_patients',
      'view_appointments',
      'edit_appointments',
    ],
    'admin': [
      'view_patients',
      'edit_patients',
      'view_appointments',
      'edit_appointments',
      'view_medical_records',
      'edit_medical_records',
      'manage_users',
      'manage_settings',
    ],
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('sendInvitation'.tr()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'email'.tr(),
                  hintText: 'Enter email address',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'role'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableRoles.map((role) {
                  return FilterChip(
                    label: Text(role),
                    selected: _selectedRoles.contains(role),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedRoles.add(role);
                          _updatePermissions();
                        } else {
                          _selectedRoles.remove(role);
                          _updatePermissions();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selectedPermissions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Permissions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _selectedPermissions.map((permission) {
                    return Chip(
                      label: Text(permission.replaceAll('_', ' ')),
                      backgroundColor: Colors.blue.shade100,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(onPressed: _sendInvitation.throttle(), child: Text('send'.tr())),
      ],
    );
  }

  void _updatePermissions() {
    _selectedPermissions.clear();
    for (final role in _selectedRoles) {
      final permissions = _rolePermissions[role] ?? [];
      for (final permission in permissions) {
        if (!_selectedPermissions.contains(permission)) {
          _selectedPermissions.add(permission);
        }
      }
    }
  }

  void _sendInvitation() {
    if (_formKey.currentState!.validate()) {
      if (_selectedRoles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('select_at_least_one_role'.tr()))),
        );
        return;
      }

      // Fetch clinic name from OwnerNotifier
      final ownerNotifier = context.read<OwnerNotifier>();
      final clinic = ownerNotifier.clinics.firstWhere(
        (c) => c.id == widget.clinicId,
        orElse: () => ClinicModel(
          id: widget.clinicId,
          name: 'Your Clinic', // Fallback
          location: '',
          ownerId: '',
          createdAt: Timestamp.fromDate(DateTime.now()),
          adminEmail: '',
        ),
      );

      // Generate a new document ID
      final newId =
          FirebaseFirestore.instance.collection('user_invitations').doc().id;

      final invitation = InvitationModel(
        id: newId,
        email: _emailController.text.trim(),
        clinicId: widget.clinicId,
        clinicName: clinic.name,
        invitedBy: widget.currentUserId,
        roles: _selectedRoles,
        permissions: _selectedPermissions,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      context.read<InvitationBloc>().add(CreateInvitation(invitation));
      Navigator.pop(context);
    }
  }
}
