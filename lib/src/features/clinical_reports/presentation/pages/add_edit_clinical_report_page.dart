import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_quill/flutter_quill.dart';
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
  late QuillController _quillController;
  late FocusNode _focusNode;
  late DateTime _selectedDate;
  PatientModel? _selectedPatient;
  bool _isLoaded = false;

  bool _isAIChatOpen = false;
  bool _hasSelection = false;
  Timer? _autoSaveTimer;
  OverlayEntry? _overlayEntry;
  final GlobalKey _editorKey = GlobalKey();
  Offset? _lastTapDownPosition;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quillController = QuillController.basic();
    _focusNode = FocusNode();
    _selectedDate = DateTime.now();

    _quillController.addListener(_onEditorChange);
  }

  @override
  void dispose() {
    _quillController.removeListener(_onEditorChange);
    _titleController.dispose();
    _quillController.dispose();
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
    final RenderBox? renderBox =
        _editorKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    // Use last tap position if available, otherwise fallback to top right
    double top;
    double left;

    if (_lastTapDownPosition != null) {
      // Adjust for overlay coordinates if needed, but usually global position is fine
      // We want it slightly below the cursor
      top = _lastTapDownPosition!.dy + 20;
      left = _lastTapDownPosition!.dx;

      // Ensure it doesn't go off screen
      final screenSize = MediaQuery.of(context).size;
      if (left + 200 > screenSize.width) {
        left = screenSize.width - 210;
      }
      if (top + 250 > screenSize.height) {
        top = _lastTapDownPosition!.dy - 260; // Show above if too low
      }
    } else {
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);
      top = offset.dy - 50;
      left = offset.dx + size.width - 220;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        left: left,
        child: SelectionMenu(
          onClose: () {
            _removeOverlay();
            // Deselect? Maybe not.
          },
          onApply: (instruction) {
            if (_hasSelection) {
              final selection = _quillController.document.getPlainText(
                _quillController.selection.baseOffset,
                _quillController.selection.extentOffset -
                    _quillController.selection.baseOffset,
              );
              context.read<AddEditClinicalReportBloc>().add(
                AISelectionEditRequested(selection, instruction),
              );
              _removeOverlay();
            }
          },
        ),
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  void _onEditorChange() {
    final hasSelection = !_quillController.selection.isCollapsed;
    if (hasSelection != _hasSelection) {
      setState(() {
        _hasSelection = hasSelection;
      });
    }
    _triggerAutoSave();

    if (hasSelection) {
      // Debounce or just show?
      // We might want to wait a bit or check if selection is stable.
      // For now, show immediately if not shown.
      if (_overlayEntry == null) {
        _showOverlay(context);
      }
    } else {
      _removeOverlay();
    }
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

    // Convert Delta to JSON
    final deltaJson = jsonEncode(_quillController.document.toDelta().toJson());

    // Create temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/report_content_autosave.json');
    await tempFile.writeAsString(deltaJson);

    final report = ClinicalReport(
      id: widget.reportId!,
      patientId: _selectedPatient!.id,
      title: _titleController.text,
      description: _quillController.document
          .toPlainText()
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

      // Convert Delta to JSON
      final deltaJson = jsonEncode(
        _quillController.document.toDelta().toJson(),
      );

      // Create temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/report_content.json');
      await tempFile.writeAsString(deltaJson);

      final newReport = ClinicalReport(
        id: widget.reportId ?? 'new_report_id',
        patientId: _selectedPatient!.id,
        title: _titleController.text,
        description: _quillController.document
            .toPlainText()
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
          final index = _quillController.selection.baseOffset;
          final length = _quillController.selection.extentOffset - index;
          _quillController.replaceText(
            index,
            length,
            BlockEmbed.image(url),
            null,
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
            final index = _quillController.selection.baseOffset;
            final length = _quillController.selection.extentOffset - index;
            _quillController.replaceText(
              index,
              length,
              state.pendingAISelectionEdit!,
              null,
            );

            // Clear the pending edit in Bloc (we need an event for this or just ignore subsequent same values?)
            // To be safe, we should probably have an event to clear it,
            // OR we just check if it's different? But it could be the same text.
            // Let's add an event `AISelectionEditConsumed`.
            context.read<AddEditClinicalReportBloc>().add(
              AISelectionEditConsumed(),
            );
          }

          if (state.pendingAIInsert != null) {
            // Insert text at cursor or append
            final index = _quillController.selection.baseOffset;
            final length = _quillController.selection.extentOffset - index;

            // If selection is collapsed (cursor), insert. If range, replace (but we use AISelectionEdit for that).
            // AIInsertRequested is usually for "Generate" which implies insertion.
            // If the user didn't select anything, baseOffset might be -1 if lost focus,
            // but we try to keep focus.

            int insertIndex = index;
            if (insertIndex < 0) {
              insertIndex =
                  _quillController.document.length - 1; // Append to end
            }

            _quillController.replaceText(
              insertIndex,
              length > 0
                  ? length
                  : 0, // If there was a selection, replace it? Or just insert?
              // Plan said: "If no selection... insert".
              // If there IS selection, we used AISelectionEditRequested.
              // So here we assume insertion.
              state.pendingAIInsert!,
              null,
            );

            context.read<AddEditClinicalReportBloc>().add(AIInsertConsumed());
          }

          if (state.isReviewingAIChanges) {
            try {
              final json = jsonDecode(state.contentJson!);
              _quillController.document = Document.fromJson(json);
            } catch (e) {
              debugPrint('Error parsing AI content: $e');
            }
          } else if (state.contentJson != null &&
              state.originalContent == null &&
              !state.isAILoading) {
            if (_isLoaded && state.contentJson != null) {
              try {
                final json = jsonDecode(state.contentJson!);
                _quillController.document = Document.fromJson(json);
              } catch (e) {
                debugPrint('Error parsing content: $e');
              }
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
        body:
            BlocBuilder<AddEditClinicalReportBloc, AddEditClinicalReportState>(
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
                        try {
                          final json = jsonDecode(state.contentJson!);
                          _quillController.document = Document.fromJson(json);
                        } catch (e) {
                          debugPrint('Error parsing report content: $e');
                        }
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
                                QuillSimpleToolbar(
                                  controller: _quillController,
                                  config: QuillSimpleToolbarConfig(
                                    showClipboardPaste: true,
                                    showFontFamily: true,
                                    showFontSize: true,
                                    showBoldButton: true,
                                    showItalicButton: true,
                                    showUnderLineButton: true,
                                    showStrikeThrough: true,
                                    showInlineCode: true,
                                    showColorButton: true,
                                    showBackgroundColorButton: true,
                                    showClearFormat: true,
                                    showAlignmentButtons: true,
                                    showLeftAlignment: true,
                                    showCenterAlignment: true,
                                    showRightAlignment: true,
                                    showJustifyAlignment: true,
                                    showHeaderStyle: true,
                                    showListNumbers: true,
                                    showListBullets: true,
                                    showListCheck: true,
                                    showCodeBlock: true,
                                    showQuote: true,
                                    showIndent: true,
                                    showLink: true,
                                    showUndo: true,
                                    showRedo: true,
                                    showDirection: true,
                                    showSearchButton: true,
                                    showSubscript: true,
                                    showSuperscript: true,
                                    customButtons: [
                                      QuillToolbarCustomButtonOptions(
                                        icon: Icon(
                                          Icons.auto_awesome,
                                          color: _isAIChatOpen
                                              ? Colors.blue
                                              : null,
                                        ),
                                        tooltip: 'AI Chat',
                                        onPressed: () {
                                          setState(() {
                                            _isAIChatOpen = !_isAIChatOpen;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!_focusNode.hasFocus) {
                                        _focusNode.requestFocus();
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                      ),
                                      child: Stack(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Listener(
                                              onPointerDown: (event) {
                                                _lastTapDownPosition =
                                                    event.position;
                                              },
                                              child: QuillEditor.basic(
                                                key: _editorKey,
                                                controller: _quillController,
                                                focusNode: _focusNode,
                                              ),
                                            ),
                                          ),
                                          if (state.isAILoading)
                                            Container(
                                              color: Colors.white.withOpacity(
                                                0.7,
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
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
                          hasSelection: _hasSelection,
                          onSaveInstruction: (label, instruction) {
                            final userId =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (userId != null) {
                              final newInstruction = ClinicalReportInstruction(
                                id: DateTime.now().millisecondsSinceEpoch
                                    .toString(),
                                userId: userId,
                                label: label,
                                instruction: instruction,
                              );
                              context.read<AddEditClinicalReportBloc>().add(
                                AddInstruction(newInstruction),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User not logged in'),
                                ),
                              );
                            }
                          },
                          onApply: (instruction) {
                            if (_hasSelection) {
                              final selection = _quillController.document
                                  .getPlainText(
                                    _quillController.selection.baseOffset,
                                    _quillController.selection.extentOffset -
                                        _quillController.selection.baseOffset,
                                  );
                              context.read<AddEditClinicalReportBloc>().add(
                                AISelectionEditRequested(
                                  selection,
                                  instruction,
                                ),
                              );
                            } else {
                              context.read<AddEditClinicalReportBloc>().add(
                                AIInsertRequested(instruction),
                              );
                            }
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
