
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/features/patients/domain/services/patient_service.dart';
import 'add_edit_clinical_report_event.dart';
import 'add_edit_clinical_report_state.dart';

class AddEditClinicalReportBloc extends Bloc<AddEditClinicalReportEvent, AddEditClinicalReportState> {
  final ClinicalReportService _clinicalReportService;
  final PatientService _patientService;

  AddEditClinicalReportBloc(this._clinicalReportService, this._patientService) : super(AddEditClinicalReportInitial()) {
    on<LoadAddEditClinicalReport>((event, emit) async {
      emit(AddEditClinicalReportLoading());
      try {
        final patients = await _patientService.getAllPatients();
        if (event.reportId != null) {
          final report = await _clinicalReportService.getClinicalReport(event.reportId!);
          emit(AddEditClinicalReportLoaded(report: report, patients: patients));
        } else {
          emit(AddEditClinicalReportLoaded(patients: patients));
        }
      } catch (e) {
        emit(AddEditClinicalReportError(e.toString()));
      }
    });

    on<SaveClinicalReport>((event, emit) async {
      try {
        if (event.report.id == 'new_report_id') {
          await _clinicalReportService.createClinicalReport(event.report);
        } else {
          await _clinicalReportService.updateClinicalReport(event.report);
        }
        emit(AddEditClinicalReportSuccess());
      } catch (e) {
        emit(AddEditClinicalReportError(e.toString()));
      }
    });
  }
}
