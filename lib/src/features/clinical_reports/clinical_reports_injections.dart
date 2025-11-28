import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/google_drive_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/add_edit_clinical_report_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_reports_list_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_ai_service.dart';

final sl = GetIt.instance;

void initClinicalReportsInjections() {
  sl.registerLazySingleton(() => ClinicalReportAIService(sl()));
  sl.registerFactory(() => ClinicalReportsListBloc(sl(), sl()));
  sl.registerFactory(() => AddEditClinicalReportBloc(sl(), sl(), sl()));
  sl.registerFactory(() => ClinicalReportDetailsBloc(sl(), sl(), sl()));
  sl.registerFactoryParam<GoogleDriveBloc, OwnerNotifier, dynamic>(
    (ownerNotifier, _) => GoogleDriveBloc(sl(), ownerNotifier),
  );
  sl.registerLazySingleton(() => ClinicalReportService());
}
