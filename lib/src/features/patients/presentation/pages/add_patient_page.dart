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
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/departments/domain/repositories/abstract_departments_repository.dart';
import 'package:dr_copilot/src/features/teams/domain/repositories/abstract_custom_teams_repository.dart';

// AddPatientPage StatefulWidget
class AddPatientPage extends StatefulWidget {
  final PatientModel? patient;
  // Constructor for AddPatientPage
  const AddPatientPage({super.key, this.patient});

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
  final _phoneNumberController = TextEditingController();
  final _alternativePhoneNumberController = TextEditingController();
  final _treatingDoctorController = TextEditingController();
  final _occupationController = TextEditingController();

  // Focus nodes for form fields
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _genderFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _alternativePhoneNumberFocusNode = FocusNode();
  final _treatingDoctorFocusNode = FocusNode();
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
      _phoneNumberController.text = widget.patient!.phoneNumber ?? '';
      _alternativePhoneNumberController.text =
          widget.patient!.alternativePhoneNumber ?? '';
      _treatingDoctorController.text = widget.patient!.treatingDoctor ?? '';
      _treatingDoctorId = widget.patient!.treatingDoctorId;
      _occupationController.text = widget.patient!.occupation ?? '';
      _selectedGender = widget.patient!.gender ?? 'Male';
      _selectedClinicId = widget.patient!.clinicId;
      _selectedDepartmentId = widget.patient!.departmentId;
      _selectedTeamId = widget.patient!.teamId;
    }
    _loadInitialData();
    // Request focus to the name field when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
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
              _treatingDoctorController.text = doctor.name;
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
          if (ownerNotifier.departmentIds.length == 1) {
            _selectedDepartmentId = ownerNotifier.departmentIds.first;
          }
          if (ownerNotifier.teamIds.length == 1) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patient != null ? 'editPatient'.tr() : 'addPatient'.tr(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: BlocListener<PatientsBloc, PatientsState>(
        listener: (context, state) {
          if (state is PatientsSuccess) {
            // Clear the form fields after successful addition
            _nameController.clear();
            _ageController.clear();
            _addressController.clear();
            _phoneNumberController.clear();
            _alternativePhoneNumberController.clear();
            _treatingDoctorController.clear();
            _occupationController.clear();
            setState(() {
              _selectedGender = 'Male';
            });
            if (context.mounted) context.pop();
          } else if (state is PatientsError) {
            debugPrint('SnackBar Error: ${state.message}');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
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
                                ).requestFocus(_phoneNumberFocusNode);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _phoneNumberController,
                              focusNode: _phoneNumberFocusNode,
                              decoration: InputDecoration(
                                labelText: 'phoneNumber'.tr(),
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
                                  _alternativePhoneNumberFocusNode,
                                );
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _alternativePhoneNumberController,
                              focusNode: _alternativePhoneNumberFocusNode,
                              decoration: InputDecoration(
                                labelText: 'alternativePhoneNumber'.tr(),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onFieldSubmitted: (_) {
                                FocusScope.of(
                                  context,
                                ).requestFocus(_treatingDoctorFocusNode);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            Consumer<OwnerNotifier>(
                              builder: (context, ownerNotifier, _) {
                                if (ownerNotifier.isDoctorScoped) {
                                  // Scoped staff member
                                  final linkedDoctorIds =
                                      ownerNotifier.linkedDoctorIds;
                                  final filteredDoctors = _doctors
                                      .where(
                                        (d) =>
                                            linkedDoctorIds.isEmpty ||
                                            linkedDoctorIds.contains(d.id),
                                      )
                                      .toList();

                                  return DropdownButtonFormField<String>(
                                    initialValue: _treatingDoctorId,
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
                                        final doctor = _doctors.firstWhere(
                                          (d) => d.id == value,
                                        );
                                        _treatingDoctorController.text =
                                            doctor.name;
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'pleaseSelectDoctor'.tr();
                                      }
                                      return null;
                                    },
                                  );
                                } else {
                                  // Non-scoped user (Doctor, Admin, or staff with viewAllPatients)
                                  return TextFormField(
                                    controller: _treatingDoctorController,
                                    focusNode: _treatingDoctorFocusNode,
                                    decoration: InputDecoration(
                                      labelText: 'treatingDoctor'.tr(),
                                      border: const OutlineInputBorder(),
                                    ),
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(_occupationFocusNode);
                                    },
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16.0),
                            // Department Selection
                            Consumer<OwnerNotifier>(
                              builder: (context, ownerNotifier, _) {
                                final filteredDepts = _departments
                                    .where(
                                      (d) =>
                                          ownerNotifier.departmentIds.isEmpty ||
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

                                return DropdownButtonFormField<String>(
                                  value: _selectedDepartmentId,
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
                                    setState(() => _selectedDepartmentId = value);
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
                                          ownerNotifier.teamIds.isEmpty ||
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

                                return DropdownButtonFormField<String>(
                                  value: _selectedTeamId,
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
                                    setState(() => _selectedTeamId = value);
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
                                onPressed: _submitForm,
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
      ),
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
          id: uuid.v4(), // Generate a unique ID
          name: _nameController.text,
          age: int.tryParse(_ageController.text),
          createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
          gender: _selectedGender,
          address: _addressController.text,
          ownerId: ownerId,
          clinicId: clinicId,
          phoneNumber: _phoneNumberController.text.isNotEmpty
              ? _phoneNumberController.text
              : null,
          alternativePhoneNumber:
              _alternativePhoneNumberController.text.isNotEmpty
                  ? _alternativePhoneNumberController.text
                  : null,
          treatingDoctor: _treatingDoctorController.text.isNotEmpty
              ? _treatingDoctorController.text
              : null,
          treatingDoctorId: _treatingDoctorId,
          departmentId: _selectedDepartmentId,
          teamId: _selectedTeamId,
          occupation: _occupationController.text.isNotEmpty
              ? _occupationController.text
              : null,
        );
        if (widget.patient != null) {
          if (mounted) {
            BlocProvider.of<PatientsBloc>(context).add(
              UpdatePatient(
                widget.patient!.id,
                patientModel.copyWith(id: widget.patient!.id),
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
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  void _showUpgradeDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('upgradeRequired'.tr()),
        content: Text(message),
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
    // Dispose the controllers
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _alternativePhoneNumberController.dispose();
    _treatingDoctorController.dispose();
    _occupationController.dispose();
    // Dispose the focus nodes
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _genderFocusNode.dispose();
    _addressFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _alternativePhoneNumberFocusNode.dispose();
    _treatingDoctorFocusNode.dispose();
    _occupationFocusNode.dispose();
    super.dispose();
  }
}
