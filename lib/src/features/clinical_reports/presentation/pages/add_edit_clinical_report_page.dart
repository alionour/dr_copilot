import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/google_docs_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_state.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';

// WebView imports
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

final getIt = GetIt.instance;

class AddEditClinicalReportPage extends StatelessWidget {
  final String? reportId;
  final String? patientId;

  const AddEditClinicalReportPage({super.key, this.reportId, this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<AddEditClinicalReportBloc>()
            ..add(LoadAddEditClinicalReport(reportId)),
      child: AddEditClinicalReportView(
        reportId: reportId,
        patientId: patientId,
      ),
    );
  }
}

class AddEditClinicalReportView extends StatefulWidget {
  final String? reportId;
  final String? patientId;

  const AddEditClinicalReportView({super.key, this.reportId, this.patientId});

  @override
  State<AddEditClinicalReportView> createState() =>
      _AddEditClinicalReportViewState();
}

class _AddEditClinicalReportViewState extends State<AddEditClinicalReportView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  PatientModel? _selectedPatient;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();

    super.dispose();
  }

  Future<void> _finalizeReport(String reportId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalize Report'),
        content: const Text(
          'Are you sure you want to finalize this report? This action is irreversible. The report will be saved as read-only and the Google Doc will be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finalize'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        final state = context.read<AddEditClinicalReportBloc>().state;
        if (state is AddEditClinicalReportLoaded &&
            state.report?.googleDocId != null) {
          final service = getIt<GoogleDocsService>();
          final html = await service.exportAsHtml(state.report!.googleDocId!);

          if (mounted) {
            context.read<AddEditClinicalReportBloc>().add(
              FinalizeClinicalReport(reportId, html),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to export report: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteClinicalReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('deleteReport'.tr()),
        content: Text('deleteReportConfirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true && mounted && widget.reportId != null) {
      context.read<AddEditClinicalReportBloc>().add(
        DeleteClinicalReport(widget.reportId!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddEditClinicalReportBloc, AddEditClinicalReportState>(
      listener: (context, state) {
        if (state is AddEditClinicalReportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.reportId == null
                    ? 'clinicalReportAddedSuccessfully'.tr()
                    : 'clinicalReportUpdatedSuccessfully'.tr(),
              ),
            ),
          );
          context.pop();
        }
        if (state is AddEditClinicalReportError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${state.message}')));
        }
        if (state is AddEditClinicalReportLoaded) {}
      },
      child: Scaffold(
        appBar: AppBar(
          title:
              BlocBuilder<
                AddEditClinicalReportBloc,
                AddEditClinicalReportState
              >(
                builder: (context, state) {
                  if (state is AddEditClinicalReportLoaded &&
                      state.report?.googleDocId != null) {
                    // Edit Mode: Show Editable Title in AppBar
                    return TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        color: Colors.black, // Adjust based on theme if needed
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Report Title',
                      ),
                    );
                  }
                  // Create Mode: Show Selected Patient or Default Title
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state is AddEditClinicalReportLoaded &&
                                _selectedPatient != null
                            ? _selectedPatient!.name
                            : 'New Clinical Report',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMd().format(_selectedDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  );
                },
              ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.reportId != null ? _deleteClinicalReport : null,
            ),
            BlocBuilder<AddEditClinicalReportBloc, AddEditClinicalReportState>(
              builder: (context, state) {
                if (state is AddEditClinicalReportLoaded &&
                    state.report != null &&
                    !state.report!.isFinalized) {
                  return IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    tooltip: 'Finalize Report',
                    onPressed: () => _finalizeReport(state.report!.id),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<AddEditClinicalReportBloc, AddEditClinicalReportState>(
          builder: (context, state) {
            if (state is AddEditClinicalReportLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AddEditClinicalReportLoaded) {
              if (!_isLoaded) {
                if (state.report != null) {
                  _titleController.text = state.report!.title;
                  _selectedDate = state.report!.date;
                  _selectedPatient = state.patients.firstWhere(
                    (p) => p.id == state.report!.patientId,
                    orElse: () => state.patients.first,
                  );
                } else if (widget.patientId != null &&
                    _selectedPatient == null) {
                  _selectedPatient = state.patients.firstWhere(
                    (p) => p.id == widget.patientId,
                    orElse: () => state.patients.first,
                  );
                }
                _isLoaded = true;
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Show form fields ONLY in creation mode (no googleDocId)
                      if (state.report?.googleDocId == null) ...[
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
                        // Patient selection dropdown
                        DropdownButtonFormField<PatientModel>(
                          value: _selectedPatient,
                          decoration: InputDecoration(
                            labelText: 'selectPatient'.tr(),
                            border: const OutlineInputBorder(),
                          ),
                          items: state.patients.map((patient) {
                            return DropdownMenuItem(
                              value: patient,
                              child: Text(patient.name),
                            );
                          }).toList(),
                          onChanged: (patient) {
                            setState(() {
                              _selectedPatient = patient;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'pleaseSelectPatient'.tr();
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      // WebView or create button
                      if (state.report?.googleDocId != null)
                        Expanded(
                          child: Stack(
                            children: [
                              if (state.report?.isFinalized == true)
                                // Show read-only HTML content
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: HtmlWidget(
                                    state.report!.content ?? '',
                                    textStyle: const TextStyle(fontSize: 16),
                                  ),
                                )
                              else if (state.report?.googleDocId != null)
                                // Show WebView with warning and browser option
                                Column(
                                  children: [
                                    // Warning Banner
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      color: Colors.orange.shade100,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange.shade900,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'webviewLimitationsWarning'
                                                      .tr(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        Colors.orange.shade900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'editingInBrowser'.tr(),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        Colors.orange.shade900,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              final url =
                                                  getIt<GoogleDocsService>()
                                                      .getEditorUrl(
                                                        state
                                                            .report!
                                                            .googleDocId!,
                                                        languageCode: context
                                                            .locale
                                                            .languageCode,
                                                      );
                                              final uri = Uri.parse(url);
                                              if (await canLaunchUrl(uri)) {
                                                await launchUrl(
                                                  uri,
                                                  mode: LaunchMode
                                                      .externalApplication,
                                                );
                                              }
                                            },
                                            icon: const Icon(
                                              Icons.open_in_new,
                                              size: 16,
                                            ),
                                            label: Text('openInBrowser'.tr()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orange.shade700,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 8,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // WebView
                                    Expanded(
                                      child: InAppWebView(
                                        initialUrlRequest: URLRequest(
                                          url: WebUri(
                                            getIt<GoogleDocsService>()
                                                .getEditorUrl(
                                                  state.report!.googleDocId!,
                                                  languageCode: context
                                                      .locale
                                                      .languageCode,
                                                ),
                                          ),
                                        ),
                                        initialSettings: InAppWebViewSettings(
                                          transparentBackground: false,
                                          safeBrowsingEnabled: true,
                                          isInspectable: kDebugMode,
                                          incognito: true,
                                          cacheEnabled: false,
                                          javaScriptCanOpenWindowsAutomatically:
                                              true,
                                          domStorageEnabled: true,
                                          databaseEnabled: true,
                                          thirdPartyCookiesEnabled: true,
                                          sharedCookiesEnabled: true,
                                          userAgent:
                                              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                        ),
                                        onConsoleMessage:
                                            (controller, consoleMessage) {
                                              debugPrint(
                                                '[WebView Console] ${consoleMessage.message}',
                                              );
                                            },
                                        onCreateWindow:
                                            (
                                              controller,
                                              createWindowRequest,
                                            ) async {
                                              debugPrint(
                                                '[WebView] onCreateWindow requested',
                                              );
                                              return true;
                                            },
                                      ),
                                    ),
                                  ],
                                )
                              else
                                // Show loading indicator
                                const Center(
                                  child: CircularProgressIndicator(),
                                ),
                            ],
                          ),
                        )
                      else
                        // New report: Show create button
                        Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.description_outlined,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Fill in the details above and click \"Create Report\" to start editing',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      final newReport = ClinicalReport(
                                        id: '',
                                        patientId: _selectedPatient!.id,
                                        title: _titleController.text,
                                        description: '',
                                        date: _selectedDate,
                                        googleDocId: null,
                                        isFinalized: false,
                                      );

                                      context
                                          .read<AddEditClinicalReportBloc>()
                                          .add(SaveClinicalReport(newReport));
                                    }
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Report'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return const Center(child: Text('Something went wrong.'));
          },
        ),
      ),
    );
  }
}
