import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';
import 'package:dr_copilot/src/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

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
        _emailController.text = staff.email ?? '';
        _phoneNumberController.text = staff.phoneNumber ?? '';
        _selectedClinicId = staff.clinicId;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('selectClinic'.tr())),
        );
        return;
      }
      if (_selectedRole == null || _selectedRole!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pleaseSelectRole'.tr())),
        );
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
      );

      if (isEditing) {
        context.read<StaffBloc>().add(UpdateStaff(staff.id, staff));
      } else {
        context.read<StaffBloc>().add(AddStaff(staff));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'editStaff'.tr() : 'addStaff'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: BlocListener<StaffBloc, StaffState>(
        listener: (context, state) {
          if (state is StaffSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Success'.tr())),
            );
            context.pop();
          } else if (state is StaffError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Error'.tr())),
            );
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
                          value: _selectedClinicId,
                          decoration: InputDecoration(
                            labelText: 'clinic'.tr(),
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          items: context
                              .watch<OwnerNotifier>()
                              .clinics
                              .map((clinic) {
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
                          value: _selectedRole,
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
                                    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                                .hasMatch(value)) {
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveStaff,
                            child: Text('saveStaff'.tr()),
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
