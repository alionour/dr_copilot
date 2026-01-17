import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/medications/domain/models/medication_model.dart';
import 'package:dr_copilot/src/features/medications/presentation/bloc/medication_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddEditMedicationPage extends StatefulWidget {
  final String patientId;
  final MedicationModel? medication;

  const AddEditMedicationPage({
    super.key,
    required this.patientId,
    this.medication,
  });

  @override
  State<AddEditMedicationPage> createState() => _AddEditMedicationPageState();
}

class _AddEditMedicationPageState extends State<AddEditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _startDateController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  File? _selectedFile;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      final m = widget.medication!;
      _nameController.text = m.name;
      _dosageController.text = m.dosage ?? '';
      _frequencyController.text = m.frequency ?? '';
      _instructionsController.text = m.instructions ?? '';
      _selectedDate = m.startDate;
    }
    _startDateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _instructionsController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _startDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final medication = MedicationModel(
        id: widget.medication?.id ?? const Uuid().v4(),
        patientId: widget.patientId,
        name: _nameController.text,
        dosage: _dosageController.text.isNotEmpty
            ? _dosageController.text
            : null,
        frequency: _frequencyController.text.isNotEmpty
            ? _frequencyController.text
            : null,
        startDate: _selectedDate,
        instructions: _instructionsController.text.isNotEmpty
            ? _instructionsController.text
            : null,
        prescribedBy:
            widget.medication?.prescribedBy ??
            FirebaseAuth.instance.currentUser?.uid,
        fileUrl: widget.medication?.fileUrl,
        createdAt: widget.medication?.createdAt ?? DateTime.now(),
      );

      context.read<MedicationBloc>().add(
        AddMedication(medication: medication, file: _selectedFile),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null
              ? 'addMedication'.tr()
              : 'medicationDetails'.tr(),
        ),
      ),
      body: BlocListener<MedicationBloc, MedicationState>(
        listener: (context, state) {
          if (state is MedicationOperationSuccess) {
            context.pop();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'medicationName'.tr()),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'required'.tr() : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dosageController,
                        decoration: InputDecoration(labelText: 'dosages'.tr()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _frequencyController,
                        decoration: InputDecoration(
                          labelText: 'frequency'.tr(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _startDateController,
                  decoration: InputDecoration(
                    labelText: 'startDate'.tr(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructionsController,
                  decoration: InputDecoration(labelText: 'instructions'.tr()),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),
                // File Upload Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          'prescriptionImage'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_selectedFile != null)
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: Text(
                              _selectedFile!.path
                                  .split(Platform.pathSeparator)
                                  .last,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () =>
                                  setState(() => _selectedFile = null),
                            ),
                          )
                        else if (widget.medication?.fileUrl != null)
                          ListTile(
                            leading: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                            title: Text('prescription'.tr()),
                            subtitle: const Text('Image uploaded'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _pickFile,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.upload_file),
                            label: Text('uploadPrescription'.tr()),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                BlocBuilder<MedicationBloc, MedicationState>(
                  builder: (context, state) {
                    if (state is MedicationLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      onPressed: _submit,
                      child: Text('save'.tr()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

