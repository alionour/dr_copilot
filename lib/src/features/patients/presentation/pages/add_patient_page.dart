// Import necessary packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

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
  final _phoneNumberController = TextEditingController();
  final _alternativePhoneNumberController = TextEditingController();
  final _treatingDoctorController = TextEditingController();
  final _occupationController = TextEditingController();

  // Focus nodes for form fields
  final _nameFocusNode = FocusNode();
  final _ageFocusNode = FocusNode();
  final _genderFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _alternativePhoneNumberFocusNode = FocusNode();
  final _treatingDoctorFocusNode = FocusNode();
  final _occupationFocusNode = FocusNode();

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
        title: Text('addPatient'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: LayoutBuilder(
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
                        children: [
                          TextFormField(
                            controller: _nameController,
                            focusNode: _nameFocusNode,
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
                              labelText: 'age'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'pleaseEnterAge'.tr();
                              }
                              final age = int.tryParse(value);
                              if (age == null || age < 1 || age > 120) {
                                return 'ageMustBeBetween'.tr();
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
                              labelText: 'address'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'pleaseEnterAddress'.tr();
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_phoneNumberFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _phoneNumberController,
                            focusNode: _phoneNumberFocusNode,
                            decoration: InputDecoration(
                              labelText: 'phoneNumber'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'pleaseEnterPhoneNumber'.tr();
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).requestFocus(
                                  _alternativePhoneNumberFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _alternativePhoneNumberController,
                            focusNode: _alternativePhoneNumberFocusNode,
                            decoration: InputDecoration(
                              labelText: 'alternativePhoneNumber'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_treatingDoctorFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _treatingDoctorController,
                            focusNode: _treatingDoctorFocusNode,
                            decoration: InputDecoration(
                              labelText: 'treatingDoctor'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (_) {
                              FocusScope.of(context)
                                  .requestFocus(_occupationFocusNode);
                            },
                          ),
                          const SizedBox(height: 16.0),
                          TextFormField(
                            controller: _occupationController,
                            focusNode: _occupationFocusNode,
                            decoration: InputDecoration(
                              labelText: 'occupation'.tr(),
                              border: const OutlineInputBorder(),
                            ),
                            onFieldSubmitted: (_) {
                              FocusScope.of(context).unfocus();
                            },
                          ),
                          const SizedBox(height: 16.0),
                          Container(
                            alignment: AlignmentDirectional
                                .centerStart, // Replaced Align with Container for RTL/LTR support
                            child: Text(
                              'gender'.tr(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Container(
                            alignment: AlignmentDirectional
                                .centerStart, // Replaced Align with Container for RTL/LTR support
                            child: ToggleButtons(
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
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.male, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'male'.tr(),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.female, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'female'.tr(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              child: Text('addPatient'.tr()),
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
          age: int.tryParse(_ageController.text),
          createdAt: Timestamp.now(),
          gender: _selectedGender,
          address: _addressController.text,
          userId: userId, // Get userId from AuthBloc
          phoneNumber: _phoneNumberController.text.isNotEmpty
              ? _phoneNumberController.text
              : null,
          alternativePhoneNumber:
              _alternativePhoneNumberController.text.isNotEmpty
                  ? _alternativePhoneNumberController.text
                  : null,
          treatingDoctor: _treatingDoctorController.text.isNotEmpty
              ? _treatingDoctorController.text
              : null,
          occupation: _occupationController.text.isNotEmpty
              ? _occupationController.text
              : null,
        );
        BlocProvider.of<PatientsBloc>(context).add(AddPatient(patientModel));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('userIdCannotBeNull'.tr())),
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
    _phoneNumberController.dispose();
    _alternativePhoneNumberController.dispose();
    _treatingDoctorController.dispose();
    _occupationController.dispose();
    // Dispose the focus nodes
    _nameFocusNode.dispose();
    _ageFocusNode.dispose();
    _genderFocusNode.dispose();
    _addressFocusNode.dispose();
    _phoneNumberFocusNode.dispose();
    _alternativePhoneNumberFocusNode.dispose();
    _treatingDoctorFocusNode.dispose();
    _occupationFocusNode.dispose();
    super.dispose();
  }
}
