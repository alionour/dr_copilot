import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart' as localization;

class PatientListItemModern extends StatefulWidget {
  final PatientModel patientModel;
  final VoidCallback onTap;

  const PatientListItemModern({
    super.key,
    required this.patientModel,
    required this.onTap,
  });

  @override
  State<PatientListItemModern> createState() => _PatientListItemModernState();
}

class _PatientListItemModernState extends State<PatientListItemModern> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 2, // Softer shadow
      shadowColor: colorScheme.shadow.withOpacity(0.1),
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
                    radius: 28, // Larger avatar
                    backgroundColor: colorScheme.primaryContainer,
                    child: Text(
                      widget.patientModel.name.isNotEmpty
                          ? widget.patientModel.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.patientModel.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${'age'.tr()}: ${widget.patientModel.age ?? 'N/A'} • ${widget.patientModel.gender ?? 'N/A'}',
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
                  _buildDetailRow(context, 'address'.tr(), 'address',
                      widget.patientModel.address),
                  _buildDetailRow(context, 'phoneNumber'.tr(), 'phoneNumber',
                      widget.patientModel.phoneNumber),
                  _buildDetailRow(
                      context,
                      'alternativePhoneNumber'.tr(),
                      'alternativePhoneNumber',
                      widget.patientModel.alternativePhoneNumber),
                  _buildDetailRow(context, 'treatingDoctor'.tr(),
                      'treatingDoctor', widget.patientModel.treatingDoctor),
                  _buildDetailRow(context, 'occupation'.tr(), 'occupation',
                      widget.patientModel.occupation),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton.filledTonal(
                        onPressed: () {
                          context.pushNamed(
                            'edit_patient',
                            extra: widget.patientModel,
                          );
                        },
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'edit'.tr(),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () {
                          context
                              .read<PatientsBloc>()
                              .add(DeletePatient(widget.patientModel.id));
                        },
                        icon: const Icon(Icons.delete_outline),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              colorScheme.errorContainer.withOpacity(0.5),
                          foregroundColor: colorScheme.error,
                        ),
                        tooltip: 'delete'.tr(),
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
      BuildContext context, String label, String key, String? value) {
    final displayValue = value ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
