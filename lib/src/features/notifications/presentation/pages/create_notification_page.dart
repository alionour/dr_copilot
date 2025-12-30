import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_state.dart';

import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:dr_copilot/src/features/auth/domain/models/user_model.dart';
import 'package:dr_copilot/src/features/teams/domain/models/custom_team_model.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

class CreateNotificationPage extends StatefulWidget {
  const CreateNotificationPage({super.key});

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  final _formKey = GlobalKey<FormState>();
  // Title controller removed (Auto-generated)
  final _messageController = TextEditingController();
  final _customActionUrlController =
      TextEditingController(); // Only for 'Custom'

  List<NotificationType> _allowedTypes = [];
  List<NotificationTargetType> _allowedTargetTypes = [];
  NotificationType? _selectedType;
  NotificationTargetType _selectedTargetType =
      NotificationTargetType.allClinicOwners;

  // Smart Actions
  String _selectedAction = 'open_app'; // Default key
  final Map<String, String> _actionOptions = {
    'open_app': '/home', // Changed from / to /home for clarity
    'appointments': '/sessions', // Mapped to Sessions page
    'reports': '/clinical_reports', // Valid route
    'profile': '/account', // Valid route
    'custom': 'custom',
  };

  final Set<AppRole> _selectedRoles = {};

