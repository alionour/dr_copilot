import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddEvaluationPage extends StatefulWidget {
  const AddEvaluationPage({super.key});

  @override
  State<AddEvaluationPage> createState() => _AddEvaluationPageState();
}

class _AddEvaluationPageState extends State<AddEvaluationPage> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _patientNameFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  DateTime? _startDate = DateTime.now(); // Initialize with the current date
  DateTime? _endDate = DateTime.now().add(
      const Duration(hours: 1)); // Initialize with the current date + 1 hour
  String _selectedCalendar = 'Evaluation'; // Default calendar matches the list
  String query = '';
  final FocusNode _searchFocusNode = FocusNode();
  List<PatientModel> _filteredPatients = [];

  final List<String> _calendars = ['Evaluation'];
  final Map<String, Color> _calendarColors = {
    'Evaluation': Colors.yellow,
  };

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

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (pickedTime != null) {
        final DateTime pickedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        if (mounted) {
          setState(() {
            if (isStart) {
              _startDate = pickedDateTime;
              _endDate = pickedDateTime.add(const Duration(
                  hours: 1)); // Set end date-time 1 hour after start date-time
            } else {
              _endDate = pickedDateTime;
            }
          });
        }
      }
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final newEvent = google_calendar.Event(
        summary: _patientNameController.text,
        description: _descriptionController.text,
        start: google_calendar.EventDateTime(dateTime: _startDate),
        end: google_calendar.EventDateTime(dateTime: _endDate),
      );
      if (mounted) {
        Navigator.of(context)
            .pop({'event': newEvent, 'calendar': _selectedCalendar});
      }
    }
  }

  @override
  void dispose() {
    _patientNameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Evaluation'),
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
          BlocListener<EvaluationsBloc, EvaluationsState>(
            listener: (context, state) {
              if (state is EvaluationsSuccess) {
                final message = state.message;
                if (message != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                    ),
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
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            return Center(
              child: SingleChildScrollView(
                child: Container(
                  width: isSmallScreen ? double.infinity : 600,
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
                                              query)); // Trigger search event
                                    },
                                    onFieldSubmitted: (_) {
                                      FocusScope.of(context)
                                          .requestFocus(_descriptionFocusNode);
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
                                            ? 5
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
                                                      _descriptionFocusNode);
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
                                                            _descriptionFocusNode);
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
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _descriptionController,
                          focusNode: _descriptionFocusNode,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Start Time',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  hintText: 'Select start time',
                                  suffixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: dateFormat.format(_startDate!),
                                ),
                                onTap: () => _selectDateTime(context, true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'End Time',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Select end time (must be after start time)',
                                  suffixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(),
                                ),
                                controller: TextEditingController(
                                  text: dateFormat.format(_endDate!),
                                ),
                                onTap: () => _selectDateTime(context, false),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
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
                        const SizedBox(height: 16.0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveEvent,
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
