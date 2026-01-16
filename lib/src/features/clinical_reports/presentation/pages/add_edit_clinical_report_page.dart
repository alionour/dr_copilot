import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

import 'package:url_launcher/url_launcher.dart';

// WebView imports
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/widgets/body_map_widget.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/widgets/body_map_3d_webview_widget.dart';

final getIt = GetIt.instance;

class AddEditClinicalReportPage extends StatelessWidget {
  final String? reportId;
  final String? patientId;

  const AddEditClinicalReportPage({super.key, this.reportId, this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AddEditClinicalReportBloc>()
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
          'Are you sure you want to finalize this report? This action is irreversible. The report will be saved as read-only and you will not be able to edit it again.',
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
      context.read<AddEditClinicalReportBloc>().add(
            FinalizeClinicalReport(reportId),
          );
    }
  }

  // Undo/Redo Stacks
  final List<List<BodyMarker>> _undoStack = [];
  final List<List<BodyMarker>> _redoStack = [];

  void _pushToUndo(List<BodyMarker> currentMarkers) {
    _undoStack.add(List.from(currentMarkers));
    _redoStack.clear(); // Clear redo stack on new action
  }

  void _undo(List<BodyMarker> currentMarkers) {
    if (_undoStack.isEmpty) return;
    final previousMarkers = _undoStack.removeLast();
    _redoStack.add(List.from(currentMarkers));
    context
        .read<AddEditClinicalReportBloc>()
        .add(UpdateBodyMarkers(previousMarkers));
  }

