import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';

import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_event.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_defaults.dart';
import 'package:dr_copilot/src/features/staff/domain/usecases/staff_usecase.dart';
import 'package:dr_copilot/src/core/services/backend_service.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'dart:developer';

// Person model to combine staff and doctors for selection
class PersonOption {
  final String name;
  final String email;
  final String role;

  PersonOption({required this.name, required this.email, required this.role});
}

class CreateInvitationPage extends StatefulWidget {
  final String clinicId;
  final String currentUserId;

  const CreateInvitationPage({
    super.key,
    required this.clinicId,
    required this.currentUserId,
  });

  @override
  State<CreateInvitationPage> createState() => _CreateInvitationPageState();
}

class _CreateInvitationPageState extends State<CreateInvitationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  AppRole? _selectedRole; // Changed from Set to single AppRole
  final Set<AppPermission> _selectedPermissions = {};

  List<PersonOption> _availablePeople = [];
  bool _isLoadingPeople = true;
  bool _useManualEntry = false;
  PersonOption? _selectedPerson;

  int _currentStep = 0;
  String? _clinicName;
  bool _canInvite = true;
  bool _checkingSubscription = true;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    _loadInitialData();
  }

  Future<void> _checkSubscriptionStatus() async {
    final subscriptionService = sl<SubscriptionService>();
    final canInvite = await subscriptionService.isFeatureAllowed(
      widget.clinicId,
      SubscriptionFeature.inviteMembers,
    );
    if (mounted) {
      setState(() {
        _canInvite = canInvite;
        _checkingSubscription = false;
      });
    }
  }

  Future<void> _loadInitialData() async {
    // Fetch both staff/doctors and clinic name concurrently
    await Future.wait([_loadStaffAndDoctors(), _fetchClinicName()]);
  }

  Future<void> _loadStaffAndDoctors() async {
    setState(() => _isLoadingPeople = true);

    final List<PersonOption> people = [];

    final staffResult = await sl<StaffUseCases>().getAllStaff(
      clinicId: widget.clinicId,
    );
    staffResult.fold((failure) => log('Error loading staff: $failure'), (
      staffList,
    ) {
      for (var staff in staffList) {
        final staffEmail = staff.email;
        if (staffEmail.isNotEmpty) {
          people.add(
            PersonOption(name: staff.name, email: staffEmail, role: staff.role),
          );
        }
      }
    });

    final doctorsResult = await sl<DoctorsUseCase>().getDoctors(
      clinicId: widget.clinicId,
    );
    doctorsResult.fold((failure) => log('Error loading doctors: $failure'), (
      doctorList,
    ) {
      for (var doctor in doctorList) {
        if (doctor.email.isNotEmpty) {
          people.add(
            PersonOption(
              name: doctor.name,
              email: doctor.email,
              role: 'Doctor',
            ),
          );
        }
      }
    });

    setState(() {
      _availablePeople = people;
      _isLoadingPeople = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchClinicName() async {
    try {
      final clinicDoc = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .get();
      if (clinicDoc.exists && mounted) {
        setState(() {
          _clinicName = clinicDoc.data()?['name'] as String?;
        });
      }
    } catch (e) {
      log('Error fetching clinic name: $e');
      // Handle error, maybe set a default name
      if (mounted) {
        setState(() {
          _clinicName = 'Your Clinic';
        });
      }
    }
  }

  void _sendInvitation() {
    final String email = _useManualEntry
        ? _emailController.text.trim()
        : _selectedPerson?.email ?? '';
    final String name = _useManualEntry ? '' : _selectedPerson?.name ?? '';

    final invitation = InvitationModel(
      id: FirebaseFirestore.instance.collection('invitations').doc().id,
      email: email,
      clinicId: widget.clinicId,
      invitedBy: widget.currentUserId,
      roles: _selectedRole != null ? [_selectedRole!.name] : [],
      permissions: _selectedPermissions.map((p) => p.name).toList(),
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Dispatch event to save to Firestore
    context.read<InvitationBloc>().add(CreateInvitation(invitation));

    // After saving, trigger the email without waiting
    BackendService.sendInvitation(
      recipientEmail: email,
      recipientName: name,
      clinicName: _clinicName ?? 'Your Clinic', // Use fetched clinic name
      clinicId: widget.clinicId,
      role: _selectedRole != null
          ? _getRoleDisplayName(_selectedRole!)
          : 'Member',
    ).then((result) {
      if (result['success'] == true) {
        log('Backend confirmed email sent for $email.');
      } else {
        log(
          'Backend failed to send email for $email. Error: ${result['error']}',
        );
      }
    });

    // Pop the screen immediately for a good UX
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSubscription) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_canInvite) {
      return Scaffold(
        appBar: AppBar(title: Text('createInvitation'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Premium Feature',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Team management is available on Professional and Elite plans.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/settings/subscription'),
                  icon: const Icon(Icons.verified_outlined),
                  label: Text('View Plans'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text('cancel'.tr()),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('createInvitation'.tr())),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () {
            final isLastStep = _currentStep == getSteps().length - 1;
            if (_formKey.currentState!.validate()) {
              if (_currentStep == 1 && _selectedRole == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('pleaseSelectRoleToProceed'.tr())),
                );
                return;
              }

              if (isLastStep) {
                _sendInvitation();
              } else {
                setState(() => _currentStep += 1);
              }
            }
          },
          onStepCancel: _currentStep == 0
              ? null
              : () => setState(() => _currentStep -= 1),
          steps: getSteps(),
          controlsBuilder: (context, details) {
            final isLastStep = _currentStep == getSteps().length - 1;
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  if (_currentStep != 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: Text('back'.tr()),
                      ),
                    ),
                  if (_currentStep != 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: details.onStepContinue,
                      child: Text(
                        isLastStep ? 'sendInvitation'.tr() : 'next'.tr(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Step> getSteps() => [
        Step(
          title: Text('recipient'.tr()),
          content: _buildEmailSelectionSection(),
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: Text('assignRole'.tr()),
          content: _buildRolesSection(),
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        ),
        Step(
          title: Text('review'.tr()),
          content: _buildReviewSection(),
          isActive: _currentStep >= 2,
        ),
      ];

  Widget _buildReviewSection() {
    final String email = _useManualEntry
        ? _emailController.text.trim()
        : _selectedPerson?.email ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReviewTile(
          icon: Icons.email_outlined,
          title: 'recipientEmail'.tr(),
          subtitle: email,
        ),
        const Divider(height: 24),
        _buildReviewTile(
          icon: Icons.shield_outlined,
          title: 'assignedRole'.tr(),
          subtitle: _selectedRole == null
              ? 'noRoleSelected'.tr()
              : _getRoleDisplayName(_selectedRole!),
        ),
        const Divider(height: 24),
        _buildReviewTile(
          icon: Icons.vpn_key_outlined,
          title: 'grantedPermissions'.tr(),
          subtitle: '',
        ),
        const SizedBox(height: 16),
        if (_selectedPermissions.isEmpty)
          Text('noPermissionsGranted'.tr())
        else
          Column(
            children: _selectedPermissions.map((permission) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20.0,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getPermissionDisplayName(permission),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            _getPermissionDescription(permission),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildReviewTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              if (subtitle.isNotEmpty)
                Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmailSelectionSection() {
    if (_isLoadingPeople) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_availablePeople.isEmpty && !_useManualEntry) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.secondaryContainer.withAlpha((255 * 0.3).round()),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'noStaffOrDoctors'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('addStaffPrompt'.tr()),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => context.push('/staff'),
                  child: Text('manageStaff'.tr()),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => setState(() => _useManualEntry = true),
                  child: Text('enterManually'.tr()),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (_useManualEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'emailAddress'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              if (_availablePeople.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _useManualEntry = false;
                    _emailController.clear();
                  }),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text('selectFromList'.tr()),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'Enter email address',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty || !value.contains('@')) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'chooseStaffOrDoctor'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => setState(() => _useManualEntry = true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('enterManually'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PersonOption>(
          isExpanded: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'chooseFromStaffOrDoctors'.tr(),
            prefixIcon: const Icon(Icons.person_outline),
          ),
          initialValue: _selectedPerson,
          selectedItemBuilder: (BuildContext context) {
            return _availablePeople.map<Widget>((PersonOption person) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${person.name} (${person.email})',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: _availablePeople.map((person) {
            return DropdownMenuItem<PersonOption>(
              value: person,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  person.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${person.email} • ${person.role}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }).toList(),
          onChanged: (PersonOption? value) {
            setState(() => _selectedPerson = value);
          },
          validator: (value) {
            if (!_useManualEntry && value == null) {
              return 'Please select a person';
            }
            return null;
          },
        ),
      ],
    );
  }

  void _updatePermissionsBasedOnRoles() {
    _selectedPermissions.clear();
    if (_selectedRole != null) {
      _selectedPermissions.addAll(
        RoleDefaults.getPermissionsForRole(_selectedRole!),
      );
    }
  }

  Widget _buildRolesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup<AppRole>(
          groupValue: _selectedRole,
          onChanged: (AppRole? value) {
            setState(() {
              _selectedRole = value;
              _updatePermissionsBasedOnRoles();
            });
          },
          child: Column(
            children: AppRole.values.map((role) {
              return RadioListTile<AppRole>(
                title: Text(_getRoleDisplayName(role)),
                subtitle: Text(
                  'Assign the ${_getRoleDisplayName(role).toLowerCase()} role',
                ),
                value: role,
              );
            }).toList(),
          ),
        ),
        if (_selectedRole == null)
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'pleaseSelectRoleToProceed'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_selectedRole != null) ...[
          const Divider(height: 32),
          ExpansionTile(
            title: Text('customizePermissions'.tr()),
            subtitle: Text('advancedPermissions'.tr()),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: AppPermission.values.map((permission) {
                    final isSelected = _selectedPermissions.contains(
                      permission,
                    );
                    return CheckboxListTile(
                      title: Text(_getPermissionDisplayName(permission)),
                      subtitle: Text(
                        _getPermissionDescription(permission),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedPermissions.add(permission);
                          } else {
                            _selectedPermissions.remove(permission);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getRoleDisplayName(AppRole role) {
    switch (role) {
      case AppRole.admin:
        return 'Admin';
      case AppRole.doctor:
        return 'Doctor';
      case AppRole.staff:
        return 'Staff';
      case AppRole.financial:
        return 'Financial';
      case AppRole.readonly:
        return 'Read Only';
    }
  }

  String _getPermissionDisplayName(AppPermission permission) {
    // Convert 'canViewPatient' to 'View Patient'
    String name = permission.name;
    // Remove 'can' prefix if it exists and is followed by an uppercase letter
    if (name.startsWith('can') &&
        name.length > 3 &&
        name[3] == name[3].toUpperCase()) {
      name = name.substring(3);
    }

    String formattedName = name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)!}')
        .trim();

    List<String> words = formattedName.split(' ');

    // Apply pluralization for specific words
    words = words.map((word) {
      if (word == 'Patient') {
        return 'Patients';
      } else if (word == 'Session') {
        return 'Sessions';
      } else if (word == 'Event') {
        return 'Events';
      }
      return word;
    }).toList();

    return words
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getPermissionDescription(AppPermission permission) {
    switch (permission) {
      // Patient management
      case AppPermission.viewAllPatients:
        return 'Allows viewing patient profiles and their complete medical records.';
      case AppPermission.viewOwnPatients:
        return 'Allows viewing only your own patient profiles.';
      case AppPermission.viewTeamPatients:
        return 'Allows viewing patients assigned to your team.';
      case AppPermission.viewSpecificDoctorPatients:
        return 'Allows viewing patients assigned to a specific doctor.';
      case AppPermission.updatePatient:
        return 'Allows editing patient demographic and contact information.';
      case AppPermission.deletePatient:
        return 'Allows permanently deleting a patient and all their associated data.';
      case AppPermission.createPatient:
        return 'Allows adding new patients to the clinic\'s database.';

      // Session management
      case AppPermission.viewAllSessions:
        return 'Allows viewing details of patient therapy or consultation sessions.';
      case AppPermission.viewOwnSessions:
        return 'Allows viewing only your own sessions.';
      case AppPermission.updateSession:
        return 'Allows modifying details of existing patient sessions.';
      case AppPermission.deleteSession:
        return 'Allows deleting patient sessions from their record.';
      case AppPermission.createSession:
        return 'Allows creating new sessions for patients.';

      // Evaluation management
      case AppPermission.viewAllEvaluations:
        return 'Allows viewing patient assessment and evaluation results.';
      case AppPermission.viewOwnEvaluations:
        return 'Allows viewing only your own evaluations.';
      case AppPermission.updateEvaluation:
        return 'Allows editing patient evaluation data and conclusions.';
      case AppPermission.deleteEvaluation:
        return 'Allows deleting evaluation records.';
      case AppPermission.createEvaluation:
        return 'Allows adding new patient evaluations.';

      // Financials
      case AppPermission.viewFinancials:
        return 'Allows access to billing, invoices, and financial reports.';
      case AppPermission.manageInvoices:
        return 'Allows creating and modifying invoices and payments.';
      case AppPermission.addFinancialEntry:
        return 'Allows adding new financial records (invoices, bills, transactions).';
      case AppPermission.editFinancialEntry:
        return 'Allows editing existing financial records.';
      case AppPermission.deleteFinancialEntry:
        return 'Allows deleting financial records.';

      // Copilot chat
      case AppPermission.useCopilot:
        return 'Allows access to the AI-powered Dr. Copilot chat features.';

      // Calendar
      case AppPermission.viewCalendar:
        return 'Allows viewing the clinic and personal appointment calendar.';
      case AppPermission.editCalendarEvent:
        return 'Allows modifying existing appointments on the calendar.';
      case AppPermission.addCalendarEvent:
        return 'Allows adding new appointments or events to the calendar.';
      case AppPermission.deleteCalendarEvent:
        return 'Allows removing events from the calendar.';

      // Notifications
      case AppPermission.viewNotifications:
        return 'Allows viewing system notifications and alerts.';
      case AppPermission.manageNotifications:
        return 'Allows sending or configuring system-wide notifications.';

      // Settings
      case AppPermission.viewSettings:
        return 'Allows viewing clinic and application settings.';
      case AppPermission.editSettings:
        return 'Allows changing clinic settings and configurations.';
      case AppPermission.manageSettings:
        return 'Allows managing all settings.';

      // Medical Files
      case AppPermission.viewMedicalFiles:
        return 'Allows viewing medical files.';
      case AppPermission.addMedicalFile:
        return 'Allows uploading or adding new medical files.';
      case AppPermission.editMedicalFile:
        return 'Allows editing medical file details.';
      case AppPermission.deleteMedicalFile:
        return 'Allows deleting medical files.';

      // Medications
      case AppPermission.viewMedications:
        return 'Allows viewing patient medications.';
      case AppPermission.addMedication:
        return 'Allows prescribing or adding medications.';
      case AppPermission.editMedication:
        return 'Allows editing medication details.';
      case AppPermission.deleteMedication:
        return 'Allows removing medications.';

      // Recycle Bin
      case AppPermission.viewRecycleBin:
        return 'Allows accessing the recycle bin.';
      case AppPermission.restoreRecycleBinItem:
        return 'Allows restoring deleted items.';
      case AppPermission.permanentDeleteRecycleBinItem:
        return 'Allows permanently deleting items.';

      // Admin
      case AppPermission.manageStaff:
        return 'Allows managing staff members.';
      case AppPermission.manageUsers:
        return 'Allows inviting, editing roles of, and removing users from the clinic.';
      case AppPermission.assignRoles:
        return 'Allows changing the roles assigned to users.';
      case AppPermission.assignPermissions:
        return 'Allows assigning or revoking specific permissions for roles.';

      // Reports/Charts
      case AppPermission.viewReports:
        return 'Allows generating and viewing detailed clinic reports.';
      case AppPermission.viewCharts:
        return 'Allows viewing data visualizations and performance charts.';

      // Clinical Reports
      case AppPermission.viewClinicalReports:
        return 'Allows viewing clinical reports.';
      case AppPermission.addClinicalReport:
        return 'Allows creating new clinical reports.';
      case AppPermission.editClinicalReport:
        return 'Allows editing existing clinical reports.';
      case AppPermission.deleteClinicalReport:
        return 'Allows deleting clinical reports.';

      // Doctors
      case AppPermission.viewDoctors:
        return 'Allows viewing the doctors directory.';
      case AppPermission.manageDoctors:
        return 'Allows adding, collecting, or removing doctors.';

      // Invitations
      case AppPermission.viewInvitations:
        return 'Allows viewing pending and sent invitations.';
      case AppPermission.sendInvitation:
        return 'Allows sending new invitations to staff or doctors.';
      case AppPermission.revokeInvitation:
        return 'Allows revoking or deleting invitations.';

      // Subscription
      case AppPermission.viewSubscription:
        return 'Allows viewing billing and subscription details.';
      case AppPermission.manageSubscription:
        return 'Allows upgrading or changing the subscription plan.';

      // Help/Support
      case AppPermission.viewHelp:
        return 'Allows access to the help and documentation section.';
      case AppPermission.accessSupport:
        return 'accessSupport'.tr();
      case AppPermission.sendNotificationMessage:
        return 'sendNotificationMessage'.tr();
      case AppPermission.sendNotificationAppointment:
        return 'sendNotificationAppointment'.tr();
      case AppPermission.sendNotificationReminder:
        return 'sendNotificationReminder'.tr();
      case AppPermission.manageTeams:
        return 'manageTeams'.tr();
      case AppPermission.createTeam:
        return 'Allows creating new teams for clinic collaboration.';
      case AppPermission.archiveTeam:
        return 'Allows archiving teams to remove them from active view.';
      case AppPermission.unarchiveTeam:
        return 'Allows restoring archived teams.';
    }
  }
}
