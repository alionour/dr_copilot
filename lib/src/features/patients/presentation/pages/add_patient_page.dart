// Import necessary packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/quota_service.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

// AddPatientPage StatefulWidget
class AddPatientPage extends StatefulWidget {
  final PatientModel? patient;
  final Map<String, dynamic>? initialData;
  final bool showScaffold;
  final VoidCallback? onSuccess;
  final VoidCallback? onCancel;
  final Function(Map<String, dynamic>)?
      onFormDataChange; // NEW: Callback for data changes

  const AddPatientPage({
    super.key,
    this.patient,
    this.initialData,
    this.showScaffold = true,
    this.onSuccess,
    this.onCancel,
    this.onFormDataChange, // NEW
  });

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
  String? _selectedClinicId;
  bool _isPopulating = false; // Prevent callback during programmatic updates
  bool _hasInitiallyFocused =
      false; // Track if we've already focused on first load

  @override
  void initState() {
    super.initState();
    _populateFields();
    _attachListeners(); // NEW: Attach listeners to notify on changes
  }

  // NEW: Attach listeners to text controllers
  void _attachListeners() {
    _nameController.addListener(_notifyFormDataChange);
    _ageController.addListener(_notifyFormDataChange);
    _addressController.addListener(_notifyFormDataChange);
    _phoneNumberController.addListener(_notifyFormDataChange);
    _alternativePhoneNumberController.addListener(_notifyFormDataChange);
    _treatingDoctorController.addListener(_notifyFormDataChange);
    _occupationController.addListener(_notifyFormDataChange);
  }

  // NEW: Notify parent of current form data (only for user edits, not programmatic changes)
  void _notifyFormDataChange() {
    if (!_isPopulating && widget.onFormDataChange != null) {
      widget.onFormDataChange!(_getCurrentFormData());
    }
  }

  // NEW: Extract current form data
  Map<String, dynamic> _getCurrentFormData() {
    return {
      'name': _nameController.text,
      'age': int.tryParse(_ageController.text) ?? _ageController.text,
      'gender': _selectedGender,
      'address': _addressController.text,
      'phoneNumber': _phoneNumberController.text,
      'alternativePhoneNumber': _alternativePhoneNumberController.text,
      'treatingDoctor': _treatingDoctorController.text,
      'occupation': _occupationController.text,
    };
  }

