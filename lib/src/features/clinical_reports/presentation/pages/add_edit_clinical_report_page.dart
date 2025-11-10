
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_state.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';


final getIt = GetIt.instance;

class AddEditClinicalReportPage extends StatelessWidget {
  final String? reportId;
  final String? patientId;

  const AddEditClinicalReportPage({super.key, this.reportId, this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AddEditClinicalReportBloc>()..add(LoadAddEditClinicalReport(reportId)),
      child: BlocListener<AddEditClinicalReportBloc, AddEditClinicalReportState>(
        listener: (context, state) {
          if (state is AddEditClinicalReportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(reportId == null ? 'clinicalReportAddedSuccessfully'.tr() : 'clinicalReportUpdatedSuccessfully'.tr())),
            );
            context.pop();
          }
          if (state is AddEditClinicalReportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}')),
            );
          }
        },
        child: AddEditClinicalReportView(reportId: reportId, patientId: patientId),
      ),
    );
  }
}

class AddEditClinicalReportView extends StatefulWidget {
  final String? reportId;
  final String? patientId;

  const AddEditClinicalReportView({super.key, this.reportId, this.patientId});

  @override
  State<AddEditClinicalReportView> createState() => _AddEditClinicalReportViewState();
}

class _AddEditClinicalReportViewState extends State<AddEditClinicalReportView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  PatientModel? _selectedPatient;
  final List<String> _documentUrls = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveClinicalReport() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('selectPatientError'.tr())),
        );
        return;
      }

      final newReport = ClinicalReport(
        id: widget.reportId ?? 'new_report_id',
        patientId: _selectedPatient!.id,
        title: _titleController.text,
        description: _descriptionController.text,
        date: _selectedDate,
        documentUrls: _documentUrls,
      );

      context.read<AddEditClinicalReportBloc>().add(SaveClinicalReport(newReport));
    }
  }

  void _showPatientSelectionDialog(BuildContext context, List<PatientModel> patients) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('selectPatient'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return ListTile(
                  title: Text(patient.name),
                  onTap: () {
                    setState(() {
                      _selectedPatient = patient;
                    });
                    context.pop();
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _addDocumentUrl() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('addDocument'.tr()),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: 'documentUrl'.tr()),
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    _documentUrls.add(controller.text);
                  });
                }
                context.pop();
              },
              child: Text('add'.tr()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reportId == null ? 'addClinicalReport'.tr() : 'editClinicalReport'.tr()),
      ),
      body: BlocBuilder<AddEditClinicalReportBloc, AddEditClinicalReportState>(
        builder: (context, state) {
          if (state is AddEditClinicalReportLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AddEditClinicalReportLoaded) {
            if (state.report != null && _titleController.text.isEmpty) {
              _titleController.text = state.report!.title;
              _descriptionController.text = state.report!.description;
              _selectedDate = state.report!.date;
              _documentUrls.addAll(state.report!.documentUrls);
              _selectedPatient = state.patients.firstWhere((p) => p.id == state.report!.patientId);
            } else if (widget.patientId != null && _selectedPatient == null) {
              _selectedPatient = state.patients.firstWhere((p) => p.id == widget.patientId);
            }

            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(_selectedPatient?.name ?? 'selectPatient'.tr()),
                      subtitle: Text('patient'.tr()),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () => _showPatientSelectionDialog(context, state.patients),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'clinicalReportTitle'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'clinicalReportTitleRequired'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'clinicalReportDescription'.tr(),
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'clinicalReportDescriptionRequired'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(DateFormat.yMd().format(_selectedDate)),
                      subtitle: Text('clinicalReportDate'.tr()),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'documentUrls'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ..._documentUrls.map((url) => ListTile(
                          title: Text(url.split('/').last),
                          subtitle: Text(url),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _documentUrls.remove(url);
                              });
                            },
                          ),
                        )),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text('addDocument'.tr()),
                        onPressed: _addDocumentUrl,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveClinicalReport,
                      child: Text('saveClinicalReport'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Something went wrong.'));
        },
      ),
    );
  }
}

