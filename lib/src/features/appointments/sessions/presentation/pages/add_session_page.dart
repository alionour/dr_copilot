import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class AddSessionPage extends StatefulWidget {
  final SessionModel? session;
  const AddSessionPage({super.key, this.session});

  @override
  State<AddSessionPage> createState() => _AddSessionPageState();
}

class _AddSessionPageState extends State<AddSessionPage> {
  // Clinic selection fields
  String? _selectedClinicId;
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientNameFocusNode = FocusNode();
  final _actualPriceFocusNode = FocusNode();
  Timestamp? _startDate = Timestamp.fromDate(
    DateTime.now(),
  ); // Initialize with the current date
  Timestamp? _endDate = Timestamp.fromDate(
    DateTime.now().add(const Duration(hours: 1)),
  ); // Initialize with the current date + 1 hour
  String _selectedCalendar = 'Sessions'; // Default calendar matches the list
  String query = '';
  final FocusNode _searchFocusNode = FocusNode();
  List<PatientModel> _filteredPatients = [];
  String _selectedSessionType =
      SessionTypePresets.standard; // Default session type
  PatientModel? _selectedPatient; // Add a field to store the selected patient
  final _customSessionTypeController = TextEditingController();

  final List<String> _calendars = ['Sessions'];

  double _estimatedPrice = SessionTypePresets.basePrices[
      SessionTypePresets.standard]!; // Default estimated price for 'Standard'
  final _actualPriceController = TextEditingController();

  CurrencyProfileModel? _selectedCurrencyProfile;

  List<CurrencyProfileModel> _currencyProfiles = [];

  InvoiceStatus?
      _selectedInvoiceStatus; // Add a field to store the selected invoice status

  // Add a TextEditingController for the partial payment amount
  final _partialPaymentController = TextEditingController();

