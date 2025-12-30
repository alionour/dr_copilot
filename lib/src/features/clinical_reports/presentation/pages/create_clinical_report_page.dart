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

class CreateClinicalReportPage extends StatelessWidget {
  const CreateClinicalReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AddEditClinicalReportBloc>()
        ..add(const LoadAddEditClinicalReport(null)),
      child: const CreateClinicalReportView(),
    );
  }
}

class CreateClinicalReportView extends StatefulWidget {
  const CreateClinicalReportView({super.key});

  @override
  State<CreateClinicalReportView> createState() =>
      _CreateClinicalReportViewState();
}

class _CreateClinicalReportViewState extends State<CreateClinicalReportView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  PatientModel? _selectedPatient;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _selectedDate = DateTime.now(); // Keep local time for display
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _createClinicalReport() {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatient == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('selectPatientError'.tr())));
        return;
      }

      final title = _titleController.text.trim().isEmpty
          ? 'clinicalReportDefaultTitle'.tr(
              args: [DateFormat.yMMMd().format(_selectedDate)],
            )
          : _titleController.text;

      final newReport = ClinicalReport(
        id: 'new_report_id',
        patientId: _selectedPatient!.id,
        title: title,
        description: '',
        date: _selectedDate,
        documentUrls: [],
      );

      context.read<AddEditClinicalReportBloc>().add(
            SaveClinicalReport(newReport),
          );
    }
  }

  void _showPatientSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return BlocProvider.value(
          value: this.context.read<AddEditClinicalReportBloc>(),
          child: StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('selectPatient'.tr()),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'search'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          context.read<AddEditClinicalReportBloc>().add(
                                SearchPatients(value),
                              );
                        },
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: BlocBuilder<AddEditClinicalReportBloc,
                            AddEditClinicalReportState>(
                          builder: (context, state) {
                            if (state is AddEditClinicalReportLoaded) {
                              if (state.patients.isEmpty) {
                                return Center(
                                  child: Text('noPatientsFound'.tr()),
                                );
                              }
                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: state.patients.length,
                                itemBuilder: (context, index) {
                                  final patient = state.patients[index];
                                  return ListTile(
                                    title: Text(patient.name),
                                    subtitle: Text(
                                      patient.phoneNumber ??
                                          'noPhoneNumber'.tr(),
                                    ),
                                    onTap: () {
                                      this.setState(() {
                                        _selectedPatient = patient;
                                      });
                                      Navigator.of(context).pop();
                                    },
                                  );
                                },
                              );
                            }
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('cancel'.tr()),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditClinicalReportBloc, AddEditClinicalReportState>(
      listener: (context, state) {
        if (state is AddEditClinicalReportSuccess) {
          if (state.reportId != null) {
            context.go('/clinical_reports/${state.reportId}/edit');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('reportCreatedIdMissing'.tr())),
            );
            context.pop();
          }
        }
        if (state is AddEditClinicalReportError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('createClinicalReport'.tr())),
        body:
            BlocBuilder<AddEditClinicalReportBloc, AddEditClinicalReportState>(
          builder: (context, state) {
            if (state is AddEditClinicalReportLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AddEditClinicalReportLoaded) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'patient'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showPatientSelectionDialog(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _selectedPatient?.name ??
                                      'selectPatient'.tr(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedPatient == null
                                        ? Colors.grey.shade600
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'clinicalReportTitle'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'clinicalReportTitle'.tr(),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'clinicalReportDate'.tr(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              DateFormat.yMMMd().add_jm().format(
                                    _selectedDate,
                                  ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _createClinicalReport,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'createReport'.tr(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(child: Text('somethingWentWrong'.tr()));
          },
        ),
      ),
    );
  }
}
