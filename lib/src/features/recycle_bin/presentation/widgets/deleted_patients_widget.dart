import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/widgets/recycle_bin_item_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DeletedPatientsWidget extends StatelessWidget {
  final List<PatientModel> patients;

  const DeletedPatientsWidget({
    super.key,
    required this.patients,
  });

  @override
  Widget build(BuildContext context) {
    if (patients.isEmpty) {
      return Center(
        child: Text(
          'noDeletedPatients'.tr(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index];
        return PatientItemTile(patient: patient);
      },
    );
  }
}
