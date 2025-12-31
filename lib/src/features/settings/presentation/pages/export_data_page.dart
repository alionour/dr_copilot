import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/navigation_side/presentation/widgets/nav_menu_button.dart';
import 'package:dr_copilot/src/features/settings/domain/repositories/export_repository.dart';
import 'package:dr_copilot/src/features/settings/domain/services/export_service.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/export_bloc.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/export_event.dart';
import 'package:dr_copilot/src/features/settings/presentation/bloc/export_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/subscription/domain/services/subscription_service.dart';

class ExportDataPage extends StatelessWidget {
  const ExportDataPage({super.key});

  Future<String?> _getPrimaryClinicId(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data()?['primaryClinicId'] as String?;
    } catch (e) {
      debugPrint('Error fetching primary clinic ID: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final navMenuButton = NavMenuButtonProvider.of(context);
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('exportMyData'.tr()),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
        body: Center(child: Text('pleaseSignIn'.tr())),
      );
    }

    return FutureBuilder<String?>(
      future: _getPrimaryClinicId(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('exportMyData'.tr()),
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return BlocProvider(
          create: (context) => ExportBloc(
            exportService: ExportService(repository: ExportRepository()),
            userId: user.uid,
            userEmail: user.email ?? '',
            primaryClinicId: snapshot.data,
          ),
          child: Scaffold(
            appBar: AppBar(
              title: Text('exportMyData'.tr()),
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0.5,
              actions: [navMenuButton ?? const SizedBox()],
            ),
            body: _ExportDataBody(clinicId: snapshot.data),
          ),
        );
      },
    );
  }
}

class _ExportDataBody extends StatefulWidget {
  final String? clinicId;
  const _ExportDataBody({this.clinicId});

  @override
  State<_ExportDataBody> createState() => _ExportDataBodyState();
}

class _ExportDataBodyState extends State<_ExportDataBody> {
  bool _canExport = true;
  bool _checkingSubscription = true;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    if (widget.clinicId == null) {
      if (mounted) setState(() => _checkingSubscription = false);
      return;
    }

    final subscriptionService = sl<SubscriptionService>();
    final canExport = await subscriptionService.isFeatureAllowed(
      widget.clinicId!,
      SubscriptionFeature.exportData,
    );

    if (mounted) {
      setState(() {
        _canExport = canExport;
        _checkingSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSubscription) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_canExport) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 24),
              Text(
                'dataExportRestricted'.tr(),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'upgradeToExportData'.tr(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.push('/subscription_pricing'),
                icon: const Icon(Icons.star_border),
                label: Text('upgrade'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    return BlocConsumer<ExportBloc, ExportState>(
      listener: (context, state) {
        if (state is ExportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('exportError'.tr(args: [state.error])),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.download_outlined,
                            size: 32,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'exportDataTitle'.tr(),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'exportDataDescription'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // What's included section
              Text(
                'whatIsIncluded'.tr(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildIncludedItem(
                        context,
                        Icons.person_outline,
                        'userProfile'.tr(),
                      ),
                      _buildIncludedItem(
                        context,
                        Icons.people_outline,
                        'patientsAndDoctors'.tr(),
                      ),
                      _buildIncludedItem(
                        context,
                        Icons.description_outlined,
                        'clinicalReports'.tr(),
                      ),
                      _buildIncludedItem(
                        context,
                        Icons.event_outlined,
                        'sessionsAndEvaluations'.tr(),
                      ),
                      _buildIncludedItem(
                        context,
                        Icons.monetization_on_outlined,
                        'financialRecords'.tr(),
                      ),
                      _buildIncludedItem(
                        context,
                        Icons.chat_outlined,
                        'copilotConversations'.tr(),
                      ),
                      _buildIncludedItem(
                        context,
                        Icons.notifications_outlined,
                        'notifications'.tr(),
                        isLast: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Export status section
              if (state is ExportInProgress) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                value: state.progress,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'exportInProgress'.tr(),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${(state.progress * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: state.progress,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.currentCategory,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (state is ExportSuccess) ...[
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'exportSuccess'.tr(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'exportSuccessDescription'.tr(
                            args: [_formatBytes(state.fileSize)],
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: () => _openFile(state.filePath),
                              icon: const Icon(Icons.folder_open_outlined),
                              label: Text('openFile'.tr()),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _shareFile(state.filePath),
                              icon: const Icon(Icons.share_outlined),
                              label: Text('share'.tr()),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Export button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state is ExportInProgress
                      ? null
                      : () {
                          context.read<ExportBloc>().add(
                                const ExportDataRequested(),
                              );
                        },
                  icon: state is ExportInProgress
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(
                    state is ExportInProgress
                        ? 'exporting'.tr()
                        : state is ExportSuccess
                            ? 'exportAgain'.tr()
                            : 'startExport'.tr(),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Legal notice
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'exportLegalNotice'.tr(),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIncludedItem(
    BuildContext context,
    IconData icon,
    String label, {
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(
              Icons.check,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
        if (!isLast) const Divider(height: 24),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> _openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(filePath),
        ], text: 'exportShareText'.tr());
      }
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
}
