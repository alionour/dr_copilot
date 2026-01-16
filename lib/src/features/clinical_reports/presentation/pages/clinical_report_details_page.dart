import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_report_details_state.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/widgets/body_map_widget.dart';
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('exportSuccess'.tr())));
              // Open the exported Google Doc
              context.push('/webview?title=Google Doc&url=${state.exportUrl}');
            } else if (state.exportStatus == 'error' &&
                state.exportError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: ${state.exportError}')),
              );
            }
          }
        },
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text('clinicalReportDetails'.tr()),
              bottom: TabBar(
                tabs: [
                  Tab(text: 'reportDetails'.tr()), // Add key to json
                  const Tab(text: '2D Body Map'),
                  const Tab(text: '3D Body Map'),
                ],
              ),
              actions: [
                BlocBuilder<ClinicalReportDetailsBloc,
                    ClinicalReportDetailsState>(
                  builder: (context, state) {
                    if (state is ClinicalReportDetailsLoaded &&
                        state.contentJson != null) {
                      if (state.exportStatus == 'loading') {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      }
                      return IconButton(
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
                      );
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
                  return Center(
                      child: SelectableText('Error: ${state.message}'));
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
                            m.view == 'left' ||
                            m.view == 'right',
                      )
                      .toList();

                  final markers3D = markers
                      .where((m) => m.view == '3d' || m.view == 'body')
                      .toList();

                  // Determine initial 3D model if markers exist
                  String? initial3DModel;
                  if (markers3D.isNotEmpty) {
                    // Use model from first marker, fallback to body
                    initial3DModel =
                        markers3D.first.modelId ?? 'human_body.glb';
                  }

                  return TabBarView(
                    physics:
                        const NeverScrollableScrollPhysics(), // Prevent swipe
                    children: [
                      // TAB 1: Report Details
                      SingleChildScrollView(
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
                                          textStyle: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      )
                                    else
                                      ListTile(
                                        title: Text(reportItem.description),
                                        subtitle: Text(
                                          'clinicalReportDescription'.tr(),
                                        ),
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
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.insert_drive_file,
                                      ),
                                      title: Text(
                                        doc.name ?? 'Untitled Document',
                                      ),
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
                                  );
                                },
                              ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.go(
                                  '/clinical_reports/${reportItem.id}/edit',
                                );
                              },
                              child: Text('editClinicalReport'.tr()),
                            ),
                          ],
                        ),
                      ),

                      // TAB 2: 2D Body Map
                      markers2D.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.map_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No 2D markers recorded.",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : BodyMapWidget(
                              markers: markers2D,
                              onMarkerAdded: (_) {}, // Read-Only
                              onMarkerRemoved: (_) {}, // Read-Only
                              isReadOnly: true,
                            ),

                      // TAB 3: 3D Body Map
                      markers3D.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.view_in_ar,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "No 3D markers recorded.",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : BodyMap3DWebViewWidget(
                              markers: markers3D,
                              onMarkerAdded: (_) {},
                              onMarkerRemoved: (_) {},
                              isReadOnly: true,
                              initialModel: initial3DModel,
                            ),
                    ],
                  );
                }
                return const Center(child: Text('Something went wrong.'));
              },
            ),
          ),
        ),
      ),
    );
  }
}
