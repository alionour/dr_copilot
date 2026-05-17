import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_defaults.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:dr_copilot/src/features/departments/domain/repositories/abstract_departments_repository.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';
import 'dart:developer';

class ClinicMembersPage extends StatefulWidget {
  const ClinicMembersPage({super.key});

  @override
  State<ClinicMembersPage> createState() => _ClinicMembersPageState();
}

class _ClinicMembersPageState extends State<ClinicMembersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clinicId = OwnerNotifier().clinicId;
    final currentUserId = OwnerNotifier().ownerId;

    final canManageMembers = OwnerNotifier().hasPermission(AppPermission.assignPermissions) ||
        OwnerNotifier().hasPermission(AppPermission.manageUsers);

    if (!canManageMembers) {
      return Scaffold(
        appBar: AppBar(title: Text('clinicMembers'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                Text(
                  'notAuthorized'.tr(),
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (clinicId == null || clinicId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('clinicMembers'.tr())),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text(
                  'No clinic assigned',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('clinicMembers'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search & Info Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'manageMembers'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'searchMembers'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),
          // Members List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('clinics')
                  .doc(clinicId)
                  .collection('members')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('somethingWentWrong'.tr()),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('noMembersFound'.tr()),
                  );
                }

                // Filter docs locally based on search query
                final filteredDocs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final displayName = (data['displayName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  return displayName.contains(_searchQuery) || email.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text('noResultsFound'.tr()),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final memberId = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    final displayName = data['displayName'] ?? 'Unknown Member';
                    final email = data['email'] ?? '';
                    final roleStr = data['role'] ?? 'readonly';
                    final permissions = List<String>.from(data['permissions'] ?? []);

                    final isSelf = memberId == currentUserId;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 0.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelf) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'you'.tr(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(email, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    roleStr.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${permissions.length} ${'permissions'.tr()}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          _showEditMemberDialog(context, clinicId, memberId, data);
                        },
                      ),
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

  void _showEditMemberDialog(
    BuildContext context,
    String clinicId,
    String memberId,
    Map<String, dynamic> memberData,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return EditMemberDialog(
          clinicId: clinicId,
          memberId: memberId,
          memberData: memberData,
        );
      },
    );
  }
}

class EditMemberDialog extends StatefulWidget {
  final String clinicId;
  final String memberId;
  final Map<String, dynamic> memberData;

  const EditMemberDialog({
    super.key,
    required this.clinicId,
    required this.memberId,
    required this.memberData,
  });

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  late AppRole _selectedRole;
  final Set<AppPermission> _selectedPermissions = {};

  final List<String> _selectedDoctorIds = [];
  final List<String> _selectedDepartmentIds = [];
  final List<String> _selectedTeamIds = [];

  bool _isAllDoctors = true;
  bool _isAllDepartments = true;
  bool _isAllTeams = true;

  List<Map<String, dynamic>> _availableDoctors = [];
  List<Map<String, dynamic>> _availableDepartments = [];
  List<Map<String, dynamic>> _availableTeams = [];

  bool _showAllPermissions = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadMetadata();
  }

  void _initializeData() {
    final roleStr = widget.memberData['role'] ?? 'readonly';
    _selectedRole = AppRole.values.firstWhere(
      (e) => e.name.toLowerCase() == roleStr.toLowerCase(),
      orElse: () {
        if (roleStr.toLowerCase() == 'receptionist') {
          return AppRole.staff;
        }
        return AppRole.readonly;
      },
    );

    final permStrings = List<String>.from(widget.memberData['permissions'] ?? []);
    for (final pStr in permStrings) {
      final perm = AppPermission.values.firstWhere(
        (e) => e.name == pStr,
        orElse: () => AppPermission.viewHelp,
      );
      if (perm != AppPermission.viewHelp || pStr == AppPermission.viewHelp.name) {
        _selectedPermissions.add(perm);
      }
    }

    final doctorIds = List<String>.from(widget.memberData['linkedDoctorIds'] ?? []);
    _isAllDoctors = doctorIds.contains('ALL');
    if (!_isAllDoctors) {
      _selectedDoctorIds.addAll(doctorIds);
    }

    final deptIds = List<String>.from(widget.memberData['departmentIds'] ?? []);
    _isAllDepartments = deptIds.contains('ALL') || deptIds.isEmpty;
    if (!_isAllDepartments) {
      _selectedDepartmentIds.addAll(deptIds);
    }

    final teamIds = List<String>.from(widget.memberData['teamIds'] ?? []);
    _isAllTeams = teamIds.contains('ALL') || teamIds.isEmpty;
    if (!_isAllTeams) {
      _selectedTeamIds.addAll(teamIds);
    }
  }

  Future<void> _loadMetadata() async {
    try {
      final doctorsResult = await sl<DoctorsUseCase>().getDoctors(clinicId: widget.clinicId);
      final deptRepo = sl<AbstractDepartmentsRepository>();
      final teamRepo = sl<AbstractCustomTeamsRepository>();

      final deptResult = await deptRepo.getDepartments(widget.clinicId);
      final teamResult = await teamRepo.getTeamsForClinic(widget.clinicId);

      if (mounted) {
        setState(() {
          _availableDoctors = doctorsResult.fold(
            (f) => [],
            (list) => list.map((d) => {'id': d.id, 'name': d.name}).toList(),
          );
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

  void _updatePermissionsBasedOnRoles() {
    _selectedPermissions.clear();
    _selectedPermissions.addAll(
      RoleDefaults.getPermissionsForRole(_selectedRole),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = widget.memberData['displayName'] ?? 'Unknown Member';
    final email = widget.memberData['email'] ?? '';
    final isSelf = widget.memberId == OwnerNotifier().ownerId;

    final hasAssignPermissions = OwnerNotifier().hasPermission(AppPermission.assignPermissions);
    final hasAssignRoles = OwnerNotifier().hasPermission(AppPermission.assignRoles) ||
        OwnerNotifier().hasPermission(AppPermission.manageUsers);
    final hasManageUsers = OwnerNotifier().hasPermission(AppPermission.manageUsers);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          email,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  // --- ROLE SELECTOR ---
                  Text(
                    'role'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AppRole>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: AppRole.values.map((role) {
                      return DropdownMenuItem<AppRole>(
                        value: role,
                        child: Text(_getRoleDisplayName(role)),
                      );
                    }).toList(),
                    onChanged: hasAssignRoles ? (AppRole? value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                          _updatePermissionsBasedOnRoles();
                        });
                      }
                    } : null,
                  ),
                  const SizedBox(height: 24),

                  // --- SCOPES (DOCTORS) ---
                  if (_selectedRole == AppRole.doctor || _selectedRole == AppRole.staff) ...[
                    _buildScopeSection(
                      title: 'doctorAssociation'.tr(),
                      description: 'doctorScopeDescription'.tr(),
                      isAll: _isAllDoctors,
                      onAllChanged: (val) => setState(() => _isAllDoctors = val!),
                      availableItems: _availableDoctors,
                      selectedIds: _selectedDoctorIds,
                      allLabel: 'allDoctors'.tr(),
                      specificLabel: 'specificDoctors'.tr(),
                      isEnabled: hasAssignRoles,
                    ),
                    const SizedBox(height: 24),

                    // --- SCOPES (DEPARTMENTS) ---
                    _buildScopeSection(
                      title: 'departmentAssociation'.tr(),
                      description: 'departmentScopeDescription'.tr(),
                      isAll: _isAllDepartments,
                      onAllChanged: (val) => setState(() => _isAllDepartments = val!),
                      availableItems: _availableDepartments,
                      selectedIds: _selectedDepartmentIds,
                      allLabel: 'allDepartments'.tr(),
                      specificLabel: 'specificDepartments'.tr(),
                      isEnabled: hasAssignRoles,
                    ),
                    const SizedBox(height: 24),

                    // --- SCOPES (TEAMS) ---
                    _buildScopeSection(
                      title: 'teamAssociation'.tr(),
                      description: 'teamScopeDescription'.tr(),
                      isAll: _isAllTeams,
                      onAllChanged: (val) => setState(() => _isAllTeams = val!),
                      availableItems: _availableTeams,
                      selectedIds: _selectedTeamIds,
                      allLabel: 'allTeams'.tr(),
                      specificLabel: 'specificTeams'.tr(),
                      isEnabled: hasAssignRoles,
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- PERMISSIONS CUSTOMIZER ---
                  ExpansionTile(
                    title: Text('customizePermissions'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('advancedPermissions'.tr()),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Column(
                          children: [
                            if (hasAssignPermissions)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => setState(() => _showAllPermissions = !_showAllPermissions),
                                    icon: Icon(_showAllPermissions
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    label: Text(_showAllPermissions ? 'showRelevant'.tr() : 'showAll'.tr()),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => setState(() => _updatePermissionsBasedOnRoles()),
                                    icon: const Icon(Icons.refresh_outlined),
                                    label: Text('reset'.tr()),
                                  ),
                                ],
                              ),
                            ...AppPermissionCategory.values.map((category) {
                              final categoryPermissions = AppPermission.values
                                  .where((p) => p.category == category)
                                  .where((p) => _showAllPermissions || p.isMeaningfulFor(_selectedRole))
                                  .toList();

                              if (categoryPermissions.isEmpty) return const SizedBox();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                                    child: Text(
                                      _getCategoryDisplayName(category),
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                            color: Theme.of(context).colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  ...categoryPermissions.map((permission) {
                                    final isSelected = _selectedPermissions.contains(permission);
                                    return CheckboxListTile(
                                      title: Text(_getPermissionDisplayName(permission)),
                                      subtitle: Text(
                                        _getPermissionDescription(permission),
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      value: isSelected,
                                      onChanged: hasAssignPermissions ? (bool? value) {
                                        setState(() {
                                          if (value == true) {
                                            _selectedPermissions.add(permission);
                                          } else {
                                            _selectedPermissions.remove(permission);
                                          }
                                        });
                                      } : null,
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
              ),
            ),
            const Divider(height: 1),

            // Actions Footer
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  if (!isSelf && hasManageUsers) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(color: Theme.of(context).colorScheme.error),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: Text('delete'.tr()),
                      onPressed: _isSaving ? null : () => _confirmRemoveMember(context),
                    ),
                  ],
                  const Spacer(),
                  if (hasAssignPermissions || hasAssignRoles || hasManageUsers) ...[
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      child: Text('cancel'.tr()),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => _saveMember(context),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('save'.tr()),
                    ),
                  ] else ...[
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScopeSection({
    required String title,
    required String description,
    required bool isAll,
    required ValueChanged<bool?> onAllChanged,
    required List<Map<String, dynamic>> availableItems,
    required List<String> selectedIds,
    required String allLabel,
    required String specificLabel,
    bool isEnabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text(allLabel),
                value: true,
                groupValue: isAll,
                onChanged: isEnabled ? onAllChanged : null,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text(specificLabel),
                value: false,
                groupValue: isAll,
                onChanged: isEnabled ? onAllChanged : null,
              ),
            ),
          ],
        ),
        if (!isAll) ...[
          const SizedBox(height: 8),
          if (availableItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'None available',
                style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: availableItems.map((item) {
                  final id = item['id'] as String;
                  final name = item['name'] as String;
                  final isChecked = selectedIds.contains(id);
                  return CheckboxListTile(
                    dense: true,
                    title: Text(name),
                    value: isChecked,
                    onChanged: isEnabled ? (val) {
                      setState(() {
                        if (val == true) {
                          selectedIds.add(id);
                        } else {
                          selectedIds.remove(id);
                        }
                      });
                    } : null,
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _saveMember(BuildContext context) async {
    setState(() => _isSaving = true);
    try {
      final updatedData = {
        'role': _selectedRole.name,
        'permissions': _selectedPermissions.map((p) => p.name).toList(),
        'linkedDoctorIds': _isAllDoctors ? ['ALL'] : _selectedDoctorIds,
        'departmentIds': _isAllDepartments ? ['ALL'] : _selectedDepartmentIds,
        'teamIds': _isAllTeams ? ['ALL'] : _selectedTeamIds,
      };

      await FirebaseFirestore.instance
          .collection('clinics')
          .doc(widget.clinicId)
          .collection('members')
          .doc(widget.memberId)
          .update(updatedData);

      final isSelf = widget.memberId == OwnerNotifier().ownerId;
      if (isSelf) {
        GetIt.I<PermissionService>().clearCache();
        await OwnerNotifier().loadOwnerIdAndClinicId();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('memberUpdated'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      log('Error saving member permissions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('somethingWentWrong'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmRemoveMember(BuildContext context) async {
    final displayName = widget.memberData['displayName'] ?? 'Unknown Member';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('delete'.tr()),
          content: Text('Are you sure you want to remove $displayName from the clinic? They will lose all access immediately.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr()),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('delete'.tr()),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() => _isSaving = true);
      try {
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(widget.clinicId)
            .collection('members')
            .doc(widget.memberId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member removed from clinic successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Close edit dialog
        }
      } catch (e) {
        log('Error removing member: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('somethingWentWrong'.tr()),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
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
    String name = permission.name;
    if (name.startsWith('can') && name.length > 3 && name[3] == name[3].toUpperCase()) {
      name = name.substring(3);
    }
    String formattedName = name.replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)!}').trim();
    return formattedName.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _getPermissionDescription(AppPermission permission) {
    switch (permission) {
      case AppPermission.viewPatients:
        return 'Allows viewing patient profiles and their medical records.';
      case AppPermission.createPatient:
        return 'Allows adding new patients to the clinic\'s database.';
      case AppPermission.updatePatient:
        return 'Allows editing patient demographic and contact information.';
      case AppPermission.deletePatient:
        return 'Allows permanently deleting a patient record.';
      case AppPermission.viewSessions:
        return 'Allows viewing details of patient therapy or consultation sessions.';
      case AppPermission.createSession:
        return 'Allows creating new sessions for patients.';
      case AppPermission.updateSession:
        return 'Allows modifying details of existing patient sessions.';
      case AppPermission.deleteSession:
        return 'Allows deleting patient sessions.';
      case AppPermission.viewEvaluations:
        return 'Allows viewing patient assessment and evaluation results.';
      case AppPermission.createEvaluation:
        return 'Allows adding new patient evaluations.';
      case AppPermission.updateEvaluation:
        return 'Allows editing patient evaluation data and conclusions.';
      case AppPermission.deleteEvaluation:
        return 'Allows deleting evaluation records.';
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
      case AppPermission.useCopilot:
        return 'Allows access to the AI-powered Dr. Copilot chat features.';
      case AppPermission.viewCalendar:
        return 'Allows viewing the clinic and personal appointment calendar.';
      case AppPermission.editCalendarEvent:
        return 'Allows modifying existing appointments on the calendar.';
      case AppPermission.addCalendarEvent:
        return 'Allows adding new appointments or events to the calendar.';
      case AppPermission.deleteCalendarEvent:
        return 'Allows removing events from the calendar.';
      case AppPermission.viewNotifications:
        return 'Allows viewing system notifications and alerts.';
      case AppPermission.manageNotifications:
        return 'Allows configuring system-wide notifications.';
      case AppPermission.viewSettings:
        return 'Allows viewing clinic and application settings.';
      case AppPermission.editSettings:
        return 'Allows changing clinic settings and configurations.';
      case AppPermission.manageSettings:
        return 'Allows managing all settings.';
      case AppPermission.viewMedicalFiles:
        return 'Allows viewing medical files.';
      case AppPermission.createMedicalFile:
        return 'Allows uploading or adding new medical files.';
      case AppPermission.updateMedicalFile:
        return 'Allows editing medical file details.';
      case AppPermission.deleteMedicalFile:
        return 'Allows deleting medical files.';
      case AppPermission.viewMedications:
        return 'Allows viewing patient medications.';
      case AppPermission.addMedication:
        return 'Allows prescribing or adding medications.';
      case AppPermission.editMedication:
        return 'Allows editing medication details.';
      case AppPermission.deleteMedication:
        return 'Allows removing medications.';
      case AppPermission.viewRecycleBin:
        return 'Allows accessing the recycle bin.';
      case AppPermission.restoreRecycleBinItem:
        return 'Allows restoring deleted items.';
      case AppPermission.permanentDeleteRecycleBinItem:
        return 'Allows permanently deleting items.';
      case AppPermission.manageStaff:
        return 'Allows managing staff members.';
      case AppPermission.manageUsers:
        return 'Allows inviting, editing roles of, and removing users from the clinic.';
      case AppPermission.assignRoles:
        return 'Allows changing the roles assigned to users.';
      case AppPermission.assignPermissions:
        return 'Allows assigning or revoking specific permissions for roles.';
      case AppPermission.viewReports:
        return 'Allows generating and viewing detailed clinic reports.';
      case AppPermission.viewCharts:
        return 'Allows viewing data visualizations and performance charts.';
      case AppPermission.viewClinicalReports:
        return 'Allows viewing clinical reports.';
      case AppPermission.createClinicalReport:
        return 'Allows creating new clinical reports.';
      case AppPermission.updateClinicalReport:
        return 'Allows editing existing clinical reports.';
      case AppPermission.deleteClinicalReport:
        return 'Allows deleting clinical reports.';
      case AppPermission.viewDoctors:
        return 'Allows viewing the doctors directory.';
      case AppPermission.manageDoctors:
        return 'Allows adding, collecting, or removing doctors.';
      case AppPermission.viewInvitations:
        return 'Allows viewing pending and sent invitations.';
      case AppPermission.sendInvitation:
        return 'Allows sending new invitations to staff or doctors.';
      case AppPermission.revokeInvitation:
        return 'Allows revoking or deleting invitations.';
      case AppPermission.viewSubscription:
        return 'Allows viewing billing and subscription details.';
      case AppPermission.manageSubscription:
        return 'Allows upgrading or changing the subscription plan.';
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
      case AppPermission.viewInventory:
        return 'Allows viewing inventory items.';
      case AppPermission.manageInventory:
        return 'Allows managing inventory.';
      case AppPermission.adjustInventoryStock:
        return 'Allows adjusting stock quantities.';
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
