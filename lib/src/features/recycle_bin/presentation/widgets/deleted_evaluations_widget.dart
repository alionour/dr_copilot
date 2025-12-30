import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:dr_copilot/src/features/recycle_bin/presentation/widgets/recycle_bin_item_tile.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DeletedEvaluationsWidget extends StatelessWidget {
  final List<EvaluationModel> evaluations;

  const DeletedEvaluationsWidget({
    super.key,
    required this.evaluations,
  });

  @override
  Widget build(BuildContext context) {
    if (evaluations.isEmpty) {
      return Center(
        child: Text(
          'noDeletedEvaluations'.tr(),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: evaluations.length,
      itemBuilder: (context, index) {
        final evaluation = evaluations[index];
        return EvaluationItemTile(evaluation: evaluation);
      },
    );
  }
}
