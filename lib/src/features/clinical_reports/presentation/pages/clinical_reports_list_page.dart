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
              context.go('/clinical_reports/new');
            },
          ),
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => getIt<ClinicalReportsListBloc>(),
          ),
          BlocProvider(
            create: (context) => getIt<GoogleDriveBloc>(param1: context.read<OwnerNotifier>()),
          ),
        ],
        child: const _ClinicalReportsContent(),
      ),
    );
  }
}

class _ClinicalReportsContent extends StatefulWidget {
  const _ClinicalReportsContent({super.key});

  @override
  State<_ClinicalReportsContent> createState() => _ClinicalReportsContentState();
}

class _ClinicalReportsContentState extends State<_ClinicalReportsContent> {
  @override
  void initState() {
    super.initState();
    // Dispatch the event here, as this widget is a child of MultiBlocProvider
    context.read<GoogleDriveBloc>().add(AuthenticateGoogleDrive());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GoogleDriveBloc, GoogleDriveState>(
      builder: (context, driveState) {
        if (driveState is GoogleDriveLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (driveState is GoogleDriveError) {
          return Center(child: Text('Error: ${driveState.message}'));
        }
        if (driveState is GoogleDriveAuthenticationRequired) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('googleDriveAuthRequired'.tr()),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<GoogleDriveBloc>().add(AuthenticateGoogleDrive());
                  },
                  child: Text('connectGoogleDrive'.tr()),
                ),
              ],
            ),
          );
        }
        if (driveState is GoogleDriveAuthenticated) {
          // If authenticated, then load clinical reports from Google Drive files
          context.read<ClinicalReportsListBloc>().add(LoadClinicalReportsFromDrive(driveState.files));
          return BlocBuilder<ClinicalReportsListBloc, ClinicalReportsListState>(
            builder: (context, state) {
              if (state is ClinicalReportsListLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ClinicalReportsListError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state is ClinicalReportsListLoaded) {
                final currentDriveState = context.read<GoogleDriveBloc>().state as GoogleDriveAuthenticated;
                final bool canGoBack = currentDriveState.folderStack.isNotEmpty || (currentDriveState.currentFolderId != null && currentDriveState.currentFolderId != currentDriveState.clinicFolderId);

                return Column(
                  children: [
                    if (canGoBack)
                      ListTile(
                        leading: const Icon(Icons.arrow_back),
                        title: Text('goBack'.tr()),
                        onTap: () {
                          context.read<GoogleDriveBloc>().add(GoBack());
                        },
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.isFromDrive ? state.driveFiles.length : state.reports.length,
                        itemBuilder: (context, index) {
                          if (state.isFromDrive) {
                            final file = state.driveFiles[index];
                            final isFolder = file.mimeType == 'application/vnd.google-apps.folder';

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                              child: ListTile(
                                leading: Icon(isFolder ? Icons.folder : Icons.insert_drive_file),
                                title: Text(file.name ?? 'Untitled'),
                                subtitle: Text(file.modifiedTime != null ? DateFormat.yMd().add_jm().format(file.modifiedTime!) : 'N/A'),
                                trailing: isFolder ? const Icon(Icons.arrow_forward_ios) : null,
                                onTap: () async {
                                  debugPrint('File tapped: ${file.name}, webViewLink: ${file.webViewLink}');
                                  if (isFolder) {
                                    context.read<GoogleDriveBloc>().add(GoToFolder(file.id!, file.name ?? ''));
                                  } else {
                                    if (file.webViewLink != null) {
                                      debugPrint('Calling _showOpenOptionsDialog for file: ${file.name}');
                                      _showOpenOptionsDialog(context, file.name ?? 'File', file.webViewLink!); // Show dialog
                                    } else {
                                      debugPrint('webViewLink is null for file: ${file.name}');
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('No webViewLink available for ${file.name}')),
                                      );
                                    }
                                  }
                                },
                              ),
                            );
                          } else {
                            final reportItem = state.reports[index];
                            final patient = state.patients[reportItem.patientId];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                              child: ListTile(
                                title: Text(reportItem.title),
                                subtitle: Text(patient?.name ?? 'Unknown Patient'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  context.push('/clinical_report_details/${reportItem.id}');
                                },
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                );
              }
              return const Center(child: Text('Something went wrong.'));
            },
          );
        }
        return const Center(child: Text('Something went wrong.'));
      },
    );
  }

  void _showOpenOptionsDialog(BuildContext context, String title, String url) {
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
                context.push('/webview?title=${Uri.encodeComponent(title)}&url=${Uri.encodeComponent(url)}');
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