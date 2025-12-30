import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/sessions/domain/models/session_model.dart';
import 'package:dr_copilot/src/features/calendar_events/domain/models/calendar_event_model.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/bloc/recycle_bin_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class SessionItemTile extends StatelessWidget {
  final SessionModel session;

  const SessionItemTile({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final deletedAt = session.deletedAt?.toDate();
    final patientName = session.patientName;
    final subtitle =
        'Patient: $patientName\nDeleted: ${deletedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(deletedAt) : 'Unknown'}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(
          Icons.calendar_today_outlined,
          color: Colors.green,
        ),
        title: Text('Session - ${session.id.substring(0, 5)}...'),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'restore'.tr(),
              onPressed: () {
                context.read<RecycleBinBloc>().add(
                      RestoreItem(
                        id: session.id,
                        type: RecycleBinItemType.session,
                      ),
                    );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_forever_outlined, color: Colors.red),
              tooltip: 'deletePermanently'.tr(),
              onPressed: () {
                _showDeleteConfirmation(context, session.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteConfirmation'.tr()),
        content: Text('deleteConfirmationMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<RecycleBinBloc>().add(
                    PermanentlyDeleteItem(
                      id: id,
                      type: RecycleBinItemType.session,
                    ),
                  );
            },
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class EvaluationItemTile extends StatelessWidget {
  final EvaluationModel evaluation;

  const EvaluationItemTile({super.key, required this.evaluation});

  @override
  Widget build(BuildContext context) {
    final deletedAt = evaluation.deletedAt?.toDate();
    final patientName = evaluation.patientName;
    final subtitle =
        'Patient: $patientName\nDeleted: ${deletedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(deletedAt) : 'Unknown'}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(
          Icons.assignment_outlined,
          color: Colors.blue,
        ),
        title: Text('Evaluation - ${evaluation.id.substring(0, 5)}...'),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'restore'.tr(),
              onPressed: () {
                context.read<RecycleBinBloc>().add(
                      RestoreItem(
                        id: evaluation.id,
                        type: RecycleBinItemType.evaluation,
                      ),
                    );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_forever_outlined, color: Colors.red),
              tooltip: 'deletePermanently'.tr(),
              onPressed: () {
                _showDeleteConfirmation(context, evaluation.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteConfirmation'.tr()),
        content: Text('deleteConfirmationMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<RecycleBinBloc>().add(
                    PermanentlyDeleteItem(
                      id: id,
                      type: RecycleBinItemType.evaluation,
                    ),
                  );
            },
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class PatientItemTile extends StatelessWidget {
  final PatientModel patient;

  const PatientItemTile({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final deletedAt = patient.deletedAt?.toDate();
    final subtitle =
        'Deleted: ${deletedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(deletedAt) : 'Unknown'}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(
          Icons.person_outline,
          color: Colors.orange,
        ),
        title: Text(patient.name ?? 'Unknown Patient'),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'restore'.tr(),
              onPressed: () {
                context.read<RecycleBinBloc>().add(
                      RestoreItem(
                        id: patient.id,
                        type: RecycleBinItemType.patient,
                      ),
                    );
              },
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_forever_outlined, color: Colors.red),
              tooltip: 'deletePermanently'.tr(),
              onPressed: () {
                _showDeleteConfirmation(context, patient.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteConfirmation'.tr()),
        content: Text('deleteConfirmationMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<RecycleBinBloc>().add(
                    PermanentlyDeleteItem(
                      id: id,
                      type: RecycleBinItemType.patient,
                    ),
                  );
            },
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CalendarEventItemTile extends StatelessWidget {
  final CalendarEventModel event;

  const CalendarEventItemTile({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final deletedAt = event.deletedAt?.toDate();
    final subtitle =
        'Deleted: ${deletedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(deletedAt) : 'Unknown'}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: const Icon(
          Icons.event,
          color: Colors.purple,
        ),
        title: Text(event.title),
        subtitle: Text('$subtitle\n${event.startDateTime.toDate()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'restore'.tr(),
              onPressed: () {
                context.read<RecycleBinBloc>().add(
                      RestoreItem(
                        id: event.id,
                        type: RecycleBinItemType.calendarEvent,
                      ),
                    );
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'deletePermanently'.tr(),
              onPressed: () {
                _showDeleteConfirmation(context, event.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('deleteConfirmation'.tr()),
        content: Text('deleteConfirmationMessage'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<RecycleBinBloc>().add(
                    PermanentlyDeleteItem(
                      id: id,
                      type: RecycleBinItemType.calendarEvent,
                    ),
                  );
            },
            child:
                Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