  DoctorModel? _selectedDoctor;
  List<DoctorModel> _doctors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_patientNameFocusNode);
      _fetchCurrencyProfiles(); // Fetch currency profiles on init
      context.read<DoctorsBloc>().add(
            const GetDoctors(),
          ); // Fetch doctors on init
    });
    context.read<PatientsBloc>().add(
          const GetPatients(),
        ); // Fetch patients on init

    if (widget.session != null) {
      _selectedClinicId = widget.session!.clinicId;
      _startDate = widget.session!.startDateTime;
      _endDate = widget.session!.endDateTime;
      _selectedSessionType =
          widget.session!.sessionType ?? SessionTypePresets.standard;

      // Check if the loaded type is one of the presets
      if (!SessionTypePresets.values.contains(_selectedSessionType)) {
        // If not a preset, it's a custom type.
        // But wait, our logic says we select "Custom" in dropdown and type the name in text field.
        // So if it's not a preset, we should set dropdown to 'Custom' and text field to the value.
        _customSessionTypeController.text = _selectedSessionType;
        _selectedSessionType = SessionTypePresets.custom;
      }

      _actualPriceController.text = widget.session!.price.toString();
      _patientNameController.text = widget.session!.patientName ?? '';
      // We need to set _selectedPatient. Since we only have ID and Name in SessionModel,
      // we might need to fetch the full patient or create a dummy one if we just need ID.
      // For now, let's create a partial model sufficient for validation.
      _selectedPatient = PatientModel(
        id: widget.session!.patientId,
        name: widget.session!.patientName ?? '',
        ownerId: widget.session!.ownerId,
        clinicId: widget.session!.clinicId,
      );
      // _selectedDoctor will be set when doctors are loaded if we match the ID
    } else {
      final clinics = OwnerNotifier().clinics;
      if (clinics.isNotEmpty) {
        _selectedClinicId = clinics.first.id;
      }
    }
  }

  Future<void> _fetchCurrencyProfiles() async {
    try {
      final failureOrProfiles =
          await context.read<SessionsBloc>().getCurrencyProfiles();
      if (!mounted) return;
      failureOrProfiles.fold(
        (failure) {
          debugPrint('Failed to fetch currency profiles: ${failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('failedToFetchCurrencyProfiles'.tr())),
          );
        },
        (profiles) {
          debugPrint(
            'Fetched currency profiles: ${profiles.map((p) => p.name).toList()}',
          );
          setState(() {
            _currencyProfiles = profiles.map((profile) => profile).toList();
          });
        },
      );
    } catch (e) {
      debugPrint('Error in _fetchCurrencyProfiles: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('failedToFetchCurrencyProfiles'.tr())),
      );
    }
    if (_currencyProfiles.isNotEmpty) {
      _selectedCurrencyProfile ??= _currencyProfiles
          .first; // Set the first profile as default if none is selected
    }
  }

  String? _validateTime() {
    if (_endDate!.toDate().isBefore(_startDate!.toDate())) {
      return 'endTimeAfterStartTime'.tr();
    }
    final duration =
        _endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0;
    if (duration > 4.0) {
      return 'maximumAllowedDuration'.tr();
    }
    return null;
  }

  void _updateEstimatedPrice() {
    final duration =
        _endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0;

    if (_selectedSessionType == SessionTypePresets.custom) {
      _estimatedPrice = 0.0; // Or keep previous? Let's say 0 for custom.
    } else if (SessionTypePresets.basePrices.containsKey(
      _selectedSessionType,
    )) {
      final basePrice = SessionTypePresets.basePrices[_selectedSessionType]!;
      // Apply specific logic if needed, or just basePrice * duration
      // The previous logic had specific multipliers. Let's replicate them if possible or simplify.
      // Previous logic:
      // Adult Intensive: duration <= 1.0 ? 150 : 200
      // Pediatric: 100 * duration
      // Traction: 150 * duration
      // Standard: 120 * duration

      if (_selectedSessionType == SessionTypePresets.adultIntensive) {
        _estimatedPrice = duration <= 1.0 ? 150.0 : 200.0;
      } else {
        _estimatedPrice = basePrice * duration;
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initialDate =
        isStart ? _startDate!.toDate() : _endDate!.toDate();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      if (!mounted) return;
      setState(() {
        if (isStart) {
          _startDate = Timestamp.fromDate(
            DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              _startDate?.toDate().hour ?? 0,
              _startDate?.toDate().minute ?? 0,
            ),
          );
        } else {
          _endDate = Timestamp.fromDate(
            DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              _endDate?.toDate().hour ?? 0,
              _endDate?.toDate().minute ?? 0,
            ),
          );
        }
      });
      if (!context.mounted) return;

      await _selectTime(context, isStart); // Automatically move to time picker
    }
  }

  DateTime _roundToNearestHalfHour(DateTime dateTime) {
    final int minute = dateTime.minute;
    final int roundedMinute = (minute < 15)
        ? 0
        : (minute < 45)
            ? 30
            : 0;
    final int hour = (minute >= 45) ? dateTime.hour + 1 : dateTime.hour;
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      hour,
      roundedMinute,
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final DateTime initialDate =
        isStart ? _startDate!.toDate() : _endDate!.toDate();
    final TimeOfDay initialTime = TimeOfDay.fromDateTime(initialDate);

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      if (!mounted) return;
      setState(() {
        final DateTime selectedDateTime = DateTime(
          initialDate.year,
          initialDate.month,
          initialDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        final roundedDateTime = _roundToNearestHalfHour(selectedDateTime);
        if (isStart) {
          _startDate = Timestamp.fromDate(roundedDateTime);
          _endDate = _endDate!.toDate().isBefore(_startDate!.toDate())
              ? Timestamp.fromDate(
                  _startDate!.toDate().add(const Duration(hours: 1)),
                )
              : _endDate;
        } else {
          _endDate = Timestamp.fromDate(roundedDateTime);
        }
        _updateEstimatedPrice(); // Update price when time changes
      });
    }
  }

  void _detectSessionTypeForPatient(String patientId) {
    context.read<SessionsBloc>().add(DetectSessionType(patientId));
  }

  Future<void> _saveSession() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatient == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('pleaseSelectPatient'.tr())));
        return;
      }

      // Ensure `_selectedCurrencyProfile` is non-null before proceeding
      if (_selectedCurrencyProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select a currency profile before adding a session.',
            ),
          ),
        );
        return;
      }

      // Ensure a clinic is selected
      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a clinic.')));
        return;
      }

      // Ensure invoice status is selected
      if (_selectedInvoiceStatus == null && widget.session == null) {
        // Only check invoice status for new sessions
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an invoice status.')),
        );
        return;
      }

      // Subscription Check: Only when adding a new session
      if (widget.session == null) {
        final subscriptionService = sl<SubscriptionService>();
        final canAdd = await subscriptionService.checkEntityLimit(
          _selectedClinicId!,
          LimitType.sessions,
        );

        if (!canAdd) {
          if (!mounted) return;
          _showUpgradeDialog(context, 'sessionLimitReached'.tr());
          return;
        }
        if (!mounted) return;
      }

      String finalSessionType = _selectedSessionType;
      if (_selectedSessionType == SessionTypePresets.custom) {
        if (_customSessionTypeController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please enter a custom session type name.')),
          );
          return;
        }
        finalSessionType = _customSessionTypeController.text;
      }

      final now = Timestamp.fromDate(DateTime.now().toUtc());

      final session = SessionModel(
        id: widget.session?.id ?? const Uuid().v4(),
        patientId: _selectedPatient!.id, // Use the selected patient's ID
        patientName:
            _selectedPatient!.name, // Include the selected patient's name
        startDateTime: _startDate!,
        endDateTime: _endDate!,
        createdAt: widget.session?.createdAt ?? now,
        sessionType: finalSessionType,
        price: double.parse(_actualPriceController.text),
        ownerId: widget.session?.ownerId ??
            FirebaseAuth.instance.currentUser?.uid ??
            '',
        clinicId: _selectedClinicId!,
        createdBy: widget.session?.createdBy ??
            FirebaseAuth.instance.currentUser?.uid ??
            '',
        doctorId: _selectedDoctor?.id, // Add the selected doctor's ID
      );

      if (widget.session != null) {
        if (!mounted) return;
        context.read<SessionsBloc>().add(UpdateSession(session.id, session));
      } else {
        if (!mounted) return;
        context.read<SessionsBloc>().add(
              AddSession(
                session,
                invoiceStatus: _selectedInvoiceStatus!,
                currencyProfileId: _selectedCurrencyProfile!.id,
              ),
            );
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
              context.push('/subscription_pricing');
            },
            child: Text('upgrade'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _partialPaymentController.dispose();
    _patientNameFocusNode.dispose();
    _patientNameController.dispose();
    _actualPriceFocusNode.dispose();
    _actualPriceController.dispose();
    _customSessionTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if (_currencyProfiles.isEmpty) {
    //   return Center(
    //     child: Text(
    //       'No currency profiles available. Please create one.',
    //       style: Theme.of(context)
    //           .textTheme
    //           .bodyMedium
    //           ?.copyWith(color: Colors.red),
    //     ),
    //   );
    // }
    return Scaffold(
      // floatingActionButton: FloatingActionButton(onPressed: () {
      //     context.read<SessionsBloc>().processSessions(context);
      //     context.read<SessionsBloc>().processEvaluations(context);
      //   }),
      appBar: AppBar(
        title: Text(
          widget.session != null ? 'Edit Session' : 'addSession'.tr(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop(); // Navigate back to previous route
          },
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<PatientsBloc, PatientsState>(
            listener: (context, state) {
              if (state is PatientsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } else if (state is PatientsError) {
                final message = state.message;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
              }
            },
          ),
          BlocListener<SessionsBloc, SessionsState>(
            listener: (context, state) {
              if (state is SessionsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } else if (state is SessionsError) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              } else if (state is SessionTypeDetected) {
                setState(() {
                  _selectedSessionType = state.sessionType;
                });
              }
            },
          ),
          BlocListener<DoctorsBloc, DoctorsState>(
            listener: (context, state) {
              if (state is DoctorsLoaded) {
                setState(() {
                  _doctors = state.doctors;
                  if (_doctors.isNotEmpty && _selectedDoctor == null) {
                    if (widget.session != null &&
                        widget.session!.doctorId != null) {
                      try {
                        _selectedDoctor = _doctors.firstWhere(
                          (d) => d.id == widget.session!.doctorId,
                        );
                      } catch (e) {
                        // Doctor not found in list
                      }
                    }
                    _selectedDoctor ??= _doctors.first;
                  }
                });
              } else if (state is DoctorsError) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(message)));
                }
              }
            },
          ),
        ],
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
                              items: OwnerNotifier().clinics.map((clinic) {
                                return DropdownMenuItem<String>(
                                  value: clinic.id,
                                  child: Text(
                                    clinic.name,
                                  ), // Replace with clinic name if available
                                );
                              }).toList(),
                              onChanged: widget.session != null
                                  ? null // Disable if editing
                                  : (String? newValue) {
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
                            const SizedBox(height: 8.0),
                            DropdownButtonFormField<DoctorModel>(
                              initialValue: _selectedDoctor,
                              decoration: InputDecoration(
                                labelText: 'selectDoctor'.tr(),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              items: _doctors.map((doctor) {
                                return DropdownMenuItem<DoctorModel>(
                                  value: doctor,
                                  child: Text(doctor.name),
                                );
                              }).toList(),
                              onChanged: (DoctorModel? newValue) {
                                setState(() {
                                  _selectedDoctor = newValue;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'pleaseSelectDoctor'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            Focus(
                              focusNode: _searchFocusNode,
                              child: BlocBuilder<PatientsBloc, PatientsState>(
                                builder: (context, state) {
                                  if (state is PatientsLoaded) {
                                    _filteredPatients = state.patients.where((
                                      patient,
                                    ) {
                                      return patient.name
                                          .toLowerCase()
                                          .contains(query.toLowerCase());
                                    }).toList();
                                  }
                                  return Column(
                                    children: [
                                      TextFormField(
                                        controller: _patientNameController,
                                        focusNode: _patientNameFocusNode,
                                        readOnly: widget.session != null,
                                        decoration: InputDecoration(
                                          labelText: 'patientName'.tr(),
                                          hintText: 'searchPatients'.tr(),
                                          prefixIcon: const Icon(Icons.search),
                                          border: InputBorder.none,
                                          enabled: widget.session == null,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'pleaseEnterPatientName'
                                                .tr();
                                          }
                                          return null;
                                        },
                                        onChanged: (newQuery) {
                                          setState(() {
                                            query = newQuery;
                                          });
                                          context.read<PatientsBloc>().add(
                                                SearchPatients(name: query),
                                              ); // Trigger search event
                                        },
                                        onFieldSubmitted: (_) {
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(_actualPriceFocusNode);
                                        },
                                      ),
                                      if (_filteredPatients.isNotEmpty)
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: _filteredPatients.length,
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                title: Text(
                                                  _filteredPatients[index].name,
                                                ),
                                                onTap: () {
                                                  setState(() {
                                                    _patientNameController
                                                            .text =
                                                        _filteredPatients[index]
                                                            .name;
                                                    _selectedPatient =
                                                        _filteredPatients[
                                                            index]; // Set the selected patient
                                                    _filteredPatients = [];
                                                  });
                                                  _detectSessionTypeForPatient(
                                                    _filteredPatients[index].id,
                                                  );
                                                  FocusScope.of(
                                                    context,
                                                  ).requestFocus(
                                                    _actualPriceFocusNode,
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      if (_filteredPatients.isEmpty &&
                                          query.isNotEmpty)
                                        Column(
                                          children: [
                                            Text('noPatientsWithQuery'.tr()),
                                            Tooltip(
                                              message: 'goToAddPatient'.tr(),
                                              child: IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_forward,
                                                ),
                                                onPressed: () {
                                                  // Navigate to add patient page
                                                  context.go('/patients/new');
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: Text(
                                'startDateTime'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(_startDate!.toDate()),
                                    ),
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('hh:mm a')
                                          .format(_startDate!.toDate())
                                          .toUpperCase(),
                                    ),
                                    onTap: () => _selectTime(context, true),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: Text(
                                'endDateTime'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat(
                                        'yyyy-MM-dd',
                                      ).format(_endDate!.toDate()),
                                    ),
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('hh:mm a')
                                          .format(_endDate!.toDate())
                                          .toUpperCase(),
                                    ),
                                    onTap: () => _selectTime(context, false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: Text(
                                '${'duration'.tr()}: ${_endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0} ${'hours'.tr()}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            if (_validateTime() != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _validateTime()!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8.0),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSessionType,
                              decoration: InputDecoration(
                                labelText: 'sessionType'.tr(),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              items: SessionTypePresets.values.map((
                                String type,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Text(type),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedSessionType = newValue!;
                                  _updateEstimatedPrice();
                                });
                              },
                            ),
                            if (_selectedSessionType ==
                                SessionTypePresets.custom) ...[
                              const SizedBox(height: 8.0),
                              TextFormField(
                                controller: _customSessionTypeController,
                                decoration: InputDecoration(
                                  labelText: 'Custom Session Type Name',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (_selectedSessionType ==
                                          SessionTypePresets.custom &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter a name for the custom session type';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: Text(
                                'actualPrice'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            TextFormField(
                              controller: _actualPriceController,
                              focusNode: _actualPriceFocusNode,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'enterActualPrice'.tr(),
                                helperText:
                                    '${'estimatedPrice'.tr()}: \$${_estimatedPrice.toStringAsFixed(2)}',
                                border: const OutlineInputBorder(),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'enterValidAmount'.tr();
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'enterValidAmountGreaterThanZero'.tr();
                                }
                                if (amount > 1000000) {
                                  return 'amountCannotExceedOneMillion'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCalendar,
                              decoration: InputDecoration(
                                labelText: 'calendar'.tr(),
                                labelStyle: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              items: _calendars.map((String calendar) {
                                return DropdownMenuItem<String>(
                                  value: calendar,
                                  child: Row(
                                    children: <Widget>[Text(calendar)],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCalendar = newValue!;
                                });
                              },
                            ),
                            const SizedBox(height: 8.0),
                            const SizedBox(height: 8.0),
                            if (widget.session == null)
                              Card(
                                color: Colors.blue.shade50,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'invoice'.tr(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade900,
                                            ),
                                      ),
                                      const SizedBox(height: 8.0),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<
                                                CurrencyProfileModel>(
                                              initialValue:
                                                  _selectedCurrencyProfile,
                                              decoration: InputDecoration(
                                                labelText:
                                                    'currencyProfile'.tr(),
                                                labelStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              items: _currencyProfiles.map((
                                                CurrencyProfileModel profile,
                                              ) {
                                                return DropdownMenuItem<
                                                    CurrencyProfileModel>(
                                                  value: profile,
                                                  child: Text(
                                                    profile.currency.tr(),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (
                                                CurrencyProfileModel? newValue,
                                              ) {
                                                setState(() {
                                                  _selectedCurrencyProfile =
                                                      newValue;
                                                });
                                              },
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.refresh),
                                            onPressed: _fetchCurrencyProfiles,
                                            tooltip:
                                                'refreshCurrencyProfiles'.tr(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: DropdownButtonFormField<
                                                InvoiceStatus>(
                                              initialValue:
                                                  _selectedInvoiceStatus,
                                              decoration: InputDecoration(
                                                labelText: 'invoiceStatus'.tr(),
                                                labelStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                              items: InvoiceStatus.values.map((
                                                InvoiceStatus status,
                                              ) {
                                                return DropdownMenuItem<
                                                    InvoiceStatus>(
                                                  value: status,
                                                  child: Text(
                                                    'invoiceStatus.${status.name}'
                                                        .tr(),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (
                                                InvoiceStatus? newValue,
                                              ) {
                                                setState(() {
                                                  _selectedInvoiceStatus =
                                                      newValue;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8.0),
                                      if (_selectedInvoiceStatus ==
                                          InvoiceStatus.partiallyPaid)
                                        TextFormField(
                                          controller: _partialPaymentController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: InputDecoration(
                                            labelText: 'amount'.tr(),
                                            border: const OutlineInputBorder(),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'enterValidAmount'.tr();
                                            }
                                            final amount = double.tryParse(
                                              value,
                                            );
                                            if (amount == null || amount <= 0) {
                                              return 'enterValidAmountGreaterThanZero'
                                                  .tr();
                                            }
                                            if (amount > 1000000) {
                                              return 'amountCannotExceedOneMillion'
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _saveSession,
                                child: Text('saveAppointment'.tr()),
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
}