  void _redo(List<BodyMarker> currentMarkers) {
    if (_redoStack.isEmpty) return;
    final nextMarkers = _redoStack.removeLast();
    _undoStack.add(List.from(currentMarkers));
    context
        .read<AddEditClinicalReportBloc>()
        .add(UpdateBodyMarkers(nextMarkers));
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
      },
      child: DefaultTabController(
        length: 3,
        child: Builder(builder: (tabContext) {
          // Use Builder to get tabContext for TabController if needed,
          // or just rely on DefaultTabController access
          return Scaffold(
            appBar: AppBar(
              title: BlocBuilder<AddEditClinicalReportBloc,
                  AddEditClinicalReportState>(
                builder: (context, state) {
                  if (state is AddEditClinicalReportLoaded &&
                      state.report?.googleDocId != null) {
                    return TextField(
                      controller: _titleController,
                      enabled: !state.report!.isFinalized,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Report Title',
                      ),
                    );
                  }
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
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Report'),
                  Tab(text: 'Body Map (2D)'),
                  Tab(text: 'Body Map (3D)'),
                ],
              ),
              actions: [
                // Undo/Redo Buttons (Only show when report is loaded)
                BlocBuilder<AddEditClinicalReportBloc,
                    AddEditClinicalReportState>(
                  builder: (context, state) {
                    if (state is AddEditClinicalReportLoaded &&
                        state.report != null &&
                        !state.report!.isFinalized) {
                      return Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.undo),
                            tooltip: 'Undo (Ctrl+Z)',
                            onPressed: _undoStack.isNotEmpty
                                ? () => _undo(state.report!.bodyMapPoints)
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.redo),
                            tooltip: 'Redo (Ctrl+Y)',
                            onPressed: _redoStack.isNotEmpty
                                ? () => _redo(state.report!.bodyMapPoints)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            tooltip: 'Finalize Report',
                            onPressed: () => _finalizeReport(state.report!.id),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            body: BlocBuilder<AddEditClinicalReportBloc,
                AddEditClinicalReportState>(
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

                  return TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Tab 1: Form / WebView
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
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
                                DropdownButtonFormField<PatientModel>(
                                  initialValue: _selectedPatient,
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
                              if (state.report?.googleDocId != null)
                                Expanded(
                                  child: Stack(
                                    children: [
                                      if (state.report?.googleDocId != null)
                                        Column(
                                          children: [
                                            if (state.report?.isFinalized ==
                                                true)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                color: Colors.blue.shade100,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.info_outline,
                                                      color:
                                                          Colors.blue.shade900,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'This report is read-only.',
                                                        style: TextStyle(
                                                          color: Colors
                                                              .blue.shade900,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (state.report?.isFinalized ==
                                                false)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                                color: Colors.orange.shade100,
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .warning_amber_rounded,
                                                      color: Colors
                                                          .orange.shade900,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'webviewLimitationsWarning'
                                                                .tr(),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors
                                                                  .orange
                                                                  .shade900,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Text(
                                                            'editingInBrowser'
                                                                .tr(),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .orange
                                                                  .shade900,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    ElevatedButton.icon(
                                                      onPressed: () async {
                                                        final url = getIt<
                                                                GoogleDocsService>()
                                                            .getEditorUrl(
                                                          state.report!
                                                              .googleDocId!,
                                                          languageCode: context
                                                              .locale
                                                              .languageCode,
                                                        );
                                                        final uri = Uri.parse(
                                                          url,
                                                        );
                                                        if (await canLaunchUrl(
                                                          uri,
                                                        )) {
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
                                                      label: Text(
                                                        'openInBrowser'.tr(),
                                                      ),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor: Colors
                                                            .orange.shade700,
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            Expanded(
                                              child: InAppWebView(
                                                initialUrlRequest: URLRequest(
                                                  url: WebUri(
                                                    state.report!.isFinalized
                                                        ? getIt<GoogleDocsService>()
                                                            .getPreviewUrl(
                                                            state.report!
                                                                .googleDocId!,
                                                            languageCode: context
                                                                .locale
                                                                .languageCode,
                                                          )
                                                        : getIt<GoogleDocsService>()
                                                            .getEditorUrl(
                                                            state.report!
                                                                .googleDocId!,
                                                            languageCode: context
                                                                .locale
                                                                .languageCode,
                                                          ),
                                                  ),
                                                ),
                                                initialSettings:
                                                    InAppWebViewSettings(
                                                  transparentBackground: false,
                                                  safeBrowsingEnabled: true,
                                                  isInspectable: kDebugMode,
                                                  incognito: false,
                                                  cacheEnabled: true,
                                                  javaScriptCanOpenWindowsAutomatically:
                                                      true,
                                                  domStorageEnabled: true,
                                                  databaseEnabled: true,
                                                  thirdPartyCookiesEnabled:
                                                      true,
                                                  sharedCookiesEnabled: true,
                                                  userAgent:
                                                      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                                                ),
                                                onConsoleMessage: (
                                                  controller,
                                                  consoleMessage,
                                                ) {
                                                  debugPrint(
                                                    '[WebView Console] ${consoleMessage.message}',
                                                  );
                                                },
                                                onCreateWindow: (
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
                                        const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                    ],
                                  ),
                                )
                              else
                                Expanded(
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.description_outlined,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Fill in the details above and click "Create Report" to start editing',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(color: Colors.grey),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            if (_formKey.currentState!
                                                .validate()) {
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
                                                  .read<
                                                      AddEditClinicalReportBloc>()
                                                  .add(
                                                    SaveClinicalReport(
                                                        newReport),
                                                  );
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
                      ),

                      // Tab 2: Body Map
                      if (state.report != null)
                        CallbackShortcuts(
                          bindings: {
                            const SingleActivator(LogicalKeyboardKey.keyZ,
                                    control: true):
                                () => _undo(state.report!.bodyMapPoints),
                            const SingleActivator(LogicalKeyboardKey.keyY,
                                    control: true):
                                () => _redo(state.report!.bodyMapPoints),
                            // Mac support for Redo (Cmd+Shift+Z)
                            const SingleActivator(LogicalKeyboardKey.keyZ,
                                    control: true, shift: true):
                                () => _redo(state.report!.bodyMapPoints),
                          },
                          child: Focus(
                            autofocus: true,
                            child: BodyMapWidget(
                              markers: state.report!.bodyMapPoints,
                              onMarkerAdded: (marker) {
                                final currentMarkers = List<BodyMarker>.from(
                                  state.report!.bodyMapPoints,
                                );
                                _pushToUndo(currentMarkers); // Save state
                                currentMarkers.add(marker);
                                context.read<AddEditClinicalReportBloc>().add(
                                      UpdateBodyMarkers(currentMarkers),
                                    );
                              },
                              onMarkerRemoved: (markerId) {
                                final currentMarkers = List<BodyMarker>.from(
                                  state.report!.bodyMapPoints,
                                );
                                _pushToUndo(currentMarkers); // Save state
                                currentMarkers
                                    .removeWhere((m) => m.id == markerId);
                                context.read<AddEditClinicalReportBloc>().add(
                                      UpdateBodyMarkers(currentMarkers),
                                    );
                              },
                              onMarkerUpdated: (updatedMarker) {
                                final currentMarkers = List<BodyMarker>.from(
                                  state.report!.bodyMapPoints,
                                );
                                final index = currentMarkers.indexWhere(
                                  (m) => m.id == updatedMarker.id,
                                );
                                if (index != -1) {
                                  _pushToUndo(currentMarkers); // Save state
                                  currentMarkers[index] = updatedMarker;
                                  context.read<AddEditClinicalReportBloc>().add(
                                        UpdateBodyMarkers(currentMarkers),
                                      );
                                }
                              },
                              isReadOnly: state.report!.isFinalized,
                            ),
                          ),
                        ),
                      // Tab 3: Body Map (3D)
                      if (state.report != null)
                        BodyMap3DWebViewWidget(
                          markers: state.report!.bodyMapPoints,
                          onMarkerAdded: (marker) {
                            final currentMarkers = List<BodyMarker>.from(
                              state.report!.bodyMapPoints,
                            );
                            // Ensure marker has 3D view set if not already
                            final m = marker.copyWith(view: '3d');
                            _pushToUndo(currentMarkers);
                            currentMarkers.add(m);
                            context.read<AddEditClinicalReportBloc>().add(
                                  UpdateBodyMarkers(currentMarkers),
                                );
                          },
                          onMarkerRemoved: (markerId) {
                            final currentMarkers = List<BodyMarker>.from(
                              state.report!.bodyMapPoints,
                            );
                            _pushToUndo(currentMarkers);
                            currentMarkers.removeWhere((m) => m.id == markerId);
                            context.read<AddEditClinicalReportBloc>().add(
                                  UpdateBodyMarkers(currentMarkers),
                                );
                          },
                          onMarkerUpdated: (updatedMarker) {
                            final currentMarkers = List<BodyMarker>.from(
                              state.report!.bodyMapPoints,
                            );
                            final index = currentMarkers.indexWhere(
                              (m) => m.id == updatedMarker.id,
                            );
                            if (index != -1) {
                              _pushToUndo(currentMarkers);
                              currentMarkers[index] = updatedMarker;
                              context.read<AddEditClinicalReportBloc>().add(
                                    UpdateBodyMarkers(currentMarkers),
                                  );
                            }
                          },
                          isReadOnly: state.report!.isFinalized,
                        )
                      else
                        const Center(
                          child: Text(
                            'Please create the report first to access the 3D Body Map.',
                          ),
                        ),
                    ],
                  );
                }

                return const Center(child: Text('Something went wrong.'));
              },
            ),
          );
        }),
      ),
    );
  }
}
