// Import necessary packages
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

// AddPatientPage StatefulWidget
class AddPatientPage extends StatefulWidget {
  // Constructor for AddPatientPage
  const AddPatientPage({super.key});

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

  // Focus nodes for form fields
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _genderFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    // Request focus to the name field when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocusNode);
    });
  }

  // Build method for the UI
  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic visual structure
    return Scaffold(
      // App bar with title and submit button
      appBar: AppBar(
        title: const Text('Add Patient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home'); // Navigate back to home
          },
        ),
        actions: [
          // Submit button
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: BlocListener<PatientsBloc, PatientsState>(
        listener: (context, state) {
          if (state is PatientsSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Patient added successfully')),
            );
            Navigator.pop(context);
          } else if (state is PatientsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocusNode,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_ageFocusNode);
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _ageController,
                          focusNode: _ageFocusNode,
                          decoration: const InputDecoration(labelText: 'Age'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an age';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(_addressFocusNode);
                          },
                        ),
                        const SizedBox(height: 16.0),
                        Wrap(
                          spacing: 8.0,
                          children: [
                            ChoiceChip(
                              label: const Text('Male'),
                              selected: _selectedGender == 'Male',
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedGender = selected ? 'Male' : '';
                                });
                              },
                            ),
                            ChoiceChip(
                              label: const Text('Female'),
                              selected: _selectedGender == 'Female',
                              onSelected: (bool selected) {
                                setState(() {
                                  _selectedGender = selected ? 'Female' : '';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _addressController,
                          focusNode: _addressFocusNode,
                          decoration:
                              const InputDecoration(labelText: 'Address'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an address';
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            child: const Text('Add Patient'),
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

  // Method to submit the form
  void _submitForm() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      const uuid = Uuid();
      final patientModel = PatientModel(
        id: uuid.v4(), // Generate a unique ID
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        address: _addressController.text,
      );
      BlocProvider.of<PatientsBloc>(context).add(AddPatient(patient));
      Navigator.pop(context);
    }
  }

  // Dispose method to release resources
  @override
  void dispose() {
    // Dispose the controllers
    _nameController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _addressController.dispose();
    // Dispose the focus nodes
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _genderFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }
}
