import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';
import 'package:dr_copilot/src/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/core/helper/safe_click.dart';


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/staff/data/remote/staff_firebase_api.dart';
import 'package:dr_copilot/src/features/staff/data/repositories/staff_repository_impl.dart';
import 'package:dr_copilot/src/features/staff/domain/usecases/staff_usecase.dart';
import 'package:uuid/uuid.dart';

class AddEditStaffPage extends StatelessWidget {
  final String? staffId;

  const AddEditStaffPage({super.key, this.staffId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          StaffBloc(StaffUseCases(StaffRepositoryImpl(StaffFirebaseApi()))),
      child: AddEditStaffForm(staffId: staffId),
    );
  }
}

class AddEditStaffForm extends StatefulWidget {
  final String? staffId;

  const AddEditStaffForm({super.key, this.staffId});

  @override
  State<AddEditStaffForm> createState() => _AddEditStaffFormState();
}

class _AddEditStaffFormState extends State<AddEditStaffForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  static const List<String> _roles = [
    'Nurse',
    'Receptionist',
    'Administrator',
    'Therapist',
    'Technician',
  ];

  String? _selectedRole;
  String? _selectedClinicId;
  StaffModel? _initialStaff;



  // Default schedule: Mon-Fri 9-5
  Map<String, Map<String, dynamic>> _workingHours = {
    'monday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'tuesday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'wednesday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'thursday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'friday': {'active': false, 'start': '09:00', 'end': '17:00'},
    'saturday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'sunday': {'active': true, 'start': '09:00', 'end': '17:00'},
  };

  bool get isEditing => widget.staffId != null;

  @override
  void initState() {
    super.initState();
    final clinics = context.read<OwnerNotifier>().clinics;
    if (clinics.isNotEmpty) {
      _selectedClinicId = clinics.first.id;
    }

    if (isEditing) {
      // Fetch staff details if in editing mode
      final clinicId = context.read<OwnerNotifier>().clinicId;
      if (clinicId != null) {
        context.read<StaffBloc>().add(GetStaff(clinicId: clinicId));
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isEditing) {
      final staffState = context.watch<StaffBloc>().state;
      if (staffState is StaffLoaded) {
        final staff = staffState.staff.firstWhere(
          (s) => s.id == widget.staffId,
          orElse: () => throw Exception('Staff not found'),
        );
        _initialStaff = staff;
        _nameController.text = staff.name;
        _selectedRole = staff.role;
        _emailController.text = staff.email;
        _phoneNumberController.text = staff.phoneNumber ?? '';
        _selectedClinicId = staff.clinicId;
        if (staff.workingHours != null) {
          _workingHours = Map<String, Map<String, dynamic>>.from(
            staff.workingHours!.map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
            ),
          );
        }

      }
    }
    _selectedRole = _initialStaff?.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();

    super.dispose();
  }

  void _saveStaff() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        debugPrint('SnackBar Error: ${'selectClinic'.tr()}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: SelectionArea(child: Text('selectClinic'.tr()))));
        return;
      }
      if (_selectedRole == null || _selectedRole!.isEmpty) {
        debugPrint('SnackBar Error: ${'pleaseSelectRole'.tr()}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: SelectionArea(child: Text('pleaseSelectRole'.tr()))));
        return;
      }

      final now = DateTime.now().toUtc();

      final staff = StaffModel(
        id: isEditing ? _initialStaff!.id : const Uuid().v4(),
        name: _nameController.text,
        role: _selectedRole!,
        email: _emailController.text,
        phoneNumber: _phoneNumberController.text,
        clinicId: _selectedClinicId!,
        createdAt: isEditing ? _initialStaff!.createdAt : now,
        updatedAt: now,
        workingHours: _workingHours,
      );

      if (isEditing) {
        context.read<StaffBloc>().add(UpdateStaff(staff.id, staff));
      } else {
        context.read<StaffBloc>().add(AddStaff(staff));
      }
    }
  }

  void _applyToAll(String start, String end) {
    setState(() {
      for (var day in _workingHours.keys) {
        _workingHours[day]!['start'] = start;
        _workingHours[day]!['end'] = end;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: SelectionArea(child: Text('appliedToAllDays'.tr()))),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'editStaff'.tr() : 'addStaff'.tr()),
        leading: IconButton(
          icon: Icon(Icons.adaptive.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/staff');
            }
          },
        ),
      ),
      body: BlocListener<StaffBloc, StaffState>(
        listener: (context, state) {
          if (state is StaffSuccess) {
            final message = state.message ?? 'success'.tr();
            debugPrint('SnackBar Success: $message');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: SelectionArea(child: Text(message))));
            if (isEditing) {
              if (context.mounted) {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/staff');
                }
              }
            } else {
              _nameController.clear();
              _emailController.clear();
              _phoneNumberController.clear();
              setState(() {
                _selectedRole = null;
              });
            }
          } else if (state is StaffError) {
            final message = state.message ?? 'anErrorOccurred'.tr();
            debugPrint('SnackBar Error: $message');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: SelectionArea(child: Text(message))));
          }
        },
        child: Center(
          child: Container(
            width: 600,
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
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClinicId,
                          decoration: InputDecoration(
                            labelText: 'clinic'.tr(),
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          items: context.watch<OwnerNotifier>().clinics.map((
                            clinic,
                          ) {
                            return DropdownMenuItem<String>(
                              value: clinic.id,
                              child: Text(clinic.name),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              if (newValue != null) {
                                _selectedClinicId = newValue;
                              }
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
                        TextFormField(
                          controller: _nameController,
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
                        ),
                        const SizedBox(height: 16.0),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'role'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          items: _roles.map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(role.tr()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRole = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'pleaseSelectRole'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'email'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'pleaseEnterEmail'.tr();
                            }
                            if (!RegExp(
                              r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                            ).hasMatch(value)) {
                              return 'enterValidEmail'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            labelText: 'phoneNumber'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'pleaseEnterPhoneNumber'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),

                        // Schedule Section
                        Text(
                          'workingHours'.tr(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ..._workingHours.keys.map((day) {
                          final schedule = _workingHours[day]!;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Switch(
                                        value: schedule['active'],
                                        onChanged: (val) {
                                          setState(() {
                                            schedule['active'] = val;
                                          });
                                        },
                                      ),
                                      Text(day.tr()),
                                      const Spacer(),
                                      if (schedule['active']) ...[
                                        TextButton(
                                          onPressed: () async {
                                            final time = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  _parseTime(schedule['start']),
                                            );
                                            if (time != null) {
                                              setState(() {
                                                schedule['start'] =
                                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                              });
                                            }
                                          },
                                          child: Text(schedule['start']),
                                        ),
                                        const Text('-'),
                                        TextButton(
                                          onPressed: () async {
                                            final time = await showTimePicker(
                                              context: context,
                                              initialTime:
                                                  _parseTime(schedule['end']),
                                            );
                                            if (time != null) {
                                              setState(() {
                                                schedule['end'] =
                                                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                              });
                                            }
                                          },
                                          child: Text(schedule['end']),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.copy_all, size: 20),
                                          onPressed: () => _applyToAll(
                                            schedule['start'],
                                            schedule['end'],
                                          ),
                                          tooltip: 'applyToAll'.tr(),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 16.0),
                        SizedBox(
                          width: double.infinity,
                          child: BlocBuilder<StaffBloc, StaffState>(
                            builder: (context, state) {
                              if (state is StaffLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return ElevatedButton(
                                onPressed: _saveStaff.throttle(),
                                child: Text('saveStaff'.tr()),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
