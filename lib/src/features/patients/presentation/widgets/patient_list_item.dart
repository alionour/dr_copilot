import 'package:dartz/dartz.dart' hide State;
import 'package:dr_copilot/src/core/injections.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/presentation/bloc/patients_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class PatientListItem extends StatefulWidget {
  final PatientModel patientModel;
  final VoidCallback onTap;

  const PatientListItem({
    super.key,
    required this.patientModel,
    required this.onTap,
  });

  @override
  State<PatientListItem> createState() => _PatientListItemState();
}

class _PatientListItemState extends State<PatientListItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                        Builder(
                          builder: (context) {
                            final isAgeEmpty = widget.patientModel.age == null;
                            final isGenderEmpty = widget.patientModel.gender == null || widget.patientModel.gender!.trim().isEmpty;
                            final ageVal = isAgeEmpty ? 'not_available'.tr() : widget.patientModel.age.toString();
                            String genderVal = 'not_available'.tr();
                            if (!isGenderEmpty) {
                              final gender = widget.patientModel.gender!.toLowerCase();
                              if (gender == 'male') {
                                genderVal = 'male'.tr();
                              } else if (gender == 'female') {
                                genderVal = 'female'.tr();
                              } else {
                                genderVal = widget.patientModel.gender!;
                              }
                            }
                            return Text(
                              '${'age'.tr()}: $ageVal • $genderVal',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
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
                    Icons.location_on_outlined,
                    'address'.tr(),
                    widget.patientModel.address,
                  ),
                  _buildDetailRow(
                    context,
                    Icons.phone_outlined,
                    '${'phoneNumber'.tr()} 1',
                    widget.patientModel.phone1,
                  ),
                  _buildDetailRow(
                    context,
                    Icons.phone_iphone_outlined,
                    '${'phoneNumber'.tr()} 2',
                    widget.patientModel.phone2,
                  ),
                  _buildDoctorRow(context),
                  _buildDetailRow(
                    context,
                    Icons.work_outline,
                    'occupation'.tr(),
                    widget.patientModel.occupation,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.pushNamed(
                            'patient_details',
                            pathParameters: {
                              'patientId': widget.patientModel.id,
                            },
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: Text('viewDetails'.tr()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(color: colorScheme.primary),
                        ),
                      ),
                      if (OwnerNotifier()
                          .hasPermission(AppPermission.updatePatient))
                        OutlinedButton.icon(
                          onPressed: () {
                            context.pushNamed(
                              'edit_patient',
                              extra: widget.patientModel,
                            );
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text('edit'.tr()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                            side: BorderSide(color: colorScheme.primary),
                          ),
                        ),
                      if (OwnerNotifier()
                          .hasPermission(AppPermission.deletePatient))
                        OutlinedButton.icon(
                          onPressed: () {
                            context.read<PatientsBloc>().add(
                                  DeletePatient(widget.patientModel.id),
                                );
                          },
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

  Widget _buildDoctorRow(BuildContext context) {
    if (widget.patientModel.treatingDoctorId == null) {
      return _buildDetailRow(
        context,
        Icons.medical_services_outlined,
        'treatingDoctor'.tr(),
        null,
      );
    }

    return FutureBuilder(
      future: sl<DoctorsUseCase>().getDoctor(widget.patientModel.treatingDoctorId!),
      builder: (context, snapshot) {
        String? doctorName;
        if (snapshot.hasData) {
          final result = snapshot.data as Either;
          result.fold(
            (l) => null,
            (r) => doctorName = r.name,
          );
        }
        return _buildDetailRow(
          context,
          Icons.medical_services_outlined,
          'treatingDoctor'.tr(),
          doctorName,
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String? value,
  ) {
    final isValueEmpty = value == null || value.trim().isEmpty;
    final displayValue = isValueEmpty ? 'not_available'.tr() : value;
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
                  displayValue,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isValueEmpty
                        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                        : theme.colorScheme.onSurface,
                    fontStyle: isValueEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
