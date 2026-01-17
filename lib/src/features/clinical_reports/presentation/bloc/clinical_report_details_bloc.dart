import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:dr_copilot/src/core/services/google_drive_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/features/patients/domain/services/patient_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/core/error/failures.dart';

import 'clinical_report_details_event.dart';
import 'clinical_report_details_state.dart';

class ClinicalReportDetailsBloc
    extends Bloc<ClinicalReportDetailsEvent, ClinicalReportDetailsState> {
  final ClinicalReportService _clinicalReportService;
  final PatientService _patientService;
  final GoogleDriveService _googleDriveService;

  ClinicalReportDetailsBloc(this._clinicalReportService, this._patientService,
      this._googleDriveService)
      : super(ClinicalReportDetailsInitial()) {
    on<LoadClinicalReportDetails>((event, emit) async {
      emit(ClinicalReportDetailsLoading());
      final reportResult =
          await _clinicalReportService.getClinicalReport(event.reportId);

      ClinicalReport? report;
      Failure? failure;

      reportResult.fold(
        (f) => failure = f,
        (r) => report = r,
      );

      if (failure != null) {
        emit(ClinicalReportDetailsError(failure!.message));
        return;
      }

      final patientResult = await _patientService.getPatient(report!.patientId);

      PatientModel? patient;
      patientResult.fold(
        (f) => failure = f,
        (p) => patient = p,
      );

      if (failure != null) {
        emit(ClinicalReportDetailsError(failure!.message));
        return;
      }

      final documents = <drive.File>[];
      for (final docId in report!.documentUrls) {
        final file = await _googleDriveService.getFile(docId);
        if (file != null) {
          documents.add(file);
        }
      }

      String? contentJson;
      if (report!.contentUrl != null) {
        final contentResult =
            await _clinicalReportService.getReportContent(report!.contentUrl!);
        contentResult.fold(
          (f) => null, // Ignore content fetch error, load empty
          (c) => contentJson = c,
        );
      }

      emit(ClinicalReportDetailsLoaded(
          report: report!,
          patient: patient!,
          documents: documents,
          contentJson: contentJson));
    });

    on<ExportClinicalReportToGoogleDocs>((event, emit) async {
      final currentState = state;
      if (currentState is ClinicalReportDetailsLoaded) {
        emit(currentState.copyWith(exportStatus: 'loading'));

        final result = await _clinicalReportService.exportToGoogleDocs(
            currentState.report, event.contentJson);

        result.fold(
          (f) => emit(currentState.copyWith(
              exportStatus: 'error', exportError: f.message)),
          (url) => emit(
              currentState.copyWith(exportStatus: 'success', exportUrl: url)),
        );
      }
    });
  }
}

