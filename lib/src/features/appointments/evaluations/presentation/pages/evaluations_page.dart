import 'package:dr_copilot/src/features/appointments/evaluations/presentation/bloc/evaluations_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EvaluationsPage extends StatelessWidget {
  const EvaluationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<EvaluationsBloc>().add(LoadEvaluations());
            },
          ),
        ],
      ),
      body: BlocBuilder<EvaluationsBloc, EvaluationsState>(
        builder: (context, state) {
          if (state is EvaluationsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is EvaluationsLoaded) {
            return ListView.builder(
              itemCount: state.evaluations.length,
              itemBuilder: (context, index) {
                final evaluation = state.evaluations[index];
                return ListTile(
                  title: Text(evaluation.title),
                  subtitle: Text(evaluation.description),
                );
              },
            );
          } else if (state is EvaluationsLoadFailure) {
            return Center(
                child: Text('Failed to load evaluations: ${state.error}'));
          } else {
            return const Center(child: Text('No evaluations available'));
          }
        },
      ),
    );
  }
}