  final List<String> _selectedClinicIds = [];
  String? _selectedTeamId;
  List<CustomTeamModel> _availableTeams = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculateAllowedTypes();
  }

  void _calculateAllowedTypes() {
    // Access OwnerNotifier to get current real-time permissions
    final ownerNotifier = context.read<OwnerNotifier>();
    final role = ownerNotifier.role;

    final allowed = <NotificationType>[];
    final allowedTargets = <NotificationTargetType>[];

    // 1. Determine Allowed Types based on Permissions
    if (ownerNotifier.hasPermission(AppPermission.sendNotificationMessage)) {
      allowed.add(NotificationType.message);
    }
    if (ownerNotifier
        .hasPermission(AppPermission.sendNotificationAppointment)) {
      allowed.add(NotificationType.appointment);
    }
    if (ownerNotifier.hasPermission(AppPermission.sendNotificationReminder)) {
      allowed.add(NotificationType.reminder);
    }

    // Admin/Manager Types
    if (role == AppRole.admin ||
        ownerNotifier.hasPermission(AppPermission.manageNotifications)) {
      allowed.add(NotificationType.system);
      allowed.add(NotificationType.alert);
      allowed.add(NotificationType.report);
      allowed.add(NotificationType.payment);
    }

    // 2. Determine Allowed Targets
    if (role == AppRole.admin ||
        ownerNotifier.hasPermission(AppPermission.manageNotifications)) {
      // Admins can target everyone
      allowedTargets.addAll([
        NotificationTargetType.ownerClinics,
        NotificationTargetType.specificClinic,
        NotificationTargetType.specificRoles,
        NotificationTargetType.customTeam,
      ]);
    } else {
      // Regular Users: STRICTLY Team Only
      if (allowed.isNotEmpty) {
        allowedTargets.add(NotificationTargetType.customTeam);
      }
    }

    setState(() {
      _allowedTypes = allowed;
      _allowedTargetTypes = allowedTargets;
      if (allowed.isNotEmpty) {
        _selectedType = allowed.first;
      }
      // Reset selected target if not in allowed list
      if (_allowedTargetTypes.isNotEmpty &&
          !_allowedTargetTypes.contains(_selectedTargetType)) {
        _selectedTargetType = _allowedTargetTypes.first;
      }
    });

    // Load teams if customTeam is allowed
    if (allowedTargets.contains(NotificationTargetType.customTeam)) {
      final user = context.read<AuthBloc>().state is AuthSignedIn
          ? (context.read<AuthBloc>().state as AuthSignedIn).user
          : null;

      if (user?.primaryClinicId != null) {
        final teamsRepo = sl<AbstractCustomTeamsRepository>();
        // Using 'then' to handle future result since we are in a void function
        teamsRepo.getTeamsForClinic(user!.primaryClinicId!).then((result) {
          result.fold((failure) => {}, (teams) {
            if (mounted) {
              setState(() {
                _availableTeams = teams;
                // If regular user has no teams, they might have an empty target list effectively
                // But we keep the logic clean here.
              });
            }
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _customActionUrlController.dispose();
    super.dispose();
  }

  void _sendNotification() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Auto-generate Title
    String title = '';
    switch (_selectedType!) {
      case NotificationType.message:
        title = 'newMessage'.tr();
        break;
      case NotificationType.appointment:
        title = 'appointmentUpdate'.tr();
        break;
      case NotificationType.reminder:
        title = 'reminder'.tr();
        break;
      case NotificationType.system:
        title = 'systemAlert'.tr();
        break;
      case NotificationType.alert:
        title = 'alert'.tr();
        break;
      case NotificationType.report:
        title = 'newReport'.tr();
        break;
      case NotificationType.payment:
        title = 'paymentUpdate'.tr();
        break;
    }

    // Resolve Action URL
    String? actionUrl;
    if (_selectedAction == 'custom') {
      actionUrl = _customActionUrlController.text.isNotEmpty
          ? _customActionUrlController.text
          : null;
    } else {
      actionUrl = _actionOptions[_selectedAction];
    }

    final template = NotificationTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title, // Use auto-generated title
      message: _messageController.text,
      type: _selectedType!,
      sender: NotificationSender(
        type: NotificationSenderType.clinicOwner,
        senderId: context.read<AuthBloc>().state is AuthSignedIn
            ? (context.read<AuthBloc>().state as AuthSignedIn).user?.uid ??
                'unknown_sender'
            : 'unknown_sender',
        senderName: context.read<AuthBloc>().state is AuthSignedIn
            ? (context.read<AuthBloc>().state as AuthSignedIn)
                    .user
                    ?.displayName ??
                'Clinic Staff'
            : 'Clinic Staff',
      ),
      target: NotificationTarget(
        type: _selectedTargetType,
        targetRoles: _selectedTargetType == NotificationTargetType.specificRoles
            ? _selectedRoles.toList()
            : null,
        ownerId: _selectedTargetType == NotificationTargetType.ownerClinics
            // Auto-use current user ID as owner ID for simplicity and security
            ? (context.read<AuthBloc>().state is AuthSignedIn
                ? (context.read<AuthBloc>().state as AuthSignedIn).user?.uid
                : null)
            : null,
        clinicIds: _selectedTargetType == NotificationTargetType.specificClinic
            ? _selectedClinicIds
            : null,
        teamId: _selectedTargetType == NotificationTargetType.customTeam
            ? _selectedTeamId
            : null,
      ),
      actionUrl: actionUrl,
    );

    context.read<NotificationsBloc>().add(SendBulkNotificationEvent(template));
    // Don't set _isLoading to false here - let the BLoC listener handle it
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('createNotificationTitle'.tr()),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: BlocListener<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationSentSuccess) {
            setState(() {
              _isLoading = false;
            });
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
            setState(() {
              _isLoading = false;
            });
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
                const SizedBox(height: 24),
                // Title Field Removed
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
                // ... Notification Type Dropdown ...
                const SizedBox(height: 16),
                if (_allowedTypes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.shade50,
                    child: Text(
                      'noNotificationPermissions'.tr(),
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  )
                else
                  DropdownButtonFormField<NotificationType>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'notificationTypeLabel'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    items: _allowedTypes.map((type) {
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

                // Target Audience
                DropdownButtonFormField<NotificationTargetType>(
                  initialValue: _selectedTargetType,
                  decoration: InputDecoration(
                    labelText: 'targetAudienceLabel'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  items: _allowedTargetTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTargetTypeName(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTargetType = value!;
                      _selectedRoles.clear();
                      _selectedClinicIds.clear();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Custom Selectors
                if (_selectedTargetType == NotificationTargetType.specificRoles)
                  _buildRoleSelector(),

                if (_selectedTargetType ==
                    NotificationTargetType.specificClinic)
                  if (context.read<AuthBloc>().state is AuthSignedIn &&
                      (context.read<AuthBloc>().state as AuthSignedIn).user !=
                          null)
                    _buildClinicSelector(
                      (context.read<AuthBloc>().state as AuthSignedIn).user!,
                    ),
                if (_selectedTargetType == NotificationTargetType.customTeam)
                  _buildTeamSelector(),

                const SizedBox(height: 16),

                // Action URL Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedAction,
                  decoration: const InputDecoration(
                    labelText: 'Action / Route',
                    border: OutlineInputBorder(),
                  ),
                  items: _actionOptions.entries
                      .where((entry) => entry.key != 'custom') // Hide custom
                      .map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.key.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedAction = value!);
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading || _allowedTypes.isEmpty
                      ? null
                      : _sendNotification,
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

  Widget _buildClinicSelector(UserModel user) {
    if (user.clinics == null || user.clinics!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          'noClinicsFound'.tr(),
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectTargetClinics'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: user.clinics!.map((clinic) {
            final clinicId = clinic['clinicId'] as String;
            final role = clinic['role'] as String;
            final label = 'Clinic: $clinicId ($role)';

            return FilterChip(
              label: Text(label),
              selected: _selectedClinicIds.contains(clinicId),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedClinicIds.add(clinicId);
                  } else {
                    _selectedClinicIds.remove(clinicId);
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
      case NotificationTargetType.customTeam:
        return 'customTeam'.tr();
    }
  }

  Widget _buildTeamSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'selectTeam'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_availableTeams.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'noTeamsAvailable'.tr(),
              style: const TextStyle(color: Colors.orange),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _selectedTeamId,
            decoration: InputDecoration(
              labelText: 'team'.tr(),
              border: const OutlineInputBorder(),
            ),
            items: _availableTeams.map((team) {
              return DropdownMenuItem(value: team.id, child: Text(team.name));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTeamId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'pleaseSelectTeam'.tr();
              }
              return null;
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
