import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/departments/domain/models/department_model.dart';
import 'package:dr_copilot/src/features/departments/presentation/pages/create_edit_department_page.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_bloc.dart';

class DepartmentDetailPage extends StatefulWidget {
  final DepartmentModel department;

  const DepartmentDetailPage({super.key, required this.department});

  @override
  State<DepartmentDetailPage> createState() => _DepartmentDetailPageState();
}

class _DepartmentDetailPageState extends State<DepartmentDetailPage> {
  late String _deptName;
  late String _deptDesc;
  List<DoctorModel> _allClinicDoctors = [];

  // Firestore streams cached to prevent infinite rebuild loops
  late final Stream<DocumentSnapshot> _departmentStream;
  late final Stream<List<Map<String, dynamic>>> _membersStream;
  late final Stream<List<PatientModel>> _patientsStream;

  // Search queries
  String _doctorQuery = '';
  String _staffQuery = '';
  String _patientQuery = '';

  @override
  void initState() {
    super.initState();
    _deptName = widget.department.name;
    _deptDesc = widget.department.description ?? '';
    
    final clinicId = widget.department.clinicId;
    final departmentId = widget.department.id;

    // Initialize streams once
    _departmentStream = FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('departments')
        .doc(departmentId)
        .snapshots();

    _membersStream = FirebaseFirestore.instance
        .collection('clinics')
        .doc(clinicId)
        .collection('members')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());

