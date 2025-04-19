import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class AddSessionPage extends StatefulWidget {
  const AddSessionPage({super.key});

  @override
  State<AddSessionPage> createState() => _AddSessionPageState();
}

class _AddSessionPageState extends State<AddSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _patientNameFocusNode = FocusNode();
  final _actualPriceFocusNode = FocusNode();
  Timestamp? _startDate =
      Timestamp.fromDate(DateTime.now()); // Initialize with the current date
  Timestamp? _endDate = Timestamp.fromDate(DateTime.now().add(
      const Duration(hours: 1))); // Initialize with the current date + 1 hour
  String _selectedCalendar = 'Sessions'; // Default calendar matches the list
  String query = '';
  final FocusNode _searchFocusNode = FocusNode();
  List<PatientModel> _filteredPatients = [];
  SessionType _selectedSessionType =
      SessionType.standard; // Default session type
  PatientModel? _selectedPatient; // Add a field to store the selected patient

  final List<String> _calendars = ['Sessions'];

  double _estimatedPrice =
      SessionType.standard.basePrice; // Default estimated price for 'Standard'
  final _actualPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_patientNameFocusNode);
    });
    context
        .read<PatientsBloc>()
        .add(const GetPatients()); // Fetch patients on init
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
    switch (_selectedSessionType) {
      case SessionType.adultIntensive:
        _estimatedPrice =
            duration <= 1.0 ? 150.0 : 200.0; // 1 hour or 1.5 hours
        break;
      case SessionType.pediatricIntensive:
        _estimatedPrice = 100.0 * duration;
        break;
      case SessionType.traction:
        _estimatedPrice = 150.0 * duration;
        break;
      case SessionType.standard:
        _estimatedPrice = 120.0 * duration;
        break;
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
        _updateEstimatedPrice(); // Update price when time changes
      });
    }
  }

  void _detectSessionTypeForPatient(String patientId) {
    context.read<SessionsBloc>().add(DetectSessionType(patientId));
  }

  void _saveSession() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('pleaseSelectPatient'.tr())),
        );
        return;
      }

      final sessionData = SessionModel(
        id: const Uuid().v4(),
        patientId: _selectedPatient!.id, // Use the selected patient's ID
        patientName:
            _selectedPatient!.name, // Include the selected patient's name
        startDateTime: _startDate!,
        endDateTime: _endDate!,
        createdAt: Timestamp.now(),

        sessionType: _selectedSessionType,
        price: double.parse(_actualPriceController.text),
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        createdBy: FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      context.read<SessionsBloc>().add(AddSession(sessionData));
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
        title: Text('addSession'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home'); // Navigate back to home
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
                    SnackBar(
                      content: Text(message),
                    ),
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
          BlocListener<SessionsBloc, SessionsState>(
            listener: (context, state) {
              if (state is SessionsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
                  );
                }
              } else if (state is SessionsError) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
              } else if (state is SessionTypeDetected) {
                setState(() {
                  _selectedSessionType = state.sessionType;
                });
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
                                        decoration: InputDecoration(
                                          labelText: 'patientName'.tr(),
                                          hintText: 'searchPatients'.tr(),
                                          prefixIcon: const Icon(Icons.search),
                                          border: InputBorder.none,
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
                                              SearchPatients(
                                                  name:
                                                      query)); // Trigger search event
                                        },
                                        onFieldSubmitted: (_) {
                                          FocusScope.of(context).requestFocus(
                                              _actualPriceFocusNode);
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
                                                            index]; // Set the selected patient
                                                    _filteredPatients = [];
                                                  });
                                                  _detectSessionTypeForPatient(
                                                      _filteredPatients[index]
                                                          .id);
                                                  FocusScope.of(context)
                                                      .requestFocus(
                                                          _actualPriceFocusNode);
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
                                                    Icons.arrow_forward),
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
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('HH:mm')
                                          .format(_startDate!.toDate()),
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
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(
                                      text: DateFormat('HH:mm')
                                          .format(_endDate!.toDate()),
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
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
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
                            Container(
                              alignment: AlignmentDirectional
                                  .centerStart, // Replaced Align with Container for RTL/LTR support
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ToggleButtons(
                                  isSelected: SessionType.values
                                      .map((type) =>
                                          _selectedSessionType == type)
                                      .toList(),
                                  onPressed: (index) {
                                    setState(() {
                                      _selectedSessionType =
                                          SessionType.values[index];
                                      _updateEstimatedPrice(); // Update price when session type changes
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8.0),
                                  selectedColor: Colors.white,
                                  fillColor: Colors.blueAccent,
                                  children: SessionType.values.map((type) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12.0, vertical: 6.0),
                                      child: Text(
                                        'sessionType.${type.name}'.tr(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _selectedSessionType == type
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _saveSession, // Call _saveEvent on button press
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
