
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:dr_copilot/src/core/services/google_drive_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/features/patients/domain/services/patient_service.dart';
import 'clinical_report_details_event.dart';
import 'clinical_report_details_state.dart';

class ClinicalReportDetailsBloc extends Bloc<ClinicalReportDetailsEvent, ClinicalReportDetailsState> {
  final ClinicalReportService _clinicalReportService;
  final PatientService _patientService;
  final GoogleDriveService _googleDriveService;

  ClinicalReportDetailsBloc(this._clinicalReportService, this._patientService, this._googleDriveService) : super(ClinicalReportDetailsInitial()) {
    on<LoadClinicalReportDetails>((event, emit) async {
      emit(ClinicalReportDetailsLoading());
      try {
        final report = await _clinicalReportService.getClinicalReport(event.reportId);
        if (report != null) {
          final patient = await _patientService.getPatient(report.patientId);
          if (patient != null) {
            final documents = <drive.File>[];
            for (final docId in report.documentUrls) {
              final file = await _googleDriveService.getFile(docId);
              if (file != null) {
                documents.add(file);
              }
            }
            emit(ClinicalReportDetailsLoaded(report: report, patient: patient, documents: documents));
          } else {
            emit(const ClinicalReportDetailsError('Patient not found'));
          }
        }
        else {
          emit(const ClinicalReportDetailsError('Clinical report not found'));
        }
      } catch (e) {
        emit(ClinicalReportDetailsError(e.toString()));
      }
    });
  }
}
