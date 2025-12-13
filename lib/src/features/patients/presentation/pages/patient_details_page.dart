import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/services/patient_service.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/entities/clinical_report.dart';
import 'package:dr_copilot/src/features/clinical_reports/domain/services/clinical_report_service.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/medical_files/presentation/bloc/medical_file_bloc.dart';
import 'package:dr_copilot/src/features/medications/presentation/bloc/medication_bloc.dart';
import 'package:dr_copilot/src/features/medical_files/presentation/widgets/medical_file_list_widget.dart';
import 'package:dr_copilot/src/features/medications/presentation/widgets/medication_list_widget.dart';

final getIt = GetIt.instance;

class PatientDetailsPage extends StatelessWidget {
  final String patientId;
  const PatientDetailsPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('patientDetails'.tr())),
      body: FutureBuilder<Either<Failure, PatientModel>>(
        future: getIt<PatientService>().getPatient(patientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('errorMessage'.tr(args: [snapshot.error.toString()])),
            );
          }

          final result = snapshot.data;
          if (result == null) {
            return Center(child: Text('somethingWentWrong'.tr()));
          }

          return result.fold(
            (failure) =>
                Center(child: Text('errorMessage'.tr(args: [failure.message]))),
            (patient) {
              return DefaultTabController(
                length: 4,
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'patientInformation'.tr(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    ListTile(
                                      title: Text(patient.name),
                                      subtitle: Text('name'.tr()),
                                    ),
                                    if (patient.age != null)
                                      ListTile(
                                        title: Text(patient.age.toString()),
                                        subtitle: Text('age'.tr()),
                                      ),
                                    if (patient.gender != null)
                                      ListTile(
                                        title: Text(patient.gender!),
                                        subtitle: Text('gender'.tr()),
                                      ),
                                    if (patient.phoneNumber != null)
                                      ListTile(
                                        title: Text(patient.phoneNumber!),
                                        subtitle: Text('phoneNumber'.tr()),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const TabBar(
                              labelColor: Colors.blue, // Theme color
                              unselectedLabelColor: Colors.grey,
                              isScrollable: true,
                              tabs: [
                                Tab(text: 'Clinical Reports'),
                                Tab(text: 'Medical Records'), // Files/X-rays
                                Tab(text: 'Medications'),
                                Tab(text: 'Full Info'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  body: TabBarView(
                    children: [
                      // Tab 1: Clinical Reports
                      _buildClinicalReportsTab(context, patient.id),

                      // Tab 2: Medical Files
                      _buildMedicalFilesTab(context, patient.id),

                      // Tab 3: Medications
                      _buildMedicationsTab(context, patient.id),

                      // Tab 4: Full Info (Original details)
                      _buildFullInfoTab(context, patient),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildClinicalReportsTab(BuildContext context, String patientId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'associatedClinicalReports'.tr(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.go('/clinical_reports/new', extra: patientId);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<Either<Failure, List<ClinicalReport>>>(
            future: getIt<ClinicalReportService>().getClinicalReportsForPatient(
              patientId,
            ),
            builder: (context, reportSnapshot) {
              if (reportSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (reportSnapshot.hasError) {
                return Text(reportSnapshot.error.toString());
              }
              final reportResult = reportSnapshot.data;
              if (reportResult == null) return const SizedBox();

              return reportResult.fold((failure) => Text(failure.message), (
                reports,
              ) {
                if (reports.isEmpty) {
                  return Center(
                    child: Text('noClinicalReportsFoundForPatient'.tr()),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final reportItem = reports[index];
                    return Card(
                      child: ListTile(
                        title: Text(reportItem.title),
                        subtitle: Text(
                          reportItem.date.toLocal().toString().split(' ')[0],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.pushNamed(
                            'clinical_report_details',
                            pathParameters: {'reportId': reportItem.id},
                          );
                        },
                      ),
                    );
                  },
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalFilesTab(BuildContext context, String patientId) {
    // Lazy load approach not strictly needed if we use BlocProvider in main
    // But for now we rely on the widget to trigger load event if needed or we trigger it here.
    // Ideally, we wrap with BlocProvider.value if already provided, or create it.
    // Assuming we register Blocs as singletons or factories in GetIt and provide them in build.

    // Note: We need to import MedicalFileListWidget
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medical Records',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.push('/patients/$patientId/upload-file');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Using BlocProvider to provide the Bloc to the widget and trigger initial load.
          BlocProvider(
            create: (context) =>
                getIt<MedicalFileBloc>()..add(LoadMedicalFiles(patientId)),
            child: MedicalFileListWidget(patientId: patientId),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab(BuildContext context, String patientId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Medications',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  context.push('/patients/$patientId/add-medication');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          BlocProvider(
            create: (context) =>
                getIt<MedicationBloc>()..add(LoadMedications(patientId)),
            child: MedicationListWidget(patientId: patientId),
          ),
        ],
      ),
    );
  }

  Widget _buildFullInfoTab(BuildContext context, PatientModel patient) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (patient.address != null)
            ListTile(
              title: Text(patient.address!),
              subtitle: Text('address'.tr()),
            ),
          if (patient.alternativePhoneNumber != null)
            ListTile(
              title: Text(patient.alternativePhoneNumber!),
              subtitle: Text('alternativePhoneNumber'.tr()),
            ),
          if (patient.treatingDoctor != null)
            ListTile(
              title: Text(patient.treatingDoctor!),
              subtitle: Text('treatingDoctor'.tr()),
            ),
          if (patient.occupation != null)
            ListTile(
              title: Text(patient.occupation!),
              subtitle: Text('occupation'.tr()),
            ),

          // Add more details as needed
        ],
      ),
    );
  }
}
