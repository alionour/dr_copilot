// Import necessary packages
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Patient',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submitForm,
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: BlocListener<PatientsBloc, PatientsState>(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Add New Patient',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _nameController,
                              focusNode: _nameFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                labelStyle: GoogleFonts.tajawal(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              style: GoogleFonts.tajawal(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_ageFocusNode);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _ageController,
                              focusNode: _ageFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                labelStyle: GoogleFonts.robotoSlab(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter an age';
                                }
                                final age = int.tryParse(value);
                                if (age == null || age < 1 || age > 120) {
                                  return 'Age must be between 1 and 120';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                FocusScope.of(context)
                                    .requestFocus(_addressFocusNode);
                              },
                            ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              controller: _addressController,
                              focusNode: _addressFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Address',
                                labelStyle: GoogleFonts.tajawal(),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                              style: GoogleFonts.tajawal(),
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
                            const Text(
                              'Gender',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8.0),
                            ToggleButtons(
                              isSelected: [
                                _selectedGender == 'Male',
                                _selectedGender == 'Female'
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _selectedGender =
                                      index == 0 ? 'Male' : 'Female';
                                });
                              },
                              borderRadius: BorderRadius.circular(8.0),
                              selectedColor: Colors.white,
                              fillColor: Colors.blueAccent,
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.male, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Male',
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.female, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Female',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16.0),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _submitForm,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                child: const Text(
                                  'Add Patient',
                                  style: TextStyle(fontSize: 16),
                                ),
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

  // Method to submit the form
  void _submitForm() {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      // Check if the user is authenticated
      if (userId != null) {
        const uuid = Uuid();
        final patientModel = PatientModel(
          id: uuid.v4(), // Generate a unique ID
          name: _nameController.text,
          age: int.parse(_ageController.text),
          gender: _selectedGender,
          address: _addressController.text,
          userId: userId, // Get userId from AuthBloc
        );
        BlocProvider.of<PatientsBloc>(context).add(AddPatient(patientModel));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('UserId can not be null')),
        );
      }
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
