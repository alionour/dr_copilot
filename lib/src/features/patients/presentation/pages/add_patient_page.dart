// Import necessary packages
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  // Selected gender
  String _selectedGender = '';

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
        actions: [
          // Submit button
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitForm,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Determine if it is a small screen
          final isSmallScreen = constraints.maxWidth < 600;
          // Center the content
          return Center(
            child: Container(
              // Limit the width on large screens
              width: isSmallScreen ? double.infinity : 600,
              padding: const EdgeInsets.all(16.0),
              // Make the content scrollable
              child: SingleChildScrollView(
                // Form for input fields
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name Form Field
                      TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        decoration: const InputDecoration(labelText: 'Name'),
                        // Validator for name field
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        // Move focus to the age field on submit
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_ageFocusNode);
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Age Form Field
                      TextFormField(
                        controller: _ageController,
                        focusNode: _ageFocusNode,
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                        // Validator for age field
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an age';
                          }
                          return null;
                        },
                        // Move focus to the address field on submit
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).requestFocus(_addressFocusNode);
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // Gender Choice Chips
                      Wrap(
                        spacing: 8.0,
                        children: [
                          // Male Choice Chip
                          ChoiceChip(
                            label: const Text('Male'),
                            selected: _selectedGender == 'Male',
                            // Update selected gender on selection
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedGender = selected ? 'Male' : '';
                              });
                            },
                          ),
                          // Female Choice Chip
                          ChoiceChip(
                            label: const Text('Female'),
                            selected: _selectedGender == 'Female',
                            // Update selected gender on selection
                            onSelected: (bool selected) {
                              setState(() {
                                _selectedGender = selected ? 'Female' : '';
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      // Address Form Field
                      TextFormField(
                        controller: _addressController,
                        focusNode: _addressFocusNode,
                        decoration: const InputDecoration(labelText: 'Address'),
                        // Validator for address field
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an address';
                          }
                          return null;
                        },
                        // Unfocus on submit
                        onFieldSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      const SizedBox(height: 20),
                      // Add Patient Button
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
    );
  }

  // Method to submit the form
  void _submitForm() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      // Create a new patient model
      final patient = PatientModel(
        id: '', // ID will be generated by Firestore
        name: _nameController.text,
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        address: _addressController.text,
      );
      // Add the patient to the bloc
      BlocProvider.of<PatientsBloc>(context).add(AddPatient(patient));
      // Pop the current page
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
