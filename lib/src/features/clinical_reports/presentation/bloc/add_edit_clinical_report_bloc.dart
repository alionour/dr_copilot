import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_ai_service.dart';
import 'package:dr_copilot/src/features/patients/domain/services/patient_service.dart';
import 'add_edit_clinical_report_event.dart';
import 'add_edit_clinical_report_state.dart';

import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/models/clinical_report_chat_message.dart';

class AddEditClinicalReportBloc
    extends Bloc<AddEditClinicalReportEvent, AddEditClinicalReportState> {
  final ClinicalReportService _clinicalReportService;
  final PatientService _patientService;
  final ClinicalReportAIService _aiService;

  AddEditClinicalReportBloc(
    this._clinicalReportService,
    this._patientService,
    this._aiService,
  ) : super(AddEditClinicalReportInitial()) {
    on<LoadAddEditClinicalReport>((event, emit) async {
      emit(AddEditClinicalReportLoading());
      final patientsResult = await _patientService.getAllPatients();

      List<PatientModel>? patients;
      Failure? failure;

      patientsResult.fold((f) => failure = f, (p) => patients = p);

      if (failure != null) {
        emit(AddEditClinicalReportError(failure!.message));
        return;
      }

      if (event.reportId != null) {
        final reportResult = await _clinicalReportService.getClinicalReport(
          event.reportId!,
        );

        await reportResult.fold(
          (f) async => emit(AddEditClinicalReportError(f.message)),
          (report) async {
            String? contentJson;
            if (report.contentUrl != null) {
              final contentResult = await _clinicalReportService
                  .getReportContent(report.contentUrl!);
              contentResult.fold(
                (f) => null, // Ignore content fetch error, load empty
                (c) => contentJson = c,
              );
            }
            emit(
              AddEditClinicalReportLoaded(
                report: report,
                patients: patients!,
                contentJson: contentJson,
              ),
            );
          },
        );
      } else {
        emit(AddEditClinicalReportLoaded(patients: patients!));
      }
      add(LoadSavedInstructions());
    });

    on<SaveClinicalReport>((event, emit) async {
      final result = event.report.id == 'new_report_id'
          ? await _clinicalReportService.createClinicalReport(
              event.report,
              jsonFile: event.jsonFile,
            )
          : await _clinicalReportService.updateClinicalReport(
              event.report,
              jsonFile: event.jsonFile,
            );

      result.fold(
        (failure) => emit(AddEditClinicalReportError(failure.message)),
        (report) => emit(AddEditClinicalReportSuccess(reportId: report.id)),
      );
    });

    on<AutoSaveClinicalReport>((event, emit) async {
      // Silent save, don't emit loading or success that navigates away
      final result = await _clinicalReportService.updateClinicalReport(
        event.report,
        jsonFile: event.jsonFile,
      );

      result.fold(
        (failure) => null, // Silently fail or maybe log
        (report) => null, // Silently succeed
      );
    });

    on<DeleteClinicalReport>((event, emit) async {
      emit(AddEditClinicalReportLoading());
      final result = await _clinicalReportService.deleteClinicalReport(
        event.reportId,
      );

      result.fold(
        (failure) => emit(AddEditClinicalReportError(failure.message)),
        (_) => emit(const AddEditClinicalReportSuccess(reportId: null)),
      );
    });

    on<AIEditRequested>((event, emit) async {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(currentState.copyWith(isAILoading: true));

        try {
          final newContent = await _aiService.editReport(
            event.currentContent,
            event.instruction,
            clinicalData: event.clinicalData,
          );
          emit(
            currentState.copyWith(
              isAILoading: false,
              contentJson: newContent,
              originalContent: event.currentContent,
              isReviewingAIChanges: true,
            ),
          );
        } catch (e) {
          emit(AddEditClinicalReportError(e.toString()));
          // Re-emit loaded state to restore UI (optional, but good for UX)
          emit(currentState.copyWith(isAILoading: false));
        }
      }
    });

    on<AIEditAccepted>((event, emit) {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(
          currentState.copyWith(
            isReviewingAIChanges: false,
            originalContent: null,
          ),
        );
      }
    });

    on<AIEditRejected>((event, emit) {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        if (currentState.originalContent != null) {
          emit(
            currentState.copyWith(
              isReviewingAIChanges: false,
              contentJson: currentState.originalContent,
              originalContent: null,
            ),
          );
        }
      }
    });

    on<AISelectionEditRequested>((event, emit) async {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(currentState.copyWith(isAILoading: true));

        try {
          final newText = await _aiService.editSelection(
            event.selection,
            event.instruction,
            clinicalData: event.clinicalData,
          );

          emit(
            currentState.copyWith(
              isAILoading: false,
              pendingAISelectionEdit: newText,
            ),
          );

          // Clear the pending edit after a short delay or expect UI to consume it?
          // Better: The UI consumes it and we don't need to clear it immediately,
          // but if we emit again it might re-trigger.
          // Let's rely on the UI to handle it.
          // Or we can emit a "consumed" state later.
          // For now, let's just emit it.

          // Actually, to avoid re-triggering on other state changes, we should probably clear it.
          // But we can't clear it *immediately* because the UI needs to see it.
          // We can emit the state WITH the text, then immediately emit WITHOUT it?
          // That might be too fast.
          // Let's let the UI consume it.
        } catch (e) {
          emit(AddEditClinicalReportError(e.toString()));
          emit(currentState.copyWith(isAILoading: false));
        }
      }
    });

    on<AISelectionEditConsumed>((event, emit) {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(currentState.copyWith(pendingAISelectionEdit: null));
      }
    });

    on<AIGenerateContentRequested>((event, emit) async {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(currentState.copyWith(isAILoading: true));

        try {
          final newText = await _aiService.chat(
            event.instruction,
            clinicalData: event.clinicalData,
          );

          emit(
            currentState.copyWith(
              isAILoading: false,
              generatedContent: newText,
            ),
          );
        } catch (e) {
          emit(AddEditClinicalReportError(e.toString()));
          emit(currentState.copyWith(isAILoading: false));
        }
      }
    });

    on<AIClearGeneratedContent>((event, emit) {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(currentState.copyWith(generatedContent: null));
      }
    });

    on<AIRefineInstructionRequested>((event, emit) async {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(currentState.copyWith(isAILoading: true));

        try {
          final refined = await _aiService.refineText(
            event.text,
            'instruction',
          );
          emit(
            currentState.copyWith(
              isAILoading: false,
              refinedInstruction: refined,
            ),
          );
        } catch (e) {
          emit(AddEditClinicalReportError(e.toString()));
          emit(currentState.copyWith(isAILoading: false));
        }
      }
    });

    on<AIRefineClinicalDataRequested>((event, emit) async {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(currentState.copyWith(isAILoading: true));

        try {
          final refined = await _aiService.refineText(
            event.text,
            'clinical data',
          );
          emit(
            currentState.copyWith(
              isAILoading: false,
              refinedClinicalData: refined,
            ),
          );
        } catch (e) {
          emit(AddEditClinicalReportError(e.toString()));
          emit(currentState.copyWith(isAILoading: false));
        }
      }
    });

    on<AIRefineConsumed>((event, emit) {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        emit(
          currentState.copyWith(
            refinedInstruction: null,
            refinedClinicalData: null,
          ),
        );
      }
    });

    on<LoadSavedInstructions>((event, emit) async {
      final result = await _clinicalReportService.getInstructions();
      result.fold(
        (failure) => null, // Ignore failure for now
        (instructions) {
          if (state is AddEditClinicalReportLoaded) {
            emit(
              (state as AddEditClinicalReportLoaded).copyWith(
                instructions: instructions,
              ),
            );
          }
        },
      );
    });

    on<SaveInstruction>((event, emit) async {
      final result = await _clinicalReportService.saveInstruction(
        event.instruction,
      );
      result.fold(
        (failure) => emit(AddEditClinicalReportError(failure.message)),
        (id) {
          add(LoadSavedInstructions());
        },
      );
    });

    on<DeleteInstruction>((event, emit) async {
      final result = await _clinicalReportService.deleteInstruction(
        event.instructionId,
      );
      result.fold(
        (failure) => emit(AddEditClinicalReportError(failure.message)),
        (_) {
          add(LoadSavedInstructions());
        },
      );
    });

    on<LoadChatHistory>((event, emit) async {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;
        final result = await _clinicalReportService.getChatHistory(
          event.reportId,
        );
        result.fold(
          (f) => null,
          (messages) => emit(currentState.copyWith(chatMessages: messages)),
        );
      }
    });

    on<SendChatMessage>((event, emit) async {
      if (state is AddEditClinicalReportLoaded) {
        final currentState = state as AddEditClinicalReportLoaded;

        // 1. Add user message immediately
        final userMsg = ClinicalReportChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: ChatMessageSender.user,
          text: event.message,
          timestamp: DateTime.now(),
        );

        final updatedMessages = List<ClinicalReportChatMessage>.from(
          currentState.chatMessages,
        )..add(userMsg);

        emit(
          currentState.copyWith(
            chatMessages: updatedMessages,
            isAILoading: true,
          ),
        );

        // Save user message
        await _clinicalReportService.saveChatMessage(event.reportId, userMsg);

        try {
          // 2. Get AI response
          final aiResponseText = await _aiService.chat(event.message);
          final aiMsg = ClinicalReportChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: ChatMessageSender.ai,
            text: aiResponseText,
            timestamp: DateTime.now(),
          );

          final newMessages = List<ClinicalReportChatMessage>.from(
            updatedMessages,
          )..add(aiMsg);

          emit(
            currentState.copyWith(
              chatMessages: newMessages,
              isAILoading: false,
            ),
          );
          await _clinicalReportService.saveChatMessage(event.reportId, aiMsg);
        } catch (e) {
          emit(AddEditClinicalReportError(e.toString()));
          emit(currentState.copyWith(isAILoading: false));
        }
      }
    });
  }
}
