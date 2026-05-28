import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:provider/provider.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/clinic_model.dart';
import 'package:dr_copilot/src/core/helper/safe_click.dart';


import 'package:dr_copilot/src/features/invitations/domain/models/invitation_model.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_bloc.dart';
import 'package:dr_copilot/src/features/invitations/presentation/bloc/invitation_event.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_defaults.dart';
import 'package:dr_copilot/src/features/staff/domain/usecases/staff_usecase.dart';
import 'package:dr_copilot/src/core/services/backend_service.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:dr_copilot/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:dr_copilot/src/features/departments/domain/repositories/abstract_departments_repository.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';
import 'dart:developer';

// Person model to combine staff and doctors for selection
class PersonOption {
  final String id;
  final String name;
  final String email;
  final String role;

  PersonOption({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
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

  final List<String> _selectedDoctorIds = [];
  final List<String> _selectedDepartmentIds = [];
  final List<String> _selectedTeamIds = [];
  bool _isAllDoctors = true;
  bool _isAllDepartments = true;
  bool _isAllTeams = true;

  List<PersonOption> _availablePeople = [];
  List<Map<String, dynamic>> _availableDepartments = [];
  List<Map<String, dynamic>> _availableTeams = [];
  bool _isLoadingPeople = true;
  bool _useManualEntry = false;
  bool _showAllPermissions = false;
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
    await Future.wait([
      _loadStaffAndDoctors(),
      _fetchClinicName(),
      _loadDepartmentsAndTeams(),
    ]);
  }

  Future<void> _loadDepartmentsAndTeams() async {
    try {
      final deptRepo = sl<AbstractDepartmentsRepository>();
      final teamRepo = sl<AbstractCustomTeamsRepository>();

      final deptResult = await deptRepo.getDepartments(widget.clinicId);
      final teamResult = await teamRepo.getTeamsForClinic(widget.clinicId);

      if (mounted) {
        setState(() {
          _availableDepartments = deptResult.fold(
            (f) => [],
            (list) => list.map((d) => {'id': d.id, 'name': d.name}).toList(),
          );
          _availableTeams = teamResult.fold(
            (f) => [],
            (list) => list.map((t) => {'id': t.id, 'name': t.name}).toList(),
          );
        });
      }
    } catch (e) {
      log('Error loading metadata: $e');
    }
  }

  Future<void> _loadStaffAndDoctors() async {
    final Map<String, PersonOption> uniquePeople = {};

    final staffResult = await sl<StaffUseCases>().getAllStaff(
      clinicId: widget.clinicId,
    );
    staffResult.fold((failure) => log('Error loading staff: $failure'), (
      staffList,
    ) {
      for (var staff in staffList) {
        final staffEmail = staff.email;
        if (staffEmail.isNotEmpty) {
          uniquePeople.putIfAbsent(
            staffEmail,
            () => PersonOption(
              id: staff.id,
              name: staff.name,
              email: staffEmail,
              role: staff.role,
            ),
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
          uniquePeople.putIfAbsent(
            doctor.email,
            () => PersonOption(
              id: doctor.id,
              name: doctor.name,
              email: doctor.email,
              role: 'Doctor',
            ),
          );
        }
      }
    });

    setState(() {
      _availablePeople = uniquePeople.values.toList();
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

  Future<void> _sendInvitation() async {
    final String email = _useManualEntry
        ? _emailController.text.trim()
        : _selectedPerson?.email ?? '';
    final String name = _useManualEntry ? '' : _selectedPerson?.name ?? '';

    // Check if user already exists
    final authRepo = sl<AbstractAuthRepository>();
    final failureOrExists = await authRepo.doesUserExist(email);

    bool userExists = false;
    failureOrExists.fold(
      (failure) => log('Error checking user existence: $failure'),
      (exists) => userExists = exists,
    );

    if (userExists) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectionArea(child: Text('userAlreadyRegistered'.tr())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final ownerNotifier = context.read<OwnerNotifier>();
    final clinic = ownerNotifier.clinics.firstWhere(
      (c) => c.id == widget.clinicId,
      orElse: () => ClinicModel(
        id: widget.clinicId,
        name: 'Clinic',
        location: null,
        ownerId: '',
        adminEmail: '',
        createdAt: null,
      ),
    );
    final clinicName = clinic.name;

    final invitation = InvitationModel(
      id: FirebaseFirestore.instance.collection('invitations').doc().id,
      email: email,
      clinicId: widget.clinicId,
      clinicName: clinicName,
      invitedBy: widget.currentUserId,
      roles: _selectedRole != null ? [_selectedRole!.name] : [],
      permissions: _selectedPermissions.map((p) => p.name).toList(),
      linkedDoctorIds: _isAllDoctors ? ['ALL'] : _selectedDoctorIds,
      departmentIds: _isAllDepartments ? ['ALL'] : _selectedDepartmentIds,
      teamIds: _isAllTeams ? ['ALL'] : _selectedTeamIds,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    // Dispatch event to save to Firestore
    if (mounted) {
      context.read<InvitationBloc>().add(CreateInvitation(invitation));
    }

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
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSubscription) {
      return Scaffold(
        appBar: AppBar(title: Text('createInvitation'.tr())),
        body: const ShimmerList(itemCount: 8),
      );
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
          key: ValueKey(getSteps().length),
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepTapped: (step) => setState(() => _currentStep = step),
          onStepContinue: () async {
            final isLastStep = _currentStep == getSteps().length - 1;
            if (_formKey.currentState!.validate()) {
              if (_currentStep == 1 && _selectedRole == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: SelectionArea(child: Text('pleaseSelectRoleToProceed'.tr()))),
                );
                return;
              }

              if (isLastStep) {
                await _sendInvitation();
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
                      onPressed: details.onStepContinue.throttle(),
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

  bool get _needsDoctorScope =>
      _selectedPermissions.contains(AppPermission.viewPatients) ||
      _selectedPermissions.contains(AppPermission.createPatient) ||
      _selectedPermissions.contains(AppPermission.updatePatient) ||
      _selectedPermissions.contains(AppPermission.deletePatient) ||
      _selectedPermissions.contains(AppPermission.viewSessions) ||
      _selectedPermissions.contains(AppPermission.createSession) ||
      _selectedPermissions.contains(AppPermission.updateSession) ||
      _selectedPermissions.contains(AppPermission.deleteSession) ||
      _selectedPermissions.contains(AppPermission.viewEvaluations) ||
      _selectedPermissions.contains(AppPermission.createEvaluation) ||
      _selectedPermissions.contains(AppPermission.updateEvaluation) ||
      _selectedPermissions.contains(AppPermission.deleteEvaluation) ||
      _selectedPermissions.contains(AppPermission.viewClinicalReports) ||
      _selectedPermissions.contains(AppPermission.createClinicalReport) ||
      _selectedPermissions.contains(AppPermission.updateClinicalReport) ||
      _selectedPermissions.contains(AppPermission.deleteClinicalReport);

  bool get _needsDeptScope => _needsDoctorScope;

  bool get _needsTeamScope => _needsDoctorScope;

  List<Step> getSteps() {
    final List<Step> steps = [
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
    ];

    if (_needsDoctorScope) {
      steps.add(
        Step(
          title: Text('doctorAssociation'.tr()),
          content: _buildDoctorAssociationSection(),
          isActive: _currentStep >= steps.length,
          state: _currentStep > steps.length ? StepState.complete : StepState.indexed,
        ),
      );
    }

    if (_needsDeptScope) {
      steps.add(
        Step(
          title: Text('departmentAssociation'.tr()),
          content: _buildDepartmentAssociationSection(),
          isActive: _currentStep >= steps.length,
          state: _currentStep > steps.length ? StepState.complete : StepState.indexed,
        ),
      );
    }

    if (_needsTeamScope) {
      steps.add(
        Step(
          title: Text('teamAssociation'.tr()),
          content: _buildTeamAssociationSection(),
          isActive: _currentStep >= steps.length,
          state: _currentStep > steps.length ? StepState.complete : StepState.indexed,
        ),
      );
    }

    steps.add(
      Step(
        title: Text('review'.tr()),
        content: _buildReviewSection(),
        isActive: _currentStep >= (steps.length),
      ),
    );

    return steps;
  }

  Widget _buildDoctorAssociationSection() {
    final doctors = _availablePeople.where((p) => p.role == 'Doctor').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'doctorScopeDescription'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        RadioListTile<bool>(
          title: Text('allDoctors'.tr()),
          value: true,
          groupValue: _isAllDoctors,
          onChanged: (value) => setState(() => _isAllDoctors = value!),
        ),
        RadioListTile<bool>(
          title: Text('specificDoctors'.tr()),
          value: false,
          groupValue: _isAllDoctors,
          onChanged: (value) => setState(() => _isAllDoctors = value!),
        ),
        if (!_isAllDoctors) ...[
          const SizedBox(height: 16),
          if (doctors.isEmpty)
            Text(
              'noDoctorsInClinic'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else
            Column(
              children: doctors.map((doctor) {
                return CheckboxListTile(
                  title: Text(doctor.name),
                  subtitle: Text(doctor.email),
                  value: _selectedDoctorIds.contains(doctor.id),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedDoctorIds.add(doctor.id);
                      } else {
                        _selectedDoctorIds.remove(doctor.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildDepartmentAssociationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'departmentScopeDescription'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        RadioListTile<bool>(
          title: Text('allDepartments'.tr()),
          value: true,
          groupValue: _isAllDepartments,
          onChanged: (value) => setState(() => _isAllDepartments = value!),
        ),
        RadioListTile<bool>(
          title: Text('specificDepartments'.tr()),
          value: false,
          groupValue: _isAllDepartments,
          onChanged: (value) => setState(() => _isAllDepartments = value!),
        ),
        if (!_isAllDepartments) ...[
          const SizedBox(height: 16),
          if (_availableDepartments.isEmpty)
            Text(
              'noDepartmentsInClinic'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else
            Column(
              children: _availableDepartments.map((dept) {
                return CheckboxListTile(
                  title: Text(dept['name']),
                  value: _selectedDepartmentIds.contains(dept['id']),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedDepartmentIds.add(dept['id']);
                      } else {
                        _selectedDepartmentIds.remove(dept['id']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

  Widget _buildTeamAssociationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'teamScopeDescription'.tr(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        RadioListTile<bool>(
          title: Text('allTeams'.tr()),
          value: true,
          groupValue: _isAllTeams,
          onChanged: (value) => setState(() => _isAllTeams = value!),
        ),
        RadioListTile<bool>(
          title: Text('specificTeams'.tr()),
          value: false,
          groupValue: _isAllTeams,
          onChanged: (value) => setState(() => _isAllTeams = value!),
        ),
        if (!_isAllTeams) ...[
          const SizedBox(height: 16),
          if (_availableTeams.isEmpty)
            Text(
              'noTeamsInClinic'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            )
          else
            Column(
              children: _availableTeams.map((team) {
                return CheckboxListTile(
                  title: Text(team['name']),
                  value: _selectedTeamIds.contains(team['id']),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedTeamIds.add(team['id']);
                      } else {
                        _selectedTeamIds.remove(team['id']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
        ],
      ],
    );
  }

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
        if (_needsDoctorScope) ...[
          const Divider(height: 24),
          _buildReviewTile(
            icon: Icons.person_outline,
            title: 'linkedDoctors'.tr(),
            subtitle: _isAllDoctors
                ? 'allDoctors'.tr()
                : _selectedDoctorIds.isEmpty
                    ? 'none'.tr()
                    : '${_selectedDoctorIds.length} doctors selected',
          ),
        ],
        if (_needsDeptScope) ...[
          const Divider(height: 24),
          _buildReviewTile(
            icon: Icons.business_outlined,
            title: 'linkedDepartments'.tr(),
            subtitle: _isAllDepartments
                ? 'allDepartments'.tr()
                : _selectedDepartmentIds.isEmpty
                    ? 'none'.tr()
                    : '${_selectedDepartmentIds.length} departments selected',
          ),
        ],
        if (_needsTeamScope) ...[
          const Divider(height: 24),
          _buildReviewTile(
            icon: Icons.groups_outlined,
            title: 'linkedTeams'.tr(),
            subtitle: _isAllTeams
                ? 'allTeams'.tr()
                : _selectedTeamIds.isEmpty
                    ? 'none'.tr()
                    : '${_selectedTeamIds.length} teams selected',
          ),
        ],
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
      return ShimmerList(itemCount: 5);
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
                  icon: Icon(Icons.adaptive.arrow_back, size: 16),
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
              if (_availablePeople.any(
                (p) => p.email.toLowerCase() == value.toLowerCase(),
              )) {
                return 'This user is already a member. Please select them from the list.';
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
              _currentStep = 1; // Stay on the current step but force rebuild
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
                // groupValue and onChanged removed as they are handled by RadioGroup
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(
                              () => _showAllPermissions = !_showAllPermissions),
                          icon: Icon(_showAllPermissions
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          label: Text(_showAllPermissions
                              ? 'showRelevant'.tr()
                              : 'showAll'.tr()),
                        ),
                      ],
                    ),
                    ...AppPermissionCategory.values.map((category) {
                      final categoryPermissions = AppPermission.values
                          .where((p) => p.category == category)
                          .where((p) =>
                              _showAllPermissions ||
                              p.isMeaningfulFor(_selectedRole!))
                          .toList();

                      if (categoryPermissions.isEmpty) return const SizedBox();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              _getCategoryDisplayName(category),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                          ...categoryPermissions.map((permission) {
                            final isSelected = _selectedPermissions.contains(
                              permission,
                            );
                            return CheckboxListTile(
                              title:
                                  Text(_getPermissionDisplayName(permission)),
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
                          }),
                          const Divider(),
                        ],
                      );
                    }),
                  ],
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

    return formattedName
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _getPermissionDescription(AppPermission permission) {
    switch (permission) {
      // Patient management
      case AppPermission.viewPatients:
        return 'Allows viewing patient profiles and their medical records.';
      case AppPermission.createPatient:
        return 'Allows adding new patients to the clinic\'s database.';
      case AppPermission.updatePatient:
        return 'Allows editing patient demographic and contact information.';
      case AppPermission.deletePatient:
        return 'Allows permanently deleting a patient record.';

      // Session management
      case AppPermission.viewSessions:
        return 'Allows viewing details of patient therapy or consultation sessions.';
      case AppPermission.createSession:
        return 'Allows creating new sessions for patients.';
      case AppPermission.updateSession:
        return 'Allows modifying details of existing patient sessions.';
      case AppPermission.deleteSession:
        return 'Allows deleting patient sessions.';

      // Evaluation management
      case AppPermission.viewEvaluations:
        return 'Allows viewing patient assessment and evaluation results.';
      case AppPermission.createEvaluation:
        return 'Allows adding new patient evaluations.';
      case AppPermission.updateEvaluation:
        return 'Allows editing patient evaluation data and conclusions.';
      case AppPermission.deleteEvaluation:
        return 'Allows deleting evaluation records.';

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
        return 'Allows access to the AI-powered Dr. AI chat features.';

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
        return 'Allows configuring system-wide notifications.';

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
      case AppPermission.createMedicalFile:
        return 'Allows uploading or adding new medical files.';
      case AppPermission.updateMedicalFile:
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
      case AppPermission.createClinicalReport:
        return 'Allows creating new clinical reports.';
      case AppPermission.updateClinicalReport:
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
        return 'Allows contacting support.';
      case AppPermission.sendNotificationMessage:
        return 'Allows sending manual message notifications.';
      case AppPermission.sendNotificationAppointment:
        return 'Allows sending appointment reminders.';
      case AppPermission.sendNotificationReminder:
        return 'Allows sending general reminders.';
      case AppPermission.viewTeams:
        return 'Allows viewing teams.';
      case AppPermission.manageTeams:
        return 'Allows managing teams.';
      case AppPermission.createTeam:
        return 'Allows creating new teams.';
      case AppPermission.archiveTeam:
        return 'Allows archiving teams.';
      case AppPermission.unarchiveTeam:
        return 'Allows restoring archived teams.';
      case AppPermission.viewTeamMembers:
        return 'Allows viewing the full member list of any team (admin-only).';
      case AppPermission.viewTeamMessages:
        return 'Allows reading messages in any team chat without being a member (admin-only).';

      // Inventory
      case AppPermission.viewInventory:
        return 'Allows viewing inventory items.';
      case AppPermission.manageInventory:
        return 'Allows managing inventory.';
      case AppPermission.adjustInventoryStock:
        return 'Allows adjusting stock quantities.';

      // Departments
      case AppPermission.viewDepartments:
        return 'Allows viewing departments.';
      case AppPermission.manageDepartments:
        return 'Allows managing departments.';

      case AppPermission.manageWorkingHours:
        return 'Allows editing working hours.';
      case AppPermission.manageBookingAvailability:
        return 'Allows managing booking availability.';
      case AppPermission.viewAllTasks:
        return 'Allows viewing all tasks in the clinic.';
      case AppPermission.viewOwnTasks:
        return 'Allows viewing tasks assigned to the current user.';
      case AppPermission.createTask:
        return 'Allows creating a new task.';
      case AppPermission.updateTask:
        return 'Allows editing an existing task.';
      case AppPermission.deleteTask:
        return 'Allows deleting a task.';
    }
  }

  String _getCategoryDisplayName(AppPermissionCategory category) {
    switch (category) {
      case AppPermissionCategory.patientManagement:
        return 'patientManagement'.tr();
      case AppPermissionCategory.clinical:
        return 'clinical'.tr();
      case AppPermissionCategory.financial:
        return 'financial'.tr();
      case AppPermissionCategory.administrative:
        return 'administrative'.tr();
      case AppPermissionCategory.scopedAccess:
        return 'scopedAccess'.tr();
      case AppPermissionCategory.inventory:
        return 'inventory'.tr();
      case AppPermissionCategory.teamCollab:
        return 'teamCollab'.tr();
      case AppPermissionCategory.system:
        return 'system'.tr();
    }
  }
}
