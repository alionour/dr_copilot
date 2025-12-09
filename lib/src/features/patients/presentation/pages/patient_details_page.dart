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
              return SingleChildScrollView(
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
                            if (patient.address != null)
                              ListTile(
                                title: Text(patient.address!),
                                subtitle: Text('address'.tr()),
                              ),
                            if (patient.phoneNumber != null)
                              ListTile(
                                title: Text(patient.phoneNumber!),
                                subtitle: Text('phoneNumber'.tr()),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'associatedClinicalReports'.tr(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            context.go(
                              '/clinical_reports/new',
                              extra: patient.id,
                            ); // Pass patientId as extra
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FutureBuilder<Either<Failure, List<ClinicalReport>>>(
                      future: getIt<ClinicalReportService>()
                          .getClinicalReportsForPatient(patient.id),
                      builder: (context, reportSnapshot) {
                        if (reportSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (reportSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'errorMessage'.tr(
                                args: [reportSnapshot.error.toString()],
                              ),
                            ),
                          );
                        }

                        final reportResult = reportSnapshot.data;
                        if (reportResult == null) {
                          return Center(child: Text('somethingWentWrong'.tr()));
                        }

                        return reportResult.fold(
                          (failure) => Center(
                            child: Text(
                              'errorMessage'.tr(args: [failure.message]),
                            ),
                          ),
                          (reports) {
                            if (reports.isEmpty) {
                              return Center(
                                child: Text(
                                  'noClinicalReportsFoundForPatient'.tr(),
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: reports.length,
                              itemBuilder: (context, index) {
                                final reportItem = reports[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4.0,
                                  ),
                                  child: ListTile(
                                    title: Text(reportItem.title),
                                    subtitle: Text(
                                      reportItem.date
                                          .toLocal()
                                          .toString()
                                          .split(' ')[0],
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                    ),
                                    onTap: () {
                                      context.go(
                                        '/clinical_report_details/${reportItem.id}',
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
