import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/financials/presentation/bloc/financials_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/auth/domain/services/permission_service.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

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
  final _appointmentDurationController = TextEditingController();
  final _consultationPriceController = TextEditingController();

  bool _canEditSchedule = false;
  bool _canManageBookingAvailability = false;
  bool _isAvailableForBooking = true;
  String? _selectedCurrencyProfileId;
  Map<String, Map<String, dynamic>> _workingHours = {
    'monday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'tuesday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'wednesday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'thursday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'friday': {'active': true, 'start': '09:00', 'end': '17:00'},
    'saturday': {'active': false, 'start': '10:00', 'end': '14:00'},
    'sunday': {'active': false, 'start': '10:00', 'end': '14:00'},
  };

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
      context.read<DoctorsBloc>().add(GetDoctors(
          clinicId:
              _selectedClinicId)); // Fetch doctors for the specific clinic
    }
    _selectedSpecialty = _initialDoctor?.specialty;

    // Check permissions
    try {
      _canEditSchedule = sl<PermissionService>()
          .hasPermissionSync(AppPermission.manageWorkingHours);
      _canManageBookingAvailability = sl<PermissionService>()
          .hasPermissionSync(AppPermission.manageBookingAvailability);
    } catch (e) {
      debugPrint('Permission check failed: $e');
      _canEditSchedule = false;
      _canManageBookingAvailability = false;
    }

    // Fetch currency profiles
    context.read<FinancialsBloc>().add(FetchCurrencyProfiles());

    if (_initialDoctor != null) {
      _loadScheduleFromDoctor(_initialDoctor!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();
    _phoneNumberController.dispose();
    _appointmentDurationController.dispose();
    _consultationPriceController.dispose();
    super.dispose();
  }

  void _saveDoctor() {
    if (_formKey.currentState!.validate()) {
      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('selectClinic'.tr()))),
        );
        return;
      }
      if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: SelectionArea(child: Text('pleaseSelectSpecialty'.tr()))),
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
        workingHours: _workingHours,
        appointmentDuration: int.tryParse(_appointmentDurationController.text),
        consultationPrice: double.tryParse(_consultationPriceController.text),
        isAvailableForBooking: _isAvailableForBooking,
        currencyProfileId: _selectedCurrencyProfileId,
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
    final hasManagePermission = OwnerNotifier().hasPermission(AppPermission.manageDoctors);

    if (!hasManagePermission) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'editDoctor'.tr() : 'addDoctor'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop();
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.gpp_bad_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'notAuthorized'.tr(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'editDoctor'.tr() : 'addDoctor'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
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
              _isAvailableForBooking = doctor.isAvailableForBooking;
              _selectedCurrencyProfileId = doctor.currencyProfileId;
              _loadScheduleFromDoctor(doctor);
            });
          } else if (state is DoctorsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectionArea(child: Text(state.message ?? 'success'.tr()))),
            );
            if (isEditing) {
              if (context.mounted) context.pop();
            } else {
              _nameController.clear();
              _emailController.clear();
              _phoneNumberController.clear();
              setState(() {
                _selectedSpecialty = null;
              });
            }
          } else if (state is DoctorsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: SelectionArea(child: Text(state.message ?? 'anErrorOccurred'.tr()))),
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
                        if (_canManageBookingAvailability)
                          SwitchListTile(
                            title: Text('availableForBooking'.tr()),
                            subtitle: Text('availableForBookingDesc'.tr()),
                            value: _isAvailableForBooking,
                            onChanged: (val) {
                              setState(() {
                                _isAvailableForBooking = val;
                              });
                            },
                          ),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClinicId,
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
                          initialValue: _selectedSpecialty,
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

                        // Schedule Section
                        if (_canEditSchedule) ...[
                          Text(
                            'workingHours'.tr(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _appointmentDurationController,
                                  decoration: InputDecoration(
                                    labelText: 'appointmentDurationMin'.tr(),
                                    border: const OutlineInputBorder(),
                                    suffixText: 'min',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: BlocBuilder<FinancialsBloc,
                                    FinancialsState>(
                                  builder: (context, state) {
                                    // Default to clinic currency if no profile selected or profiles loaded
                                    final profiles = state.currencyProfiles;
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller:
                                                _consultationPriceController,
                                            decoration: InputDecoration(
                                              labelText:
                                                  'consultationPrice'.tr(),
                                              border:
                                                  const OutlineInputBorder(),
                                              suffixText: _selectedCurrencyProfileId !=
                                                      null
                                                  ? profiles
                                                      .firstWhere(
                                                          (p) =>
                                                              p.id ==
                                                              _selectedCurrencyProfileId,
                                                          orElse: () =>
                                                              CurrencyProfileModel(
                                                                  id: '',
                                                                  currency: '',
                                                                  name: '',
                                                                  createdAt:
                                                                      Timestamp
                                                                          .now(),
                                                                  createdBy:
                                                                      ''))
                                                      .currency
                                                  : '',
                                            ),
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                                decimal: true),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 100,
                                          child:
                                              DropdownButtonFormField<String>(
                                            initialValue:
                                                _selectedCurrencyProfileId,
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              labelText: 'currency'.tr(),
                                              border:
                                                  const OutlineInputBorder(),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 16),
                                            ),
                                            items: profiles.map((profile) {
                                              return DropdownMenuItem<String>(
                                                value: profile.id,
                                                child: Text(
                                                  profile.currency,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                _selectedCurrencyProfileId =
                                                    val;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
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
                                                initialTime: _parseTime(
                                                    schedule['start']),
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
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 16.0),
                        ],
                        const SizedBox(height: 16.0),
                        SizedBox(
                          width: double.infinity,
                          child: BlocBuilder<DoctorsBloc, DoctorsState>(
                            builder: (context, state) {
                              if (state is DoctorsLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              return ElevatedButton(
                                onPressed: _saveDoctor,
                                child: Text('saveDoctor'.tr()),
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

  void _loadScheduleFromDoctor(DoctorModel doctor) {
    if (doctor.workingHours != null) {
      _workingHours = Map<String, Map<String, dynamic>>.from(
          doctor.workingHours!.map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value))));
    }
    if (doctor.appointmentDuration != null) {
      _appointmentDurationController.text =
          doctor.appointmentDuration.toString();
    }
    if (doctor.consultationPrice != null) {
      _consultationPriceController.text = doctor.consultationPrice.toString();
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