  @override
  void didUpdateWidget(covariant AddPatientPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initialData changes (e.g. from AI update), update the fields
    if (widget.initialData != oldWidget.initialData &&
        widget.initialData != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    _isPopulating = true; // Suppress callback during population
    if (widget.patient != null) {
      _nameController.text = widget.patient!.name;
      _ageController.text = widget.patient!.age?.toString() ?? '';
      _addressController.text = widget.patient!.address ?? '';
      _phoneNumberController.text = widget.patient!.phoneNumber ?? '';
      _alternativePhoneNumberController.text =
          widget.patient!.alternativePhoneNumber ?? '';
      _treatingDoctorController.text = widget.patient!.treatingDoctor ?? '';
      _occupationController.text = widget.patient!.occupation ?? '';
      _selectedGender = widget.patient!.gender ?? 'Male';
      _selectedClinicId = widget.patient!.clinicId;
    } else if (widget.initialData != null) {
      // Only update fields if they are empty or if it's an explicit update
      // But for AI voice interaction, we probably want to overwrite?
      // Yes, if AI says "Change name to X", expected behavior is overwriting.
      // However, we preserve typed text if user is typing?
      // Since LiveChatPage provides full state, we rely on LiveChatPage to merge.
      // LiveChatPage currently just replaces _activeFormData.
      // So here we apply what we get.

      if (widget.initialData!['name'] != null) {
        _nameController.text = widget.initialData!['name'];
      }
      if (widget.initialData!['age'] != null) {
        _ageController.text = widget.initialData!['age']?.toString() ?? '';
      }
      if (widget.initialData!['address'] != null) {
        _addressController.text = widget.initialData!['address'];
      }
      if (widget.initialData!['phoneNumber'] != null) {
        _phoneNumberController.text = widget.initialData!['phoneNumber'];
      }
      if (widget.initialData!['alternativePhoneNumber'] != null) {
        _alternativePhoneNumberController.text =
            widget.initialData!['alternativePhoneNumber'];
      }
      if (widget.initialData!['treatingDoctor'] != null) {
        _treatingDoctorController.text = widget.initialData!['treatingDoctor'];
      }
      if (widget.initialData!['occupation'] != null) {
        _occupationController.text = widget.initialData!['occupation'];
      }

      final gender = widget.initialData!['gender'];
      if (gender != null && gender.toString().toLowerCase() == 'female') {
        _selectedGender = 'Female';
      } else if (gender != null) {
        _selectedGender = 'Male';
      }
    }
    // Request focus to the name field ONLY on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitiallyFocused) {
        FocusScope.of(context).requestFocus(_nameFocusNode);
        _hasInitiallyFocused = true;
      }
      _isPopulating = false; // Re-enable callback after population completes
    });
  }

  // Build method for the UI
  @override
  Widget build(BuildContext context) {
    final Widget body = BlocListener<PatientsBloc, PatientsState>(
      listener: (context, state) {
        if (state is PatientsSuccess) {
          // Clear the form fields after successful addition
          _nameController.clear();
          _ageController.clear();
          _addressController.clear();
          _phoneNumberController.clear();
          _alternativePhoneNumberController.clear();
          _treatingDoctorController.clear();
          _occupationController.clear();
          setState(() {
            _selectedGender = 'Male';
          });
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else if (context.mounted) {
            context.pop();
          }
        } else if (state is PatientsError) {
          debugPrint('SnackBar Error: ${state.message}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Clinic selection dropdown
                          Consumer<OwnerNotifier>(
                            builder: (context, ownerNotifier, _) {
                              final clinics = ownerNotifier.clinics;
                              if (clinics.isEmpty) {
                                return const SizedBox();
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedClinicId ??
                                        ownerNotifier.clinicId,
                                    decoration: InputDecoration(
                                      labelText: 'clinic'.tr(),
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: clinics.map((clinic) {
                                      return DropdownMenuItem<String>(
                                        value: clinic.id,
                                        child: Text(clinic.name),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedClinicId = newValue;
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
                                ],
                              );
                            },
                          ),
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
                              FocusScope.of(
                                context,
                              ).requestFocus(_ageFocusNode);
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
                              FocusScope.of(
                                context,
                              ).requestFocus(_addressFocusNode);
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
                              FocusScope.of(
                                context,
                              ).requestFocus(_phoneNumberFocusNode);
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
                                _alternativePhoneNumberFocusNode,
                              );
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
                              FocusScope.of(
                                context,
                              ).requestFocus(_treatingDoctorFocusNode);
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
                              FocusScope.of(
                                context,
                              ).requestFocus(_occupationFocusNode);
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
                                _selectedGender == 'Female',
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
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.male, size: 20),
                                      const SizedBox(width: 8),
                                      Text('male'.tr()),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.female, size: 20),
                                      const SizedBox(width: 8),
                                      Text('female'.tr()),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              if (widget.onCancel != null) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: widget.onCancel,
                                    child: Text('cancel'.tr()),
                                  ),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitForm,
                                  child: Text(
                                    widget.patient != null
                                        ? 'saveChanges'.tr()
                                        : 'addPatient'.tr(),
                                  ),
                                ),
                              ),
                            ],
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

    // If showScaffold is false, return just the body for inline embedding
    if (!widget.showScaffold) {
      return body;
    }

    // Otherwise return with Scaffold and AppBar
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patient != null ? 'editPatient'.tr() : 'addPatient'.tr(),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: body,
    );
  }

  // Method to submit the form
  Future<void> _submitForm() async {
    // Validate the form
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final ownerNotifier = Provider.of<OwnerNotifier>(context, listen: false);
      final ownerId = ownerNotifier.ownerId;
      final clinicId = _selectedClinicId ?? ownerNotifier.clinicId;

      // Check if the user is authenticated and clinic/owner are available
      if (userId != null && ownerId != null && clinicId != null) {
        // Subscription Check: Only when adding a new patient
        if (widget.patient == null) {
          final subscriptionService = sl<SubscriptionService>();
          final canAdd = await subscriptionService.checkEntityLimit(
            clinicId,
            LimitType.patients,
          );

          if (!canAdd) {
            if (mounted) {
              _showUpgradeDialog(context, 'patientLimitReached'.tr());
            }
            return;
          }
        }

        const uuid = Uuid();
        final patientModel = PatientModel(
          id: uuid.v4(), // Generate a unique ID
          name: _nameController.text,
          age: int.tryParse(_ageController.text),
          createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
          gender: _selectedGender,
          address: _addressController.text,
          ownerId: ownerId,
          clinicId: clinicId,
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
        if (widget.patient != null) {
          if (mounted) {
            BlocProvider.of<PatientsBloc>(context).add(
              UpdatePatient(
                widget.patient!.id,
                patientModel.copyWith(id: widget.patient!.id),
              ),
            );
          }
        } else {
          if (mounted) {
            BlocProvider.of<PatientsBloc>(context)
                .add(AddPatient(patientModel));
          }
        }
      } else {
        final message = 'userIdCannotBeNull'.tr();
        debugPrint('SnackBar Error: $message');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
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
              context.push('/settings/subscription');
            },
            child: Text('upgrade'.tr()),
          ),
        ],
      ),
    );
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