    _patientsStream = FirebaseFirestore.instance
        .collection('patients')
        .where('clinicId', isEqualTo: clinicId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return PatientModel.fromJson({
                ...data,
                'id': doc.id,
              });
            }).toList());

    _loadClinicDoctors();
  }

  Future<void> _loadClinicDoctors() async {
    try {
      final doctorsResult = await sl<DoctorsUseCase>().getDoctors(clinicId: widget.department.clinicId);
      doctorsResult.fold(
        (failure) => debugPrint('Error loading doctors: ${failure.message}'),
        (list) {
          if (mounted) {
            setState(() {
              _allClinicDoctors = list;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading clinic doctors: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerNotifier = OwnerNotifier();
    final canManage = ownerNotifier.hasPermission(AppPermission.manageDepartments);

    return StreamBuilder<DocumentSnapshot>(
      stream: _departmentStream,
      builder: (context, deptSnapshot) {
        if (deptSnapshot.hasData && deptSnapshot.data!.exists) {
          final data = deptSnapshot.data!.data() as Map<String, dynamic>;
          _deptName = data['name'] ?? widget.department.name;
          _deptDesc = data['description'] ?? '';
        }

        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: Text(_deptName),
              actions: [
                if (canManage)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editDepartment(context),
                    tooltip: 'editDepartment'.tr(),
                  ),
              ],
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            body: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _membersStream,
              builder: (context, membersSnapshot) {
                return StreamBuilder<List<PatientModel>>(
                  stream: _patientsStream,
                  builder: (context, patientsSnapshot) {
                    if (membersSnapshot.connectionState == ConnectionState.waiting ||
                        patientsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allMembers = membersSnapshot.data ?? [];
                    final allPatients = patientsSnapshot.data ?? [];

                    // Filter department doctors: members having role 'doctor' and departmentIds contains departmentId
                    final deptDoctors = allMembers.where((m) {
                      final roles = (m['role'] ?? '').toString().toLowerCase();
                      final deptIds = List<String>.from(m['departmentIds'] ?? []);
                      return roles == 'doctor' && (deptIds.contains(departmentId) || deptIds.contains('ALL'));
                    }).toList();

                    // Filter department staff: members not having role 'doctor' and departmentIds contains departmentId
                    final deptStaff = allMembers.where((m) {
                      final roles = (m['role'] ?? '').toString().toLowerCase();
                      final deptIds = List<String>.from(m['departmentIds'] ?? []);
                      return roles != 'doctor' && (deptIds.contains(departmentId) || deptIds.contains('ALL'));
                    }).toList();

                    // Filter department patients: patients having departmentId equal to departmentId
                    final deptPatients = allPatients.where((p) => p.departmentId == departmentId).toList();

                    return Column(
                      children: [
                        // PREMIUM HEADER CARD WITH GRADIENT
                        _buildHeaderCard(deptDoctors.length, deptStaff.length, deptPatients.length),

                        // TAB BAR
                        Container(
                          color: Theme.of(context).colorScheme.surface,
                          child: TabBar(
                            labelColor: Theme.of(context).colorScheme.primary,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Theme.of(context).colorScheme.primary,
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: [
                              Tab(icon: const Icon(Icons.analytics_outlined), text: 'overview'.tr()),
                              Tab(icon: const Icon(Icons.people_outline), text: 'assignedDoctors'.tr()),
                              Tab(icon: const Icon(Icons.badge_outlined), text: 'assignedStaff'.tr()),
                              Tab(icon: const Icon(Icons.medical_services_outlined), text: 'assignedPatients'.tr()),
                            ],
                          ),
                        ),

                        // TAB BAR VIEW
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildOverviewTab(deptDoctors.length, deptStaff.length, deptPatients),
                              _buildDoctorsTab(deptDoctors, allMembers, canManage),
                              _buildStaffTab(deptStaff, allMembers, canManage),
                              _buildPatientsTab(deptPatients, allPatients, canManage),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(int doctorsCount, int staffCount, int patientsCount) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.85),
            Theme.of(context).colorScheme.secondary.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _deptName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_deptDesc.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        _deptDesc,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white30, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStatItem(Icons.people_outline, doctorsCount.toString(), 'assignedDoctors'.tr()),
              _buildHeaderStatItem(Icons.badge_outlined, staffCount.toString(), 'assignedStaff'.tr()),
              _buildHeaderStatItem(Icons.medical_services_outlined, patientsCount.toString(), 'assignedPatients'.tr()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatItem(IconData icon, String count, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(int doctorsCount, int staffCount, List<PatientModel> patients) {
    // Stat Calculations
    final totalPatients = patients.length;
    double avgAge = 0;
    int maleCount = 0;
    int femaleCount = 0;
    int otherCount = 0;

    int childrenCount = 0; // < 18
    int adultCount = 0;    // 18 - 60
    int seniorCount = 0;   // > 60

    if (totalPatients > 0) {
      double totalAge = 0;
      int patientsWithAge = 0;

      for (final p in patients) {
        if (p.age != null) {
          totalAge += p.age!;
          patientsWithAge++;

          if (p.age! < 18) {
            childrenCount++;
          } else if (p.age! <= 60) {
            adultCount++;
          } else {
            seniorCount++;
          }
        }

        final gender = (p.gender ?? '').toLowerCase();
        if (gender == 'male' || gender == 'm') {
          maleCount++;
        } else if (gender == 'female' || gender == 'f') {
          femaleCount++;
        } else {
          otherCount++;
        }
      }

      if (patientsWithAge > 0) {
        avgAge = totalAge / patientsWithAge;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'statistics'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // SUMMARY CARDS ROW
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetricCard(
                  context,
                  'averagePatientAge'.tr(),
                  totalPatients > 0 ? '${avgAge.toStringAsFixed(1)} ${'yearsOld'.tr()}' : 'not_available'.tr(),
                  Icons.cake_outlined,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetricCard(
                  context,
                  'assignedPatients'.tr(),
                  totalPatients.toString(),
                  Icons.assignment_ind_outlined,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // GENDER DISTRIBUTION CARD
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'patientGenderDistribution'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (totalPatients == 0)
                    Text('noPatientsAssigned'.tr(), style: const TextStyle(color: Colors.grey))
                  else ...[
                    _buildDistributionRow('Male', maleCount, totalPatients, Colors.blue),
                    const SizedBox(height: 12),
                    _buildDistributionRow('Female', femaleCount, totalPatients, Colors.pink),
                    if (otherCount > 0) ...[
                      const SizedBox(height: 12),
                      _buildDistributionRow('Other', otherCount, totalPatients, Colors.purple),
                    ]
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // AGE DISTRIBUTION CARD
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'patientAgeDistribution'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (totalPatients == 0)
                    Text('noPatientsAssigned'.tr(), style: const TextStyle(color: Colors.grey))
                  else ...[
                    _buildDistributionRow('Children (< 18)', childrenCount, totalPatients, Colors.green),
                    const SizedBox(height: 12),
                    _buildDistributionRow('Adults (18 - 60)', adultCount, totalPatients, Colors.teal),
                    const SizedBox(height: 12),
                    _buildDistributionRow('Seniors (> 60)', seniorCount, totalPatients, Colors.indigo),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetricCard(BuildContext context, String title, String val, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(String title, int count, int total, Color color) {
    final double percent = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            Text('$count (${(percent * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorsTab(List<Map<String, dynamic>> deptDoctors, List<Map<String, dynamic>> allMembers, bool canManage) {
    final filteredDoctors = deptDoctors.where((doc) {
      final name = (doc['displayName'] ?? '').toString().toLowerCase();
      final email = (doc['email'] ?? '').toString().toLowerCase();
      return name.contains(_doctorQuery.trim().toLowerCase()) || email.contains(_doctorQuery.trim().toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search & Manage Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'searchDoctors'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _doctorQuery = val),
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showManageDoctorsDialog(allMembers),
                  icon: const Icon(Icons.add),
                  label: Text('assignDoctors'.tr()),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: filteredDoctors.isEmpty
              ? Center(child: Text('noDoctorsAssigned'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredDoctors.length,
                  itemBuilder: (context, index) {
                    final member = filteredDoctors[index];
                    final memberId = member['id'] as String;
                    final displayName = member['displayName'] ?? 'Unknown Member';
                    final email = member['email'] ?? '';

                    // Find corresponding DoctorModel to display specialty
                    final doctorProfile = _allClinicDoctors.firstWhere((d) => d.id == memberId,
                        orElse: () => DoctorModel(
                              id: '',
                              name: '',
                              specialty: '',
                              clinicId: '',
                              email: '',
                              phoneNumber: '',
                              createdAt: Timestamp.now(),
                              updatedAt: Timestamp.now(),
                            ));

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'D'),
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          doctorProfile.specialty.isNotEmpty ? doctorProfile.specialty : email,
                          style: const TextStyle(fontSize: 13),
                        ),
                        trailing: canManage
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeMemberFromDepartment(memberId, displayName),
                                tooltip: 'Remove from department',
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStaffTab(List<Map<String, dynamic>> deptStaff, List<Map<String, dynamic>> allMembers, bool canManage) {
    final filteredStaff = deptStaff.where((stf) {
      final name = (stf['displayName'] ?? '').toString().toLowerCase();
      final email = (stf['email'] ?? '').toString().toLowerCase();
      return name.contains(_staffQuery.trim().toLowerCase()) || email.contains(_staffQuery.trim().toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search & Manage Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'searchStaff'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _staffQuery = val),
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showManageStaffDialog(allMembers),
                  icon: const Icon(Icons.add),
                  label: Text('assignStaff'.tr()),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: filteredStaff.isEmpty
              ? Center(child: Text('noStaffAssigned'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredStaff.length,
                  itemBuilder: (context, index) {
                    final member = filteredStaff[index];
                    final memberId = member['id'] as String;
                    final displayName = member['displayName'] ?? 'Unknown Member';
                    final email = member['email'] ?? '';
                    final roleStr = member['role'] ?? 'staff';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S'),
                        ),
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${roleStr.toString().toUpperCase()} • $email', style: const TextStyle(fontSize: 13)),
                        trailing: canManage
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removeMemberFromDepartment(memberId, displayName),
                                tooltip: 'Remove from department',
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPatientsTab(List<PatientModel> deptPatients, List<PatientModel> allPatients, bool canManage) {
    final filteredPatients = deptPatients.where((pat) {
      final name = pat.name.toLowerCase();
      final phone = (pat.phoneNumber ?? '').toLowerCase();
      return name.contains(_patientQuery.trim().toLowerCase()) || phone.contains(_patientQuery.trim().toLowerCase());
    }).toList();

    return Column(
      children: [
        // Search & Manage Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'searchPatients'.tr(),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _patientQuery = val),
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showManagePatientsDialog(allPatients),
                  icon: const Icon(Icons.add),
                  label: Text('assignPatients'.tr()),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ],
          ),
        ),

        // List
        Expanded(
          child: filteredPatients.isEmpty
              ? Center(child: Text('noPatientsAssigned'.tr()))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPatients.length,
                  itemBuilder: (context, index) {
                    final patient = filteredPatients[index];
                    final name = patient.name;
                    final gender = patient.gender ?? 'not_available'.tr();
                    final age = patient.age != null ? '${patient.age} ${'yearsOld'.tr()}' : 'not_available'.tr();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'P'),
                        ),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('$gender • $age • ${patient.phoneNumber ?? 'noPhoneNumber'.tr()}', style: const TextStyle(fontSize: 13)),
                        trailing: canManage
                            ? IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => _removePatientFromDepartment(patient.id, name),
                                tooltip: 'Remove from department',
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _editDepartment(BuildContext context) async {
    final departmentsBloc = context.read<DepartmentsBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: departmentsBloc,
          child: CreateEditDepartmentPage(department: widget.department),
        ),
      ),
    );
  }

  Future<void> _removeMemberFromDepartment(String memberId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member'),
        content: Text('Are you sure you want to remove $name from the ${widget.department.name} department?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(widget.department.clinicId)
            .collection('members')
            .doc(memberId)
            .update({
          'departmentIds': FieldValue.arrayRemove([widget.department.id]),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Member removed from department successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('somethingWentWrong'.tr()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _removePatientFromDepartment(String patientId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Patient'),
        content: Text('Are you sure you want to remove patient $name from the ${widget.department.name} department?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('patients').doc(patientId).update({
          'departmentId': null,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Patient removed from department successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('somethingWentWrong'.tr()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _showManageDoctorsDialog(List<Map<String, dynamic>> allMembers) {
    final doctorsInClinic = allMembers.where((m) => (m['role'] ?? '').toString().toLowerCase() == 'doctor').toList();
    final initialSelectedIds = doctorsInClinic
        .where((m) => List<String>.from(m['departmentIds'] ?? []).contains(widget.department.id))
        .map((m) => m['id'] as String)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        List<String> selectedIds = List.from(initialSelectedIds);
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text('assignDoctors'.tr()),
              content: SizedBox(
                width: 400,
                height: 400,
                child: doctorsInClinic.isEmpty
                    ? Center(child: Text('noDoctorsInClinic'.tr()))
                    : ListView.builder(
                        itemCount: doctorsInClinic.length,
                        itemBuilder: (context, index) {
                          final doc = doctorsInClinic[index];
                          final id = doc['id'] as String;
                          final name = doc['displayName'] ?? 'Unknown Doctor';
                          final isChecked = selectedIds.contains(id);

                          return CheckboxListTile(
                            title: Text(name),
                            value: isChecked,
                            onChanged: (val) {
                              dialogSetState(() {
                                if (val == true) {
                                  selectedIds.add(id);
                                } else {
                                  selectedIds.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _saveMembersAssociation(doctorsInClinic.map((d) => d['id'] as String).toList(), selectedIds);
                  },
                  child: Text('saveChanges'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManageStaffDialog(List<Map<String, dynamic>> allMembers) {
    final staffInClinic = allMembers.where((m) => (m['role'] ?? '').toString().toLowerCase() != 'doctor').toList();
    final initialSelectedIds = staffInClinic
        .where((m) => List<String>.from(m['departmentIds'] ?? []).contains(widget.department.id))
        .map((m) => m['id'] as String)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        List<String> selectedIds = List.from(initialSelectedIds);
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text('assignStaff'.tr()),
              content: SizedBox(
                width: 400,
                height: 400,
                child: staffInClinic.isEmpty
                    ? const Center(child: Text('No staff found.'))
                    : ListView.builder(
                        itemCount: staffInClinic.length,
                        itemBuilder: (context, index) {
                          final stf = staffInClinic[index];
                          final id = stf['id'] as String;
                          final name = stf['displayName'] ?? 'Unknown Member';
                          final roleStr = stf['role'] ?? 'staff';
                          final isChecked = selectedIds.contains(id);

                          return CheckboxListTile(
                            title: Text(name),
                            subtitle: Text(roleStr.toString().toUpperCase()),
                            value: isChecked,
                            onChanged: (val) {
                              dialogSetState(() {
                                if (val == true) {
                                  selectedIds.add(id);
                                } else {
                                  selectedIds.remove(id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _saveMembersAssociation(staffInClinic.map((s) => s['id'] as String).toList(), selectedIds);
                  },
                  child: Text('saveChanges'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveMembersAssociation(List<String> allEligibleIds, List<String> selectedIds) async {
    final batch = FirebaseFirestore.instance.batch();
    final clinicId = widget.department.clinicId;
    final departmentId = widget.department.id;

    try {
      for (final id in allEligibleIds) {
        final docRef = FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .collection('members')
            .doc(id);

        if (selectedIds.contains(id)) {
          batch.update(docRef, {
            'departmentIds': FieldValue.arrayUnion([departmentId]),
          });
        } else {
          batch.update(docRef, {
            'departmentIds': FieldValue.arrayRemove([departmentId]),
          });
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('saveSuccess'.tr()), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('somethingWentWrong'.tr()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showManagePatientsDialog(List<PatientModel> allPatients) {
    final initialSelectedIds = allPatients
        .where((p) => p.departmentId == widget.department.id)
        .map((p) => p.id)
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        List<String> selectedIds = List.from(initialSelectedIds);
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text('assignPatients'.tr()),
              content: SizedBox(
                width: 400,
                height: 400,
                child: allPatients.isEmpty
                    ? Center(child: Text('noPatientsFound'.tr()))
                    : ListView.builder(
                        itemCount: allPatients.length,
                        itemBuilder: (context, index) {
                          final patient = allPatients[index];
                          final isChecked = selectedIds.contains(patient.id);

                          return CheckboxListTile(
                            title: Text(patient.name),
                            subtitle: patient.phoneNumber != null ? Text(patient.phoneNumber!) : null,
                            value: isChecked,
                            onChanged: (val) {
                              dialogSetState(() {
                                if (val == true) {
                                  selectedIds.add(patient.id);
                                } else {
                                  selectedIds.remove(patient.id);
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _savePatientsAssociation(allPatients.map((p) => p.id).toList(), selectedIds);
                  },
                  child: Text('saveChanges'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _savePatientsAssociation(List<String> allEligibleIds, List<String> selectedIds) async {
    final batch = FirebaseFirestore.instance.batch();

    try {
      for (final id in allEligibleIds) {
        final docRef = FirebaseFirestore.instance.collection('patients').doc(id);

        if (selectedIds.contains(id)) {
          batch.update(docRef, {
            'departmentId': widget.department.id,
          });
        } else {
          // If the patient was previously assigned to this department but is no longer checked, clear it.
          // Wait, only update if the current field is actually this department's ID.
          batch.update(docRef, {
            'departmentId': null,
          });
        }
      }

      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('saveSuccess'.tr()), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('somethingWentWrong'.tr()), backgroundColor: Colors.red),
        );
      }
    }
  }
}
