import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/doctors/presentation/bloc/doctors_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

class AddEvaluationPage extends StatefulWidget {
  final EvaluationModel? evaluation;
  const AddEvaluationPage({super.key, this.evaluation});

  @override
  State<AddEvaluationPage> createState() => _AddEvaluationPageState();
}

class _AddEvaluationPageState extends State<AddEvaluationPage> {
  String? _selectedClinicId;
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientNameFocusNode = FocusNode();
  final _actualPriceFocusNode = FocusNode();
  Timestamp? _startDate =
      Timestamp.fromDate(DateTime.now()); // Initialize with the current date
  Timestamp? _endDate = Timestamp.fromDate(DateTime.now().add(
      const Duration(hours: 1))); // Initialize with the current date + 1 hour
  String _selectedCalendar = 'Evaluations'; // Default calendar matches the list
  String query = '';
  final FocusNode _searchFocusNode = FocusNode();
  List<PatientModel> _filteredPatients = [];
  PatientModel? _selectedPatient;

  final List<String> _calendars = ['Evaluations'];
  final Map<String, Color> _calendarColors = {
    'Evaluations': Colors.red,
  };

  double _estimatedPrice = 250.0; // Default estimated price
  final _actualPriceController = TextEditingController();

  DoctorModel? _selectedDoctor;
  List<DoctorModel> _doctors = [];

