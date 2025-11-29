import 'dart:async';

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html_editor_enhanced/html_editor.dart';
// ... imports

// ... inside build method
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_state.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_instruction.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/ai_chat_panel.dart';

import '../widgets/selection_menu.dart';

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
  late HtmlEditorController _htmlController;
  late FocusNode _focusNode;
  late DateTime _selectedDate;
  PatientModel? _selectedPatient;
  bool _isLoaded = false;
  bool _isEditorLoaded = false;

  bool _isAIChatOpen = false;

  Timer? _autoSaveTimer;
  OverlayEntry? _overlayEntry;
  Offset? _lastTapDownPosition;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _htmlController = HtmlEditorController();
    _focusNode = FocusNode();
    _selectedDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    // _htmlController.dispose(); // HtmlEditorController doesn't have dispose method in some versions, check if needed
    _focusNode.dispose();
    _autoSaveTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    final OverlayState overlayState = Overlay.of(context);

    // Default position if tap position is missing
    double top = 100;
    double left = 100;

    if (_lastTapDownPosition != null) {
      top = _lastTapDownPosition!.dy - 60; // Show slightly above
      left = _lastTapDownPosition!.dx;

      // Boundary checks
      final screenSize = MediaQuery.of(context).size;
      if (left + 200 > screenSize.width) {
        left = screenSize.width - 210;
      }
      if (top < 80) {
        top = _lastTapDownPosition!.dy + 20; // Show below if too high
      }
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        left: left,
        child: SelectionMenu(
          onClose: () {
            _removeOverlay();
            _htmlController.clearFocus();
          },
          onApply: (instruction) async {
            final selection = await _htmlController.editorController!
                .evaluateJavascript(source: "window.getSelection().toString()");
            if (selection != null && selection.toString().isNotEmpty) {
              if (mounted) {
                context.read<AddEditClinicalReportBloc>().add(
                  AISelectionEditRequested(selection.toString(), instruction),
                );
              }
              _removeOverlay();
            }
          },
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  Future<void> _checkSelection() async {
    final selection = await _htmlController.editorController!
        .evaluateJavascript(source: "window.getSelection().toString()");

    if (selection != null && selection.toString().trim().isNotEmpty) {
      if (_overlayEntry == null && mounted) {
        _showOverlay(context);
      }
    } else {
      _removeOverlay();
    }
  }

  void _onEditorChange(String? content) {
    _triggerAutoSave();
  }

  void _triggerAutoSave() {
    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && widget.reportId != null) {
        _autoSaveClinicalReport();
      }
    });
  }

  Future<void> _autoSaveClinicalReport() async {
    if (_selectedPatient == null) return;

    final html = await _htmlController.getText();

    // Create temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/report_content_autosave.html');
    await tempFile.writeAsString(html);

    final report = ClinicalReport(
      id: widget.reportId!,
      patientId: _selectedPatient!.id,
      title: _titleController.text,
      description: html
          .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags for description
          .replaceAll('\n', ' ')
          .trim(),
      date: _selectedDate,
      documentUrls: [],
    );

    if (mounted) {
      context.read<AddEditClinicalReportBloc>().add(
        AutoSaveClinicalReport(report, jsonFile: tempFile),
      );
    }
  }

  Future<void> _saveClinicalReport() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedPatient == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('selectPatientError'.tr())));
        return;
      }

      final html = await _htmlController.getText();

      // Create temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/report_content.html');
      await tempFile.writeAsString(html);

      final newReport = ClinicalReport(
        id: widget.reportId ?? 'new_report_id',
        patientId: _selectedPatient!.id,
        title: _titleController.text,
        description: html
            .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
            .replaceAll('\n', ' ')
            .trim(), // Plain text summary
        date: _selectedDate,
        documentUrls: [], // Handled inside content now
      );

      if (mounted) {
        context.read<AddEditClinicalReportBloc>().add(
          SaveClinicalReport(newReport, jsonFile: tempFile),
        );
      }
    }
  }

  Future<void> _deleteClinicalReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'deleteReport'.tr(),
        ), // Ensure this key exists or use 'Delete Report'
        content: Text(
          'deleteReportConfirmation'.tr(),
        ), // Ensure this key exists
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

  // ignore: unused_element
  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      // Upload image
      final service = getIt<ClinicalReportService>();
      final uploadResult = await service.uploadImage(file);

      uploadResult.fold(
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading image: ${failure.message}'),
              ),
            );
          }
        },
        (url) {
          // Insert image URL into editor
          _htmlController.insertHtml(
            '<img src="$url" style="max-width: 100%;" />',
          );
        },
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
        if (state is AddEditClinicalReportLoaded) {
          if (state.pendingAISelectionEdit != null) {
            // Apply selection edit
            _htmlController.insertHtml(state.pendingAISelectionEdit!);

            context.read<AddEditClinicalReportBloc>().add(
              AISelectionEditConsumed(),
            );
          }

          if (state.isReviewingAIChanges) {
            _htmlController.setText(state.contentJson ?? '');
          } else if (state.contentJson != null &&
              state.originalContent == null &&
              !state.isAILoading) {
            if (_isLoaded && state.contentJson != null) {
              // Only update if explicitly needed, usually initial load handles it
              // But if we re-loaded, we might want to update.
              // _htmlController.setText(state.contentJson!);
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedPatient?.name ?? 'loading'.tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_selectedPatient != null)
                Text(
                  DateFormat.yMMMd().format(_selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: widget.reportId != null ? _deleteClinicalReport : null,
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveClinicalReport,
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

                  if (state.contentJson != null &&
                      state.contentJson!.isNotEmpty) {
                    // _htmlController.setText(state.contentJson!); // Handled by initialText
                  }
                } else if (widget.patientId != null &&
                    _selectedPatient == null) {
                  _selectedPatient = state.patients.firstWhere(
                    (p) => p.id == widget.patientId,
                    orElse: () => state.patients.first,
                  );
                }
                _isLoaded = true;
              }

              return Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
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
                            const SizedBox(height: 16),
                            Expanded(
                              child: Stack(
                                children: [
                                  Listener(
                                    onPointerDown: (event) {
                                      _lastTapDownPosition = event.position;
                                    },
                                    child: HtmlEditor(
                                      controller: _htmlController,
                                      htmlEditorOptions: HtmlEditorOptions(
                                        hint: 'startTyping'.tr(),
                                        shouldEnsureVisible: true,
                                        initialText: state.contentJson,
                                      ),
                                      htmlToolbarOptions: HtmlToolbarOptions(
                                        toolbarPosition:
                                            ToolbarPosition.aboveEditor,
                                        toolbarType:
                                            ToolbarType.nativeScrollable,
                                        customToolbarButtons: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _isAIChatOpen = !_isAIChatOpen;
                                              });
                                            },
                                            child: Icon(
                                              Icons.auto_awesome,
                                              color: _isAIChatOpen
                                                  ? Colors.blue
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      otherOptions: const OtherOptions(
                                        height: 500,
                                      ),
                                      callbacks: Callbacks(
                                        onInit: () {
                                          setState(() {
                                            _isEditorLoaded = true;
                                          });
                                          // Inject Google Fonts CSS
                                          _htmlController.editorController!
                                              .evaluateJavascript(
                                                source: """
                                            var link = document.createElement('link');
                                            link.href = 'https://fonts.googleapis.com/css?family=Roboto|Lato|Open+Sans|Montserrat|Raleway|Merriweather|Playfair+Display|Courier+Prime';
                                            link.rel = 'stylesheet';
                                            document.head.appendChild(link);
                                          """,
                                              );
                                        },
                                        onChangeContent: (String? changed) {
                                          _onEditorChange(changed);
                                        },
                                        onMouseUp: () {
                                          _checkSelection();
                                        },
                                        onKeyUp: (code) {
                                          _checkSelection();
                                        },
                                      ),
                                    ),
                                  ),
                                  if (!_isEditorLoaded)
                                    Container(
                                      color: Colors.white.withOpacity(0.8),
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_isAIChatOpen)
                    AIChatPanel(
                      onClose: () {
                        setState(() {
                          _isAIChatOpen = false;
                        });
                      },
                      // hasSelection: _hasSelection, // Removed selection check for now
                      hasSelection:
                          true, // Always allow asking about selection if user wants, or check via JS
                      onSaveInstruction: (label, instruction) {
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId != null) {
                          final newInstruction = ClinicalReportInstruction(
                            id: '', // Let API generate ID
                            userId: userId,
                            label: label,
                            instruction: instruction,
                          );
                          context.read<AddEditClinicalReportBloc>().add(
                            SaveInstruction(newInstruction),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('User not logged in')),
                          );
                        }
                      },
                      onDeleteInstruction: (instructionId) {
                        context.read<AddEditClinicalReportBloc>().add(
                          DeleteInstruction(instructionId),
                        );
                      },
                      onRefineInstruction: (text) {
                        context.read<AddEditClinicalReportBloc>().add(
                          AIRefineInstructionRequested(text),
                        );
                      },
                      onRefineClinicalData: (text) {
                        context.read<AddEditClinicalReportBloc>().add(
                          AIRefineClinicalDataRequested(text),
                        );
                      },
                      onGenerate: (instruction, clinicalData) async {
                        final selection =
                            (await _htmlController.editorController
                                    ?.evaluateJavascript(
                                      source:
                                          "window.getSelection().toString()",
                                    ))
                                ?.toString() ??
                            '';
                        if (!mounted) return;
                        if (selection.isNotEmpty) {
                          this.context.read<AddEditClinicalReportBloc>().add(
                            AISelectionEditRequested(
                              selection,
                              instruction,
                              clinicalData: clinicalData,
                            ),
                          );
                        } else {
                          this.context.read<AddEditClinicalReportBloc>().add(
                            AIGenerateContentRequested(
                              instruction,
                              clinicalData: clinicalData,
                            ),
                          );
                        }
                      },
                      onInsert: (content) {
                        _htmlController.insertHtml(content);
                        context.read<AddEditClinicalReportBloc>().add(
                          AIClearGeneratedContent(),
                        );
                      },
                      onDiscard: () {
                        context.read<AddEditClinicalReportBloc>().add(
                          AIClearGeneratedContent(),
                        );
                      },
                    ),
                ],
              );
            }

            return const Center(child: Text('Something went wrong.'));
          },
        ),
      ),
    );
  }
}
