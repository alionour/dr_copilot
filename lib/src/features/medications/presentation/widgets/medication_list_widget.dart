import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/medications/presentation/bloc/medication_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';

class MedicationListWidget extends StatelessWidget {
  final String patientId;

  const MedicationListWidget({super.key, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MedicationBloc, MedicationState>(
      listener: (context, state) {
        if (state is MedicationOperationSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: SelectionArea(child: Text(state.message))));
        } else if (state is MedicationError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: SelectionArea(child: Text(state.message))));
        }
      },
      builder: (context, state) {
        if (state is MedicationLoading) {
          return const ShimmerList(itemCount: 3);
        }

        if (state is MedicationsLoaded) {
          if (state.medications.isEmpty) {
            return Center(child: Text('noMedicationsFound'.tr()));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.medications.length,
            itemBuilder: (context, index) {
              final medication = state.medications[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.medication),
                  title: Text(medication.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (medication.dosage != null)
                        Text('Dosage: ${medication.dosage}'),
                      if (medication.frequency != null)
                        Text('Frequency: ${medication.frequency}'),
                      Text(
                        'Started: ${medication.startDate.toLocal().toString().split(' ')[0]}',
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (medication.fileUrl != null)
                        IconButton(
                          icon: const Icon(Icons.image),
                          onPressed: () async {
                            final uri = Uri.parse(medication.fileUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          context.read<MedicationBloc>().add(
                            DeleteMedication(medication),
                          );
                        },
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
              context.read<MedicationBloc>().add(LoadMedications(patientId));
            },
            child: Text('retry'.tr()),
          ),
        );
      },
    );
  }
}

