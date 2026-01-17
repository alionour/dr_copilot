import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

class EvaluationListItem extends StatefulWidget {
  final EvaluationModel evaluationModel;
  final VoidCallback onTap;

  const EvaluationListItem({
    super.key,
    required this.evaluationModel,
    required this.onTap,
  });

  @override
  State<EvaluationListItem> createState() => _EvaluationListItemState();
}

class _EvaluationListItemState extends State<EvaluationListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 2,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: colorScheme.tertiaryContainer,
                    child: Text(
                      widget.evaluationModel.patientName.isNotEmpty
                          ? widget.evaluationModel.patientName[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.evaluationModel.patientName,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(widget.evaluationModel.startDateTime.toDate())} • ${timeFormat.format(widget.evaluationModel.startDateTime.toDate())}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(),
                  _buildDetailRow(
                    context,
                    Icons.timer_outlined,
                    'duration'.tr(),
                    _calculateDuration(
                      widget.evaluationModel.startDateTime,
                      widget.evaluationModel.endDateTime,
                    ),
                  ),
                  _buildDetailRow(
                    context,
                    Icons.attach_money_outlined,
                    'price'.tr(),
                    widget.evaluationModel.price.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            'edit_evaluation',
                            extra: widget.evaluationModel,
                          );
                        },
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: Text('edit'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _showDeleteConfirmation(context),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: Text('delete'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          side: BorderSide(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _calculateDuration(dynamic start, dynamic end) {
    final startTime = start.toDate();
    final endTime = end.toDate();
    final duration = endTime.difference(startTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    bool deleteInvoiceAndTransaction = true;
    final result = await showDialog<_DeleteEvaluationDialogResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('deleteEvaluationTitle'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('deleteEvaluationConfirm'.tr()),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    value: deleteInvoiceAndTransaction,
                    onChanged: (val) {
                      setState(() {
                        deleteInvoiceAndTransaction = val ?? true;
                      });
                    },
                    title: Text(
                      'deleteCorrespondingInvoiceAndTransaction'.tr(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      _DeleteEvaluationDialogResult(
                        deleteEvaluationAndTransaction:
                            deleteInvoiceAndTransaction,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: Text('delete'.tr()),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && context.mounted) {
      // Assuming the bloc event only takes ID for now based on previous file content
      context.read<EvaluationsBloc>().add(
        DeleteEvaluation(widget.evaluationModel.id),
      );
    }
  }
}

class _DeleteEvaluationDialogResult {
  final bool deleteEvaluationAndTransaction;
  _DeleteEvaluationDialogResult({required this.deleteEvaluationAndTransaction});
}

