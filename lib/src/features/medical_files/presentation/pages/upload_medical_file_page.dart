import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/medical_files/domain/models/medical_file_model.dart';
import 'package:dr_copilot/src/features/medical_files/presentation/bloc/medical_file_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/core/helper/safe_click.dart';


class UploadMedicalFilePage extends StatefulWidget {
  final String patientId;
  final MedicalFileModel? existingFile;

  const UploadMedicalFilePage({super.key, required this.patientId, this.existingFile});

  @override
  State<UploadMedicalFilePage> createState() => _UploadMedicalFilePageState();
}

class _UploadMedicalFilePageState extends State<UploadMedicalFilePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedType = 'X-Ray';
  File? _selectedFile;
  DateTime _selectedDate = DateTime.now();

  // Dynamic key-value pairs
  final List<MapEntry<TextEditingController, TextEditingController>>
  _keyValueControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingFile != null) {
      final file = widget.existingFile!;
      _titleController.text = file.title;
      _descriptionController.text = file.description ?? '';
      _selectedType = file.type;
      _selectedDate = file.date;
      if (file.metadata != null) {
        file.metadata!.forEach((key, value) {
          final keyController = TextEditingController(text: key);
          final valueController = TextEditingController(text: value);
          _keyValueControllers.add(MapEntry(keyController, valueController));
        });
      }
    }
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    for (var entry in _keyValueControllers) {
      entry.key.dispose();
      entry.value.dispose();
    }
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

  void _addKeyPair() {
    setState(() {
      _keyValueControllers.add(
        MapEntry(TextEditingController(), TextEditingController()),
      );
    });
  }

  void _removeKeyPair(int index) {
    setState(() {
      final entry = _keyValueControllers.removeAt(index);
      entry.key.dispose();
      entry.value.dispose();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedFile == null && _keyValueControllers.isEmpty && widget.existingFile?.fileUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectionArea(child: Text(
              'Please upload a file OR add at least one value pair.',
            )),
          ),
        );
        return;
      }

      final Map<String, String> metadata = {};
      for (var entry in _keyValueControllers) {
        if (entry.key.text.isNotEmpty) {
          metadata[entry.key.text] = entry.value.text;
        }
      }

      final isEdit = widget.existingFile != null;

      final medicalFile = MedicalFileModel(
        id: isEdit ? widget.existingFile!.id : const Uuid().v4(),
        patientId: widget.patientId,
        clinicId: isEdit ? widget.existingFile!.clinicId : OwnerNotifier().clinicId!,
        title: _titleController.text,
        type: _selectedType,
        fileUrl: isEdit ? widget.existingFile!.fileUrl : null, // Will be set by Bloc if file exists and changed
        date: _selectedDate,
        description: _descriptionController.text,
        uploadedBy: isEdit ? widget.existingFile!.uploadedBy : (FirebaseAuth.instance.currentUser?.uid ?? 'unknown'),
        metadata: metadata.isNotEmpty ? metadata : null,
        createdAt: isEdit ? widget.existingFile!.createdAt : DateTime.now(),
      );

      if (isEdit) {
        context.read<MedicalFileBloc>().add(
          UpdateMedicalFile(medicalFile: medicalFile, file: _selectedFile),
        );
      } else {
        context.read<MedicalFileBloc>().add(
          AddMedicalFile(medicalFile: medicalFile, file: _selectedFile),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingFile != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'editMedicalRecord'.tr() : 'Add Medical Record')),
      body: BlocListener<MedicalFileBloc, MedicalFileState>(
        listener: (context, state) {
          if (state is MedicalFileOperationSuccess) {
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
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: ['X-Ray', 'Lab Report', 'MRI', 'Prescription', 'Other']
                      .map(
                        (type) =>
                            DropdownMenuItem(value: type, child: Text(type)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _selectedType = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Chest X-Ray or Blood Test',
                  ),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // File Upload Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Attachment (Optional)',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                        else if (widget.existingFile?.fileUrl != null)
                          ListTile(
                            leading: const Icon(Icons.link),
                            title: const Text('Existing File Uploaded'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: _pickFile,
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Select File (Image/PDF)'),
                          ),
                        const Text(
                          'Max 20MB. JPG, PNG, PDF.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Values Pair Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Structured Data (Optional)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              onPressed: _addKeyPair,
                              icon: const Icon(Icons.add_circle),
                            ),
                          ],
                        ),
                        if (_keyValueControllers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'Add key-value pairs like "Hemoglobin: 13.5"',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ...List.generate(_keyValueControllers.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _keyValueControllers[index].key,
                                    decoration: const InputDecoration(
                                      labelText: 'Label',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller:
                                        _keyValueControllers[index].value,
                                    decoration: const InputDecoration(
                                      labelText: 'Value',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeKeyPair(index),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                BlocBuilder<MedicalFileBloc, MedicalFileState>(
                  builder: (context, state) {
                    if (state is MedicalFileLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ElevatedButton(
                      onPressed: _submit.throttle(),
                      child: const Text('Save'),
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

