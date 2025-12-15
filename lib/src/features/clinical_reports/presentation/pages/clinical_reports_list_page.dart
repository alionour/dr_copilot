import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_reports_list_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_reports_list_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/clinical_reports_list_state.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/google_drive_bloc.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/google_drive_event.dart';
import 'package:dr_copilot/src/features/clinical_reports/presentation/bloc/google_drive_state.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_copilot/src/core/presentation/widgets/empty_state_widget.dart';

final getIt = GetIt.instance;

class ClinicalReportsListPage extends StatelessWidget {
  const ClinicalReportsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('clinicalReports'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.go('/clinical_reports/create');
            },
          ),
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => getIt<ClinicalReportsListBloc>()),
          BlocProvider(
            create: (context) =>
                getIt<GoogleDriveBloc>(param1: context.read<OwnerNotifier>()),
          ),
        ],
        child: const _ClinicalReportsContent(),
      ),
    );
  }
}

class _ClinicalReportsContent extends StatefulWidget {
  const _ClinicalReportsContent();

  @override
  State<_ClinicalReportsContent> createState() =>
      _ClinicalReportsContentState();
}

class _ClinicalReportsContentState extends State<_ClinicalReportsContent> {
  @override
  void initState() {
    super.initState();
    // Load reports from Firestore by default
    context.read<ClinicalReportsListBloc>().add(LoadClinicalReportsList());
    // Optionally check Google Drive auth status without blocking
    context.read<GoogleDriveBloc>().add(AuthenticateGoogleDrive());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Optional Google Drive Status / Connect Button
        BlocBuilder<GoogleDriveBloc, GoogleDriveState>(
          builder: (context, driveState) {
            if (driveState is GoogleDriveAuthenticationRequired) {
              return Container(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade800,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'googleDriveNotConnected'.tr(),
                        style: TextStyle(color: Colors.orange.shade900),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<GoogleDriveBloc>().add(
                          AuthenticateGoogleDrive(),
                        );
                      },
                      child: Text('connect'.tr()),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
        Expanded(
          child: BlocBuilder<ClinicalReportsListBloc, ClinicalReportsListState>(
            builder: (context, state) {
              if (state is ClinicalReportsListLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ClinicalReportsListError) {
                return Center(child: SelectableText('Error: ${state.message}'));
              }
              if (state is ClinicalReportsListLoaded) {
                if (state.reports.isEmpty && !state.isFromDrive) {
                  return EmptyStateWidget(
                    message: 'noClinicalReportsFound'.tr(),
                    title: 'noReports'.tr(),
                    actionLabel: 'createReport'.tr(),
                    onActionPressed: () {
                      context.go('/clinical_reports/create');
                    },
                  );
                }

                return ListView.builder(
                  itemCount: state.isFromDrive
                      ? state.driveFiles.length
                      : state.reports.length,
                  itemBuilder: (context, index) {
                    if (state.isFromDrive) {
                      // ... (Drive file rendering logic - kept for future use if we add toggle)
                      final file = state.driveFiles[index];
                      return ListTile(title: Text(file.name ?? 'Untitled'));
                    } else {
                      final reportItem = state.reports[index];
                      final patient = state.patients[reportItem.patientId];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 8.0,
                        ),
                        child: ListTile(
                          title: Text(reportItem.title),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patient?.name ?? 'Unknown Patient'),
                              Text(
                                DateFormat.yMd().format(reportItem.date),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (reportItem.isFinalized)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.green),
                                  ),
                                  child: const Text(
                                    'Finalized',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (reportItem.isFinalized)
                                const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                          onTap: () {
                            context.push(
                              '/clinical_reports/clinical_report_details/${reportItem.id}',
                            );
                          },
                        ),
                      );
                    }
                  },
                );
              }
              return const Center(child: Text('Something went wrong.'));
            },
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  void _showOpenOptionsDialog(BuildContext context, String title, String url) {
    // ... (Keep existing method if needed, though mostly for Drive files)
    debugPrint('Inside _showOpenOptionsDialog for title: $title, url: $url');
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('openFileOptions'.tr()),
          content: Text('howWouldYouLikeToOpenThisFile'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text('openInApp'.tr()),
              onPressed: () {
                debugPrint('Open in App selected for $url');
                Navigator.of(context).pop();
                context.push(
                  '/webview?title=${Uri.encodeComponent(title)}&url=${Uri.encodeComponent(url)}',
                );
              },
            ),
            TextButton(
              child: Text('openInBrowser'.tr()),
              onPressed: () async {
                debugPrint('Open in Browser selected for $url');
                Navigator.of(context).pop();
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('couldNotLaunch'.tr(args: [url]))),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

