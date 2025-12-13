import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/bloc/recycle_bin_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class RecycleBinPage extends StatelessWidget {
  const RecycleBinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<RecycleBinBloc>()..add(LoadDeletedItems()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Recycle Bin')),
        body: BlocConsumer<RecycleBinBloc, RecycleBinState>(
          listener: (context, state) {
            if (state is RecycleBinError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is RecycleBinLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is RecycleBinLoaded) {
              final items = state.allItems;

              if (items.isEmpty) {
                return const Center(child: Text('Recycle Bin is empty'));
              }

              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _RecycleBinItemTile(item: item);
                },
              );
            }
            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }
}

class _RecycleBinItemTile extends StatelessWidget {
  final dynamic item;

  const _RecycleBinItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final isEvaluation = item is EvaluationModel;
    final id = isEvaluation
        ? (item as EvaluationModel).id
        : (item as SessionModel).id;
    final deletedAt = isEvaluation
        ? (item as EvaluationModel).deletedAt?.toDate()
        : (item as SessionModel).deletedAt?.toDate();
    final patientName = isEvaluation
        ? (item as EvaluationModel).patientName
        : (item as SessionModel)
              .patientName; // Assuming SessionModel has patientName populated

    // Note: SessionModel might not have patientName populated if not handled in getDeletedSessions
    // But we did handle it in getDeletedSessions.

    final title = isEvaluation ? 'Evaluation' : 'Session';
    final subtitle =
        'Patient: $patientName\nDeleted: ${deletedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(deletedAt) : 'Unknown'}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          isEvaluation ? Icons.assignment : Icons.calendar_today,
          color: isEvaluation ? Colors.blue : Colors.green,
        ),
        title: Text('$title - ${id.substring(0, 5)}...'), // Shortened ID
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Restore',
              onPressed: () {
                context.read<RecycleBinBloc>().add(
                  RestoreItem(
                    id: id,
                    type: isEvaluation
                        ? RecycleBinItemType.evaluation
                        : RecycleBinItemType.session,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Delete Permanently',
              onPressed: () {
                _showDeleteConfirmation(context, id, isEvaluation);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String id,
    bool isEvaluation,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Permanently?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to permanently delete this item?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<RecycleBinBloc>().add(
                PermanentlyDeleteItem(
                  id: id,
                  type: isEvaluation
                      ? RecycleBinItemType.evaluation
                      : RecycleBinItemType.session,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
