import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/features/patients/domain/services/patient_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';

import 'package:dr_copilot/src/core/error/failures.dart';

import 'clinical_reports_list_event.dart';
import 'clinical_reports_list_state.dart';

class ClinicalReportsListBloc
    extends Bloc<ClinicalReportsListEvent, ClinicalReportsListState> {
  final ClinicalReportService _clinicalReportService;
  final PatientService _patientService;

  ClinicalReportsListBloc(this._clinicalReportService, this._patientService)
      : super(ClinicalReportsListInitial()) {
    on<LoadClinicalReportsList>((event, emit) async {
      emit(ClinicalReportsListLoading());
      final result = await _clinicalReportService.getAllClinicalReports();

      List<ClinicalReport>? reports;
      Failure? failure;

      result.fold(
        (f) => failure = f,
        (r) => reports = r,
      );

      if (failure != null) {
        emit(ClinicalReportsListError(failure!.message));
        return;
      }

      final patientIds = reports!.map((c) => c.patientId).toSet();
      final patients = <String, dynamic>{};

      for (var patientId in patientIds) {
        final patientResult = await _patientService.getPatient(patientId);
        patientResult.fold(
          (f) => null, // Ignore errors for individual patients
          (p) => patients[patientId] = p,
        );
      }

      emit(ClinicalReportsListLoaded(
          reports: reports!,
          patients: patients.cast(),
          isFromDrive: false)); // Set the flag
    });

    on<LoadClinicalReportsFromDrive>((event, emit) async {
      emit(ClinicalReportsListLoading());
      try {
        // Create dummy ClinicalReport objects for display purposes
        final List<ClinicalReport> reports = event.driveFiles.map((file) {
          return ClinicalReport(
            id: file.id!,
            title: file.name ?? 'Untitled Report',
            description: file.description ??
                file.webViewLink ??
                'No description available.',
            date: file.modifiedTime ?? DateTime.now(),
            patientId: 'google_drive_patient', // Placeholder patient ID
            documentUrls: file.webViewLink != null ? [file.webViewLink!] : [],
          );
        }).toList();

        emit(ClinicalReportsListLoaded(
          reports: reports,
          patients: {}, // No patient info from Drive files directly
          driveFiles: event.driveFiles, // Pass the raw drive files
          isFromDrive: true, // Set the flag
        ));
      } catch (e) {
        emit(ClinicalReportsListError(e.toString()));
      }
    });
  }
}

