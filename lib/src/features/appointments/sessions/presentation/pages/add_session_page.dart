import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

  final List<String> _calendars = ['Sessions'];
  final Map<String, Color> _calendarColors = {
    'Sessions': Colors.red,
  };

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
      return 'End time must be after start time.';
    }
    final duration =
        _endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0;
    if (duration > 4.0) {
      return 'The maximum allowed duration is 4 hours.';
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
      await _selectTime(context, isStart); // Automatically move to time picker
    }
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
      setState(() {
        if (isStart) {
          _startDate = Timestamp.fromDate(DateTime(
              _startDate?.toDate().year ?? DateTime.now().year,
              _startDate?.toDate().month ?? DateTime.now().month,
              _startDate?.toDate().day ?? DateTime.now().day,
              pickedTime.hour,
              pickedTime.minute));
          _endDate = _endDate!.toDate().isBefore(_startDate!.toDate())
              ? Timestamp.fromDate(
                  _startDate!.toDate().add(const Duration(hours: 1)))
              : _endDate;
        } else {
          _endDate = Timestamp.fromDate(DateTime(
              _endDate?.toDate().year ?? DateTime.now().year,
              _endDate?.toDate().month ?? DateTime.now().month,
              _endDate?.toDate().day ?? DateTime.now().day,
              pickedTime.hour,
              pickedTime.minute));
        }
        _updateEstimatedPrice(); // Update price when time changes
      });
    }
  }

  void _saveSession() {
    if (_formKey.currentState!.validate()) {
      final sessionData = SessionModel(
        id: const Uuid().v4(),
        patientName: _patientNameController.text,
        startDateTime: _startDate!,
        endDateTime: _endDate!,
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
        title: const Text('Add New Session'),
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
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(message)),
                  );
                }
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
              }
            },
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Center(
              child: SingleChildScrollView(
                child: Container(
                  width: isSmallScreen ? double.infinity : 600,
                  padding: const EdgeInsets.all(8.0),
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
                                    decoration: const InputDecoration(
                                      labelText: 'Patient Name',
                                      hintText: 'Search Patients',
                                      prefixIcon: Icon(Icons.search),
                                      border: InputBorder.none,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a patient name';
                                      }
                                      return null;
                                    },
                                    onChanged: (newQuery) {
                                      setState(() {
                                        query = newQuery;
                                      });
                                      context.read<PatientsBloc>().add(
                                          SearchPatients(
                                              name:query)); // Trigger search event
                                    },
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_actualPriceFocusNode);
                                    },
                                  ),
                                  if (_filteredPatients.isNotEmpty)
                                    Container(
                                      constraints: const BoxConstraints(
                                        maxHeight:
                                            200, // Limit height for scrolling
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _filteredPatients.length > 5
                                            ? 2
                                            : _filteredPatients
                                                .length, // Show only 5 items
                                        itemBuilder: (context, index) {
                                          return ListTile(
                                            title: Text(
                                                _filteredPatients[index].name),
                                            onTap: () {
                                              setState(() {
                                                _patientNameController.text =
                                                    _filteredPatients[index]
                                                        .name;
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
                                      query.isNotEmpty)
                                    Column(
                                      children: [
                                        const Text(
                                            'No patients with provided query.'),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Tooltip(
                                              message: 'Add Patient',
                                              child: IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  final userId = FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid;
                                                  if (userId != null) {
                                                    // Add patient directly
                                                    final newPatient =
                                                        PatientModel(
                                                            id: const Uuid()
                                                                .v4(),
                                                            name: query,
                                                            userId: userId);
                                                    context
                                                        .read<PatientsBloc>()
                                                        .add(AddPatient(
                                                            newPatient));
                                                    setState(() {
                                                      _patientNameController
                                                          .text = query;
                                                      _filteredPatients = [];
                                                    });
                                                    FocusScope.of(context)
                                                        .requestFocus(
                                                            _actualPriceFocusNode);
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              'User can not be null')),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            Tooltip(
                                              message: 'Go to Add Patient',
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
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Start Date & Time',
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
                                decoration: const InputDecoration(
                                  hintText: 'Select start date',
                                  suffixIcon:
                                      Icon(Icons.calendar_month_outlined),
                                  border: OutlineInputBorder(),
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
                                decoration: const InputDecoration(
                                  hintText: 'Select start time',
                                  suffixIcon:
                                      Icon(Icons.access_time_filled_outlined),
                                  border: OutlineInputBorder(),
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'End Date & Time',
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
                                decoration: const InputDecoration(
                                  hintText: 'Select end date',
                                  suffixIcon:
                                      Icon(Icons.calendar_month_outlined),
                                  border: OutlineInputBorder(),
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
                                decoration: const InputDecoration(
                                  hintText: 'Select end time',
                                  suffixIcon:
                                      Icon(Icons.access_time_filled_outlined),
                                  border: OutlineInputBorder(),
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Duration: ${_endDate!.toDate().difference(_startDate!.toDate()).inMinutes / 60.0} hours',
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Session Type',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 8.0,
                          children: SessionType.values.map((type) {
                            return ChoiceChip(
                              label: Text(type.text),
                              selected: _selectedSessionType == type,
                              onSelected: (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSessionType = type;
                                    _updateEstimatedPrice(); // Update price when session type changes
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Actual Price',
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
                            hintText: 'Enter actual price',
                            helperText:
                                'Estimated Price: \$${_estimatedPrice.toStringAsFixed(2)}',
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the actual price';
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return 'Please enter a valid price greater than zero';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8.0),
                        DropdownButtonFormField<String>(
                          value: _selectedCalendar,
                          decoration: InputDecoration(
                            labelText: 'Calendar',
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
                                    backgroundColor: _calendarColors[calendar],
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _saveSession, // Call _saveEvent on button press
                            child: const Text('Save Appointment'),
                          ),
                        ),
                      ],
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
