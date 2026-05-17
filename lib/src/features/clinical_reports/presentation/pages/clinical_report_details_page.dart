import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_state.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/widgets/body_map_readonly_widget.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/widgets/body_map_3d_webview_widget.dart';

final getIt = GetIt.instance;

class ClinicalReportDetailsPage extends StatefulWidget {
  final String reportId;
  const ClinicalReportDetailsPage({super.key, required this.reportId});

  @override
  State<ClinicalReportDetailsPage> createState() =>
      _ClinicalReportDetailsPageState();
}

class _ClinicalReportDetailsPageState extends State<ClinicalReportDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ClinicalReportDetailsBloc>()
        ..add(LoadClinicalReportDetails(widget.reportId)),
      child:
          BlocListener<ClinicalReportDetailsBloc, ClinicalReportDetailsState>(
        listener: (context, state) {
          if (state is ClinicalReportDetailsLoaded) {
            if (state.exportStatus == 'success' && state.exportUrl != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: SelectionArea(child: Text('exportSuccess'.tr()))),
              );
              // Open the exported Google Doc
              context.push('/webview?title=Google Doc&url=${state.exportUrl}');
            } else if (state.exportStatus == 'error' &&
                state.exportError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: SelectionArea(child: Text('Error: ${state.exportError}'))),
              );
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text('clinicalReportDetails'.tr()),
            actions: [
              BlocBuilder<ClinicalReportDetailsBloc,
                  ClinicalReportDetailsState>(
                builder: (context, state) {
                  // Only show actions if loaded
                  if (state is ClinicalReportDetailsLoaded) {
                    final List<Widget> actions = [];

                    // Edit Button (Moved to AppBar)
                    actions.add(
                      IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'editClinicalReport'.tr(),
                        onPressed: () {
                          context.push(
                              '/clinical_reports/${state.report.id}/edit');
                        },
                      ),
                    );

                    if (state.contentJson != null &&
                        state.contentJson!.isNotEmpty) {
                      if (state.exportStatus == 'loading') {
                        actions.add(const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ));
                      } else {
                        actions.add(IconButton(
                          icon: const Icon(Icons.file_upload),
                          tooltip: 'exportToGoogleDocs'.tr(),
                          onPressed: () {
                            context.read<ClinicalReportDetailsBloc>().add(
                                  ExportClinicalReportToGoogleDocs(
                                    state.report.id,
                                    state.contentJson!,
                                  ),
                                );
                          },
                        ));
                      }
                    }
                    return Row(children: actions);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: BlocBuilder<ClinicalReportDetailsBloc,
              ClinicalReportDetailsState>(
            builder: (context, state) {
              if (state is ClinicalReportDetailsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ClinicalReportDetailsError) {
                return Center(child: SelectableText('Error: ${state.message}'));
              }
              if (state is ClinicalReportDetailsLoaded) {
                final reportItem = state.report;
                final patient = state.patient;
                final markers = reportItem.bodyMapPoints;

                final markers2D = markers
                    .where(
                      (m) =>
                          m.view == 'front' ||
                          m.view == 'back' ||
                          m.view == 'lateral',
                    )
                    .toList();

                final markers3D = markers
                    .where((m) => m.view == '3d' || m.view == 'body')
                    .toList();

                // Get unique models used in 3D markers
                final uniqueModels = markers3D
                    .map((m) => m.modelId ?? 'human_body.glb')
                    .toSet()
                    .toList();

                return LayoutBuilder(builder: (context, constraints) {
                  final isWideScreen = constraints.maxWidth > 900;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Clinical Info
                        ExpansionTile(
                          title: Text(
                            'clinicalReportInformation'.tr(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          initiallyExpanded: true,
                          children: [
                            Card(
                              margin: const EdgeInsets.only(bottom: 16),
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
                                      title: Text(
                                        reportItem.date
                                            .toLocal()
                                            .toString()
                                            .split(' ')[0],
                                      ),
                                      subtitle: Text('clinicalReportDate'.tr()),
                                    ),
                                    const SizedBox(height: 8),
                                    if (state.contentJson != null &&
                                        state.contentJson!.isNotEmpty)
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        padding: const EdgeInsets.all(8),
                                        child: HtmlWidget(
                                          state.contentJson!,
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      )
                                    else
                                      ListTile(
                                        title: Text(reportItem.description),
                                        subtitle: Text(
                                            'clinicalReportDescription'.tr()),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // 2. Documents
                        ExpansionTile(
                          title: Text(
                            'associatedDocuments'.tr(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          initiallyExpanded: true,
                          children: [
                            if (state.documents.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text('noDocumentsFound'.tr()),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWideScreen ? 2 : 1,
                                  childAspectRatio: isWideScreen ? 3 : 4,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: state.documents.length,
                                itemBuilder: (context, index) {
                                  final doc = state.documents[index];
                                  return Card(
                                    margin: EdgeInsets.zero,
                                    child: Center(
                                      child: ListTile(
                                        leading:
                                            const Icon(Icons.insert_drive_file),
                                        title: Text(
                                            doc.name ?? 'Untitled Document',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.open_in_new),
                                          onPressed: () {
                                            if (doc.webViewLink != null) {
                                              context.push(
                                                '/webview?title=${doc.name ?? 'Document'}&url=${doc.webViewLink}',
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),

                        // 3. 2D Maps
                        if (markers2D.isNotEmpty)
                          ExpansionTile(
                            title: Text(
                              '2D Body Map Markers',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            initiallyExpanded: true,
                            children: [
                              BodyMapReadOnlyWidget(
                                  markers: markers2D, isGrid: isWideScreen),
                            ],
                          ),

                        // 4. 3D Maps
                        if (uniqueModels.isNotEmpty)
                          ExpansionTile(
                            title: Text(
                              '3D Body Map Markers',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            initiallyExpanded: true,
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isWideScreen ? 2 : 1,
                                  childAspectRatio:
                                      1.2, // Optimized to reduce vertical space
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: uniqueModels.length,
                                itemBuilder: (context, index) {
                                  final modelId = uniqueModels[index];
                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: BodyMap3DWebViewWidget(
                                      markers: markers3D,
                                      onMarkerAdded: (_) {},
                                      onMarkerRemoved: (_) {},
                                      isReadOnly: true,
                                      initialModel: modelId,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                });
              }
              return const Center(child: Text('Something went wrong.'));
            },
          ),
        ),
      ),
    );
  }
}
