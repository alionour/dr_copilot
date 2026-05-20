// Import necessary packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dr_copilot/src/core/helper/safe_click.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/departments/domain/repositories/abstract_departments_repository.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';

// AddPatientPage StatefulWidget
class AddPatientPage extends StatefulWidget {
  final PatientModel? patient;
  final Map<String, dynamic>? initialData;
  final bool showScaffold;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final ValueChanged<Map<String, dynamic>>? onFormDataChange;

  // Constructor for AddPatientPage
  const AddPatientPage({
    super.key,
    this.patient,
    this.initialData,
    this.showScaffold = true,
    this.onSuccess,
    this.onCancel,
    this.onFormDataChange,
  });

  @override
  State<AddPatientPage> createState() => _AddPatientPageState();
}

// _AddPatientPageState State class
class _AddPatientPageState extends State<AddPatientPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  // Text editing controllers for form fields
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _genderController = TextEditingController();
  final _addressController = TextEditingController();
  final _phone1Controller = TextEditingController();
  final _phone2Controller = TextEditingController();
  final _occupationController = TextEditingController();

  // Focus nodes for form fields
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _genderFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phone1FocusNode = FocusNode();
  final _phone2FocusNode = FocusNode();
  final _occupationFocusNode = FocusNode();

  String _selectedGender = 'Male';
  String? _selectedClinicId;
  String? _treatingDoctorId;
  String? _selectedDepartmentId;
  String? _selectedTeamId;
  List<DoctorModel> _doctors = [];
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _teams = [];
  bool _isLoadingDoctors = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _nameController.text = widget.patient!.name;
      _ageController.text = widget.patient!.age?.toString() ?? '';
      _addressController.text = widget.patient!.address ?? '';
      _phone1Controller.text = widget.patient!.phone1 ?? '';
      _phone2Controller.text = widget.patient!.phone2 ?? '';
      _treatingDoctorId = widget.patient!.treatingDoctorId;
      _occupationController.text = widget.patient!.occupation ?? '';
      _selectedGender = widget.patient!.gender ?? 'Male';
      _selectedClinicId = widget.patient!.clinicId;
      _selectedDepartmentId = widget.patient!.departmentId;
      _selectedTeamId = widget.patient!.teamId;
    } else if (widget.initialData != null) {
      final data = widget.initialData!;
      if (data['name'] != null) _nameController.text = data['name'].toString();
      if (data['age'] != null) _ageController.text = data['age'].toString();
      if (data['address'] != null) _addressController.text = data['address'].toString();
      if (data['phone1'] != null) {
        _phone1Controller.text = data['phone1'].toString();
      } else if (data['phoneNumber'] != null) {
        _phone1Controller.text = data['phoneNumber'].toString();
      }
      if (data['phone2'] != null) {
        _phone2Controller.text = data['phone2'].toString();
      } else if (data['alternativePhoneNumber'] != null) {
        _phone2Controller.text = data['alternativePhoneNumber'].toString();
      }
      if (data['treatingDoctorId'] != null) {
        _treatingDoctorId = data['treatingDoctorId'].toString();
      }
      if (data['gender'] != null) {
        final g = data['gender'].toString().toLowerCase();
        if (g.startsWith('m')) {
          _selectedGender = 'Male';
        } else if (g.startsWith('f')) {
          _selectedGender = 'Female';
        }
      }
      if (data['occupation'] != null) {
        _occupationController.text = data['occupation'].toString();
      }
    }
    _nameController.addListener(_notifyFormDataChange);
    _ageController.addListener(_notifyFormDataChange);
    _addressController.addListener(_notifyFormDataChange);
    _phone1Controller.addListener(_notifyFormDataChange);
    _phone2Controller.addListener(_notifyFormDataChange);
    _occupationController.addListener(_notifyFormDataChange);
    _loadInitialData();
    // Request focus to the name field when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
  }

  void _notifyFormDataChange() {
    if (widget.onFormDataChange != null) {
      widget.onFormDataChange!({
        'name': _nameController.text,
        'age': int.tryParse(_ageController.text),
        'gender': _selectedGender,
        'address': _addressController.text,
        'phone1': _phone1Controller.text,
        'phone2': _phone2Controller.text,
        'occupation': _occupationController.text,
        'treatingDoctorId': _treatingDoctorId,
        'departmentId': _selectedDepartmentId,
        'teamId': _selectedTeamId,
        'clinicId': _selectedClinicId,
      });
    }
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadDoctors(), _loadDepartmentsAndTeams()]);
  }

  Future<void> _loadDoctors() async {
    final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
    final clinicId = _selectedClinicId ?? ownerNotifier.clinicId;
    if (clinicId == null) return;

    setState(() => _isLoadingDoctors = true);

    final result = await sl<DoctorsUseCase>().getDoctors(clinicId: clinicId);
    result.fold(
      (failure) => debugPrint('Error loading doctors: $failure'),
      (doctors) {
        setState(() {
          _doctors = doctors;
          _isLoadingDoctors = false;

          // If scoped staff and exactly one doctor, auto-select
          if (ownerNotifier.isScoped &&
              ownerNotifier.linkedDoctorIds.length == 1 &&
              widget.patient == null) {
            final linkedId = ownerNotifier.linkedDoctorIds.first;
            final doctor = _doctors.cast<DoctorModel?>().firstWhere(
              (d) => d?.id == linkedId,
              orElse: () => null,
            );
            if (doctor != null) {
              _treatingDoctorId = doctor.id;
            }
          }
        });
      },
    );
  }

  Future<void> _loadDepartmentsAndTeams() async {
    final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
    final clinicId = _selectedClinicId ?? ownerNotifier.clinicId;
    if (clinicId == null) return;


    try {
      final deptRepo = sl<AbstractDepartmentsRepository>();
      final teamRepo = sl<AbstractCustomTeamsRepository>();

      final deptResult = await deptRepo.getDepartments(clinicId);
      final teamResult = await teamRepo.getTeamsForClinic(clinicId);

      setState(() {
        _departments = deptResult.fold(
          (f) => [],
          (list) => list.map((d) => {'id': d.id, 'name': d.name}).toList(),
        );
        _teams = teamResult.fold(
          (f) => [],
          (list) => list.map((t) => {'id': t.id, 'name': t.name}).toList(),
        );

        // Auto-select if scoped and only one
        if (ownerNotifier.isScoped && widget.patient == null) {
          if (ownerNotifier.departmentIds.length == 1 &&
              ownerNotifier.departmentIds.first != 'ALL') {
            _selectedDepartmentId = ownerNotifier.departmentIds.first;
          }
          if (ownerNotifier.teamIds.length == 1 &&
              ownerNotifier.teamIds.first != 'ALL') {
            _selectedTeamId = ownerNotifier.teamIds.first;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading metadata: $e');
    }
  }

  // Build method for the UI
  @override
  Widget build(BuildContext context) {
    final body = BlocListener<PatientsBloc, PatientsState>(
      listener: (context, state) {
        if (state is PatientsSuccess) {
          // Clear the form fields after successful addition
          _nameController.clear();
          _ageController.clear();
          _addressController.clear();
          _phone1Controller.clear();
          _phone2Controller.clear();
          _occupationController.clear();
          setState(() {
            _selectedGender = 'Male';
          });
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (context.mounted) {
            context.pop();
          }
        } else if (state is PatientsError) {
          debugPrint('SnackBar Error: ${state.message}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: SelectionArea(child: Text(state.message))));
        }
      },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Center(
              child: Container(
                width: isSmallScreen ? double.infinity : 600,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Clinic selection dropdown
                            Consumer<OwnerNotifier>(
                              builder: (context, ownerNotifier, _) {
                                final clinics = ownerNotifier.clinics;
                                if (clinics.isEmpty) {
                                  return const SizedBox();
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      value: _selectedClinicId ??
                                          ownerNotifier.clinicId,
                                      decoration: InputDecoration(
                                        labelText: 'clinic'.tr(),
                                        border: const OutlineInputBorder(),
                                      ),
                                      items: clinics.map((clinic) {
                                        return DropdownMenuItem<String>(
                                          value: clinic.id,
                                          child: Text(clinic.name),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          _selectedClinicId = newValue;
                                          _notifyFormDataChange();
                                        });
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'selectClinic'.tr();
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16.0),
                                  ],
                                );
                              },
                            ),
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              decoration: InputDecoration(
                                labelText: 'name'.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'pleaseEnterName'.tr();
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_ageFocusNode);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _ageController,
                              focusNode: _ageFocusNode,
                              decoration: InputDecoration(
                                labelText: 'age'.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'pleaseEnterAge'.tr();
                                }
                                final age = int.tryParse(value);
                                if (age == null || age < 1 || age > 120) {
                                  return 'ageMustBeBetween'.tr();
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_addressFocusNode);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _addressController,
                              focusNode: _addressFocusNode,
                              decoration: InputDecoration(
                                labelText: 'address'.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'pleaseEnterAddress'.tr();
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_phone1FocusNode);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _phone1Controller,
                              focusNode: _phone1FocusNode,
                              decoration: InputDecoration(
                                labelText: '${'phoneNumber'.tr()} 1',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'pleaseEnterPhoneNumber'.tr();
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).requestFocus(
                                  _phone2FocusNode,
                                );
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _phone2Controller,
                              focusNode: _phone2FocusNode,
                              decoration: InputDecoration(
                                labelText: '${'phoneNumber'.tr()} 2',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            const SizedBox(height: 16.0),
                            Consumer<OwnerNotifier>(
                              builder: (context, ownerNotifier, _) {
                                // List of doctors
                                final filteredDoctors = ownerNotifier.isDoctorScoped
                                    ? _doctors
                                        .where(
                                          (d) => ownerNotifier.linkedDoctorIds
                                              .contains(d.id),
                                        )
                                        .toList()
                                    : _doctors;

                                return DropdownButtonFormField<String>(
                                  value: _treatingDoctorId,
                                  decoration: InputDecoration(
                                    labelText: 'treatingDoctor'.tr(),
                                    border: const OutlineInputBorder(),
                                    hintText: _isLoadingDoctors
                                        ? 'loadingDoctors'.tr()
                                        : null,
                                  ),
                                  items: filteredDoctors.map((doctor) {
                                    return DropdownMenuItem<String>(
                                      value: doctor.id,
                                      child: Text(doctor.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _treatingDoctorId = value;
                                      _notifyFormDataChange();
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // Department Selection
                            Consumer<OwnerNotifier>(
                              builder: (context, ownerNotifier, _) {
                                final filteredDepts = _departments
                                    .where(
                                      (d) =>
                                          ownerNotifier.hasAllDepartmentsAccess ||
                                          ownerNotifier.departmentIds.contains(
                                            d['id'],
                                          ),
                                    )
                                    .toList();

                                if (filteredDepts.isEmpty &&
                                    !ownerNotifier.hasPermission(
                                      AppPermission.viewPatients,
                                    )) {
                                  return const SizedBox();
                                }

                                // Guard: only pass value if it exists in the filtered list
                                final hasSelectedDept = filteredDepts
                                    .any((d) => d['id'] == _selectedDepartmentId);

                                return DropdownButtonFormField<String>(
                                  value: hasSelectedDept ? _selectedDepartmentId : null,
                                  decoration: InputDecoration(
                                    labelText: 'department'.tr(),
                                    border: const OutlineInputBorder(),
                                    hintText: null,
                                  ),
                                  items: filteredDepts.map((dept) {
                                    return DropdownMenuItem<String>(
                                      value: dept['id'] as String,
                                      child: Text(dept['name'] as String),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedDepartmentId = value;
                                      _notifyFormDataChange();
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // Team Selection
                            Consumer<OwnerNotifier>(
                              builder: (context, ownerNotifier, _) {
                                final filteredTeams = _teams
                                    .where(
                                      (t) =>
                                          ownerNotifier.hasAllTeamsAccess ||
                                          ownerNotifier.teamIds.contains(
                                            t['id'],
                                          ),
                                    )
                                    .toList();

                                if (filteredTeams.isEmpty &&
                                    !ownerNotifier.hasPermission(
                                      AppPermission.viewPatients,
                                    )) {
                                  return const SizedBox();
                                }

                                // Guard: only pass value if it exists in the filtered list
                                final hasSelectedTeam = filteredTeams
                                    .any((t) => t['id'] == _selectedTeamId);

                                return DropdownButtonFormField<String>(
                                  value: hasSelectedTeam ? _selectedTeamId : null,
                                  decoration: InputDecoration(
                                    labelText: 'team'.tr(),
                                    border: const OutlineInputBorder(),
                                    hintText: null,
                                  ),
                                  items: filteredTeams.map((team) {
                                    return DropdownMenuItem<String>(
                                      value: team['id'] as String,
                                      child: Text(team['name'] as String),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTeamId = value;
                                      _notifyFormDataChange();
                                    });
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _occupationController,
                              focusNode: _occupationFocusNode,
                              decoration: InputDecoration(
                                labelText: 'occupation'.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              onFieldSubmitted: (_) {
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            const SizedBox(height: 16.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: Text(
                                'gender'.tr(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: ToggleButtons(
                                isSelected: [
                                  _selectedGender == 'Male',
                                  _selectedGender == 'Female',
                                ],
                                onPressed: (index) {
                                  setState(() {
                                    _selectedGender =
                                        index == 0 ? 'Male' : 'Female';
                                    _notifyFormDataChange();
                                  });
                                },
                                borderRadius: BorderRadius.circular(8.0),
                                selectedColor: Colors.white,
                                fillColor: Colors.blueAccent,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.male, size: 20),
                                        const SizedBox(width: 8),
                                        Text('male'.tr()),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.female, size: 20),
                                        const SizedBox(width: 8),
                                        Text('female'.tr()),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitForm.throttle(),
                                child: Text(
                                  widget.patient != null
                                      ? 'saveChanges'.tr()
                                      : 'addPatient'.tr(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      if (!widget.showScaffold) {
        return body;
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.patient != null ? 'editPatient'.tr() : 'addPatient'.tr(),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (widget.onCancel != null) {
                widget.onCancel!();
              } else {
                context.pop();
              }
            },
          ),
        ),
        body: body,
      );
  }

  // Method to submit the form
  Future<void> _submitForm() async {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = _selectedClinicId ?? ownerNotifier.clinicId;

      // Check if the user is authenticated and clinic/owner are available
      if (userId != null && ownerId != null && clinicId != null) {
        // Subscription Check: Only when adding a new patient
        if (widget.patient == null) {
          final subscriptionService = sl<SubscriptionService>();
          final canAdd = await subscriptionService.checkEntityLimit(
            clinicId,
            LimitType.patients,
          );

          if (!canAdd) {
            if (mounted) {
              _showUpgradeDialog(context, 'patientLimitReached'.tr());
            }
            return;
          }
        }

        const uuid = Uuid();
        final patientModel = PatientModel(
          id: widget.patient?.id ?? uuid.v4(),
          name: _nameController.text,
          age: int.tryParse(_ageController.text),
          createdAt: widget.patient?.createdAt ??
              Timestamp.fromDate(DateTime.now().toUtc()),
          gender: _selectedGender,
          address: _addressController.text,
          ownerId: ownerId,
          clinicId: clinicId,
          phone1: _phone1Controller.text.isNotEmpty
              ? _phone1Controller.text
              : null,
          phone2: _phone2Controller.text.isNotEmpty
              ? _phone2Controller.text
              : null,
          treatingDoctorId: _treatingDoctorId,
          departmentId: _selectedDepartmentId,
          teamId: _selectedTeamId,
          occupation: _occupationController.text.isNotEmpty
              ? _occupationController.text
              : null,
          createdBy: widget.patient?.createdBy,
          updatedAt: Timestamp.fromDate(DateTime.now().toUtc()),
          deletedAt: widget.patient?.deletedAt,
        );
        if (widget.patient != null) {
          if (mounted) {
            BlocProvider.of<PatientsBloc>(context).add(
              UpdatePatient(
                widget.patient!.id,
                patientModel,
              ),
            );
          }
        } else {
          if (mounted) {
            BlocProvider.of<PatientsBloc>(context)
                .add(AddPatient(patientModel));
          }
        }
      } else {
        final message = 'userIdCannotBeNull'.tr();
        debugPrint('SnackBar Error: $message');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: SelectionArea(child: Text(message))));
      }
    }
  }

  void _showUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('upgradeRequired'.tr()),
        content: SelectionArea(child: Text(message)),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: Text('cancel'.tr()),
          ),
          FilledButton(
            onPressed: () {
              context.pop();
              context.push('/settings/subscription');
            },
            child: Text('upgrade'.tr()),
          ),
        ],
      ),
    );
  }

  // Dispose method to release resources
  @override
  void dispose() {
    _nameController.removeListener(_notifyFormDataChange);
    _ageController.removeListener(_notifyFormDataChange);
    _addressController.removeListener(_notifyFormDataChange);
    _phone1Controller.removeListener(_notifyFormDataChange);
    _phone2Controller.removeListener(_notifyFormDataChange);
    _occupationController.removeListener(_notifyFormDataChange);

    // Dispose the controllers
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _phone1Controller.dispose();
    _phone2Controller.dispose();
    _occupationController.dispose();
    // Dispose the focus nodes
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _genderFocusNode.dispose();
    _addressFocusNode.dispose();
    _phone1FocusNode.dispose();
    _phone2FocusNode.dispose();
    _occupationFocusNode.dispose();
    super.dispose();
  }
}
