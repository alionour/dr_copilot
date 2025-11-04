import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class AddEditDoctorPage extends StatefulWidget {
  final String? doctorId;

  const AddEditDoctorPage({super.key, this.doctorId});

  @override
  State<AddEditDoctorPage> createState() => _AddEditDoctorPageState();
}

class _AddEditDoctorPageState extends State<AddEditDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  static const List<String> _specialties = [
    'General Practice',
    'Pediatrics',
    'Internal Medicine',
    'Surgery',
    'Obstetrics and Gynecology',
    'Cardiology',
    'Dermatology',
    'Neurology',
    'Orthopedics',
    'Ophthalmology',
    'Psychiatry',
    'Radiology',
    'Anesthesiology',
    'Urology',
    'Endocrinology',
    'Gastroenterology',
    'Nephrology',
    'Pulmonology',
    'Oncology',
    'Emergency Medicine',
    'Physical Therapy',
  ];

  String? _selectedSpecialty;

  String? _selectedClinicId;
  DoctorModel? _initialDoctor;

  bool get isEditing => widget.doctorId != null;

  @override
  void initState() {
    super.initState();
    final clinics = OwnerNotifier().clinics;
    if (clinics.isNotEmpty) {
      _selectedClinicId = clinics.first.id;
    }

    if (isEditing) {
      // Fetch doctor details if in editing mode
      context.read<DoctorsBloc>().add(const GetDoctors()); // Fetch all doctors to find the one to edit
    }
    _selectedSpecialty = _initialDoctor?.specialty;
  }

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _saveDoctor() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('selectClinic'.tr())),
        );
        return;
      }
      if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pleaseSelectSpecialty'.tr())),
        );
        return;
      }

      final now = Timestamp.fromDate(DateTime.now().toUtc());


      final doctor = DoctorModel(
        id: isEditing ? _initialDoctor!.id : const Uuid().v4(),
        name: _nameController.text,
        specialty: _selectedSpecialty!,
        email: _emailController.text,
        phoneNumber: _phoneNumberController.text,
        clinicId: _selectedClinicId!,
        createdAt: isEditing ? _initialDoctor!.createdAt : now,
        updatedAt: now,
      );

      if (isEditing) {
        context.read<DoctorsBloc>().add(UpdateDoctor(doctor.id, doctor));
      } else {
        context.read<DoctorsBloc>().add(AddDoctor(doctor));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'editDoctor'.tr() : 'addDoctor'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/doctors');
          },
        ),
      ),
      body: BlocListener<DoctorsBloc, DoctorsState>(
        listener: (context, state) {
          if (isEditing && state is DoctorsLoaded) {
            final doctor = state.doctors.firstWhere(
              (doc) => doc.id == widget.doctorId,
              orElse: () => throw Exception('Doctor not found'),
            );
            setState(() {
              _initialDoctor = doctor;
              _nameController.text = doctor.name;
              _selectedSpecialty = doctor.specialty;
              _emailController.text = doctor.email;
              _phoneNumberController.text = doctor.phoneNumber;
              _selectedClinicId = doctor.clinicId;
            });
          } else if (state is DoctorsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Success'.tr())),
            );
            context.go('/doctors');
          } else if (state is DoctorsError) {
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
                          items: OwnerNotifier().clinics.map((clinic) {
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
                          value: _selectedSpecialty,
                          decoration: InputDecoration(
                            labelText: 'specialty'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          items: _specialties.map((String specialty) {
                            return DropdownMenuItem<String>(
                              value: specialty,
                              child: Text(specialty.tr()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSpecialty = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'pleaseSelectSpecialty'.tr();
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
                            if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
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
                            onPressed: _saveDoctor,
                            child: Text('saveDoctor'.tr()),
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