  CurrencyProfileModel? _selectedCurrencyProfile;
  List<CurrencyProfileModel> _currencyProfiles = [];
  InvoiceStatus? _selectedInvoiceStatus;
  final TextEditingController _partialPaymentController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_patientNameFocusNode);
      _fetchCurrencyProfiles(); // Fetch currency profiles on init
      context.read<DoctorsBloc>().add(const GetDoctors());
    });
    context.read<PatientsBloc>().add(const GetPatients());

    if (widget.evaluation != null) {
      _selectedClinicId = widget.evaluation!.clinicId;
      _startDate = widget.evaluation!.startDateTime;
      _endDate = widget.evaluation!.endDateTime;
      _actualPriceController.text = widget.evaluation!.price.toString();
      _patientNameController.text = widget.evaluation!.patientName;
      _selectedPatient = PatientModel(
        id: widget.evaluation!.patientId,
        name: widget.evaluation!.patientName,
        ownerId: widget.evaluation!.ownerId,
        clinicId: widget.evaluation!.clinicId,
      );
      // _selectedDoctor will be set when doctors are loaded
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
          await context.read<EvaluationsBloc>().getCurrencyProfiles();
      failureOrProfiles.fold(
        (failure) {
          debugPrint('Failed to fetch currency profiles: ${failure.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('failedToFetchCurrencyProfiles'.tr())),
          );
        },
        (profiles) {
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
      _selectedCurrencyProfile ??= _currencyProfiles.first;
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
          _startDate = Timestamp.fromDate(DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              _startDate?.toDate().hour ?? 0,
              _startDate?.toDate().minute ?? 0));
        } else {
          _endDate = Timestamp.fromDate(DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              _endDate?.toDate().hour ?? 0,
              _endDate?.toDate().minute ?? 0));
        }
      });
      if (!context.mounted) return;

      await _selectTime(context, isStart);
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
        dateTime.year, dateTime.month, dateTime.day, hour, roundedMinute);
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
                  _startDate!.toDate().add(const Duration(hours: 1)))
              : _endDate;
        } else {
          _endDate = Timestamp.fromDate(roundedDateTime);
        }
      });
    }
  }

  void _saveEvaluation() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatient == null) {
        // Try to find patient from list if name matches
        try {
          _selectedPatient = _filteredPatients.firstWhere(
            (p) => p.name == _patientNameController.text,
          );
        } catch (e) {
          // Patient not found
        }
      }

      if (_selectedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pleaseSelectPatient'.tr())),
        );
        return;
      }

      if (_selectedCurrencyProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Please select a currency profile before adding a evaluation.')),
        );
        return;
      }

      if (_selectedClinicId == null || _selectedClinicId!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a clinic.')),
        );
        return;
      }

      if (_selectedInvoiceStatus == null && widget.evaluation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an invoice status.')),
        );
        return;
      }

      final now = Timestamp.fromDate(DateTime.now().toUtc());

      final evaluation = EvaluationModel(
        id: widget.evaluation?.id ?? const Uuid().v4(),
        patientId: _selectedPatient!.id,
        patientName: _selectedPatient!.name,
        startDateTime: _startDate!,
        endDateTime: _endDate!,
        createdAt: widget.evaluation?.createdAt ?? now,
        price: double.parse(_actualPriceController.text),
        ownerId: widget.evaluation?.ownerId ??
            FirebaseAuth.instance.currentUser?.uid ??
            '',
        clinicId: _selectedClinicId!,
        createdBy: widget.evaluation?.createdBy ??
            FirebaseAuth.instance.currentUser?.uid ??
            '',
        doctorId: _selectedDoctor?.id,
      );

      if (widget.evaluation != null) {
        context
            .read<EvaluationsBloc>()
            .add(UpdateEvaluation(evaluation.id, evaluation));
      } else {
        context.read<EvaluationsBloc>().add(AddEvaluation(evaluation,
            invoiceStatus: _selectedInvoiceStatus!,
            currencyProfileId: _selectedCurrencyProfile!.id));
      }
    }
  }

  @override
  void dispose() {
    _patientNameFocusNode.dispose();
    _patientNameController.dispose();
    _actualPriceFocusNode.dispose();
    _actualPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.evaluation != null
            ? 'Edit Evaluation'
            : 'addEvaluation'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } else if (state is PatientsError) {
                final message = state.message;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(message)),
                );
              }
            },
          ),
          BlocListener<EvaluationsBloc, EvaluationsState>(
            listener: (context, state) {
              if (state is EvaluationsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } else if (state is EvaluationsError) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              }
            },
          ),
          BlocListener<DoctorsBloc, DoctorsState>(
            listener: (context, state) {
              if (state is DoctorsLoaded) {
                setState(() {
                  _doctors = state.doctors;
                  if (_doctors.isNotEmpty && _selectedDoctor == null) {
                    if (widget.evaluation != null &&
                        widget.evaluation!.doctorId != null) {
                      try {
                        _selectedDoctor = _doctors.firstWhere(
                            (d) => d.id == widget.evaluation!.doctorId);
                      } catch (e) {
                        // Doctor not found
                      }
                    }
                    _selectedDoctor ??= _doctors.first;
                  }
                });
              } else if (state is DoctorsError) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
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
                              onChanged: widget.evaluation != null
                                  ? null
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
                              value: _selectedDoctor,
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
                                    _filteredPatients =
                                        state.patients.where((patient) {
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
                                        readOnly: widget.evaluation != null,
                                        decoration: InputDecoration(
                                          labelText: 'patientName'.tr(),
                                          hintText: 'searchPatients'.tr(),
                                          prefixIcon: const Icon(Icons.search),
                                          border: InputBorder.none,
                                          enabled: widget.evaluation == null,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'pleaseEnterName'.tr();
                                          }
                                          return null;
                                        },
                                        onChanged: (newQuery) {
                                          setState(() {
                                            query = newQuery;
                                          });
                                          context
                                              .read<PatientsBloc>()
                                              .add(SearchPatients(name: query));
                                        },
                                        onFieldSubmitted: (_) {
                                          FocusScope.of(context).requestFocus(
                                              _actualPriceFocusNode);
                                        },
                                      ),
                                      if (_filteredPatients.isNotEmpty &&
                                          widget.evaluation == null)
                                        Container(
                                          constraints: const BoxConstraints(
                                            maxHeight: 200,
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount:
                                                _filteredPatients.length > 5
                                                    ? 5
                                                    : _filteredPatients.length,
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                title: Text(
                                                    _filteredPatients[index]
                                                        .name),
                                                onTap: () {
                                                  setState(() {
                                                    _patientNameController
                                                            .text =
                                                        _filteredPatients[index]
                                                            .name;
                                                    _selectedPatient =
                                                        _filteredPatients[
                                                            index];
                                                    _filteredPatients = [];
                                                  });
                                                  FocusScope.of(context)
                                                      .requestFocus(
                                                          _actualPriceFocusNode);
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      if (_filteredPatients.isEmpty &&
                                          query.isNotEmpty &&
                                          widget.evaluation == null)
                                        Column(
                                          children: [
                                            Text('noPatients'.tr()),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Tooltip(
                                                  message:
                                                      'goToAddPatient'.tr(),
                                                  child: IconButton(
                                                    icon: const Icon(
                                                        Icons.arrow_forward),
                                                    onPressed: () {
                                                      context
                                                          .go('/patients/new');
                                                    },
                                                  ),
                                                ),
                                              ],
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
                              alignment: AlignmentDirectional.centerStart,
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
                                      hintText: 'selectStartDate'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.calendar_month_outlined),
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('yyyy-MM-dd')
                                          .format(_startDate!.toDate()),
                                    ),
                                    onTap: () => _selectDate(context, true),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'selectStartTime'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.access_time_filled_outlined),
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
                              alignment: AlignmentDirectional.centerStart,
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
                                      hintText: 'selectEndDate'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.calendar_month_outlined),
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('yyyy-MM-dd')
                                          .format(_endDate!.toDate()),
                                    ),
                                    onTap: () => _selectDate(context, false),
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Expanded(
                                  child: TextFormField(
                                    readOnly: true,
                                    decoration: InputDecoration(
                                      hintText: 'selectEndTime'.tr(),
                                      suffixIcon: const Icon(
                                          Icons.access_time_filled_outlined),
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
                              alignment: AlignmentDirectional.centerStart,
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
                              Container(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  _validateTime()!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8.0),
                            Container(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                'actualPrice'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'enterValidPrice'.tr();
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'enterValidPriceGreaterThanZero'.tr();
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8.0),
                            DropdownButtonFormField<String>(
                              value: _selectedCalendar,
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
                                    children: <Widget>[
                                      CircleAvatar(
                                        backgroundColor:
                                            _calendarColors[calendar],
                                        radius: 5,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(calendar),
                                    ],
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
                            if (widget.evaluation == null)
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
                                              value: _selectedCurrencyProfile,
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
                                              items: _currencyProfiles.map(
                                                  (CurrencyProfileModel
                                                      profile) {
                                                return DropdownMenuItem<
                                                    CurrencyProfileModel>(
                                                  value: profile,
                                                  child: Text(
                                                      profile.currency.tr()),
                                                );
                                              }).toList(),
                                              onChanged: (CurrencyProfileModel?
                                                  newValue) {
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
                                              value: _selectedInvoiceStatus,
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
                                              items: InvoiceStatus.values
                                                  .map((InvoiceStatus status) {
                                                return DropdownMenuItem<
                                                    InvoiceStatus>(
                                                  value: status,
                                                  child: Text(
                                                      'invoiceStatus.${status.name}'
                                                          .tr()),
                                                );
                                              }).toList(),
                                              onChanged:
                                                  (InvoiceStatus? newValue) {
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
                                            final amount =
                                                double.tryParse(value);
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
                                onPressed: _saveEvaluation,
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
