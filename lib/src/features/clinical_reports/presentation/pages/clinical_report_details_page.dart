
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_state.dart';




final getIt = GetIt.instance;

class ClinicalReportDetailsPage extends StatefulWidget {
  final String reportId;
  const ClinicalReportDetailsPage({super.key, required this.reportId});

  @override
  State<ClinicalReportDetailsPage> createState() => _ClinicalReportDetailsPageState();
}

class _ClinicalReportDetailsPageState extends State<ClinicalReportDetailsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ClinicalReportDetailsBloc>()..add(LoadClinicalReportDetails(widget.reportId)),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text('clinicalReportDetails'.tr()),
        ),
        body: BlocBuilder<ClinicalReportDetailsBloc, ClinicalReportDetailsState>(
          builder: (context, state) {
            if (state is ClinicalReportDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ClinicalReportDetailsError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is ClinicalReportDetailsLoaded) {
              final reportItem = state.report;
              final patient = state.patient;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'clinicalReportInformation'.tr(),
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
                              subtitle: Text('patientName'.tr()),
                            ),
                            ListTile(
                              title: Text(reportItem.id),
                              subtitle: Text('clinicalReportId'.tr()),
                            ),
                            ListTile(
                              title: Text(reportItem.date.toLocal().toString().split(' ')[0]),
                              subtitle: Text('clinicalReportDate'.tr()),
                            ),
                            ListTile(
                              title: Text(reportItem.description),
                              subtitle: Text('clinicalReportDescription'.tr()),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'associatedDocuments'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    if (state.documents.isEmpty)
                      Text('noDocumentsFound'.tr())
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.documents.length,
                        itemBuilder: (context, index) {
                          final doc = state.documents[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: const Icon(Icons.insert_drive_file),
                              title: Text(doc.name ?? 'Untitled Document'),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () {
                                  if (doc.webViewLink != null) {
                                    context.push('/webview?title=${doc.name ?? 'Document'}&url=${doc.webViewLink}');
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/clinical_reports/${reportItem.id}/edit');
                      },
                      child: Text('editClinicalReport'.tr()),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Something went wrong.'));
          },
        ),
      ),
    );
  }
}

