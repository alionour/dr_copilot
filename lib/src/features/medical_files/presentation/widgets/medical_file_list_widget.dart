import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';
import 'package:dr_copilot/src/features/medical_files/domain/models/medical_file_model.dart';
import 'package:dr_copilot/src/features/medical_files/presentation/bloc/medical_file_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalFileListWidget extends StatelessWidget {
  final String patientId;

  const MedicalFileListWidget({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicalFileBloc, MedicalFileState>(
      listener: (context, state) {
        if (state is MedicalFileOperationSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: SelectionArea(child: Text(state.message))));
        } else if (state is MedicalFileError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: SelectionArea(child: Text(state.message))));
        }
      },
      builder: (context, state) {
        if (state is MedicalFileLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MedicalFilesLoaded) {
          if (state.medicalFiles.isEmpty) {
            return Center(child: Text('noFilesFound'.tr()));
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // Adjust for responsiveness later
              childAspectRatio: 0.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: state.medicalFiles.length,
            itemBuilder: (context, index) {
              final file = state.medicalFiles[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    if (file.fileUrl != null) {
                      final uri = Uri.parse(file.fileUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    } else {
                      // Show details dialog for key-value only records
                      _showDetailsDialog(context, file);
                    }
                  },
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: file.fileUrl != null
                                ? (file.type == 'X-Ray' ||
                                        file.type == 'Image' ||
                                        file.fileUrl!.endsWith('.jpg') ||
                                        file.fileUrl!.endsWith('.png'))
                                    ? Image.network(
                                        file.fileUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.insert_drive_file,
                                          size: 50,
                                        ),
                                      )
                                : const Center(
                                    child: Icon(Icons.info, size: 50),
                                  ), // No file, just data
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  file.date.toLocal().toString().split(' ')[0],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (file.metadata != null &&
                                    file.metadata!.isNotEmpty)
                                  Text(
                                    '${file.metadata!.length} attributes',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: _buildOptionsMenu(context, file),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return Center(
          child: TextButton(
            onPressed: () {
              context.read<MedicalFileBloc>().add(LoadMedicalFiles(patientId));
            },
            child: Text('retry'.tr()),
          ),
        );
      },
    );
  }

  void _showDetailsDialog(BuildContext context, dynamic file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(file.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Date: ${file.date.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (file.metadata != null && file.metadata!.isNotEmpty) ...[
                const Text(
                  'Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...file.metadata!.entries.map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${entry.key}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(entry.value.toString()),
                          ),
                        ],
                      ),
                    )),
              ] else
                const Text('No additional details available.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('close'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsMenu(BuildContext context, MedicalFileModel file) {
    final canEdit = OwnerNotifier().hasPermission(AppPermission.updateMedicalFile);
    final canDelete = OwnerNotifier().hasPermission(AppPermission.deleteMedicalFile);

    if (!canEdit && !canDelete) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, size: 20),
        padding: EdgeInsets.zero,
        onSelected: (value) {
          if (value == 'edit') {
            context.push('/patients/${file.patientId}/medical-records/new', extra: file);
          } else if (value == 'delete') {
            _showDeleteConfirmation(context, file);
          }
        },
        itemBuilder: (context) => [
          if (canEdit)
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20),
                  const SizedBox(width: 8),
                  Text('edit'.tr()),
                ],
              ),
            ),
          if (canDelete)
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, MedicalFileModel file) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('delete'.tr()),
          content: SelectionArea(child: Text('Are you sure you want to delete this medical file?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                context.read<MedicalFileBloc>().add(DeleteMedicalFile(file));
              },
              child: Text('delete'.tr(), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
