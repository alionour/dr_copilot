import 'package:dr_copilot/src/features/appointments/sessions/presentation/bloc/sessions_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SessionsBloc>().add(LoadSessions());
            },
          ),
        ],
      ),
      body: BlocBuilder<SessionsBloc, SessionsState>(
        builder: (context, state) {
          if (state is SessionsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SessionsLoaded) {
            if (state.sessions.isEmpty) {
              return const Center(child: Text('No sessions available'));
            }
            return ListView.builder(
              itemCount: state.sessions.length,
              itemBuilder: (context, index) {
                final session = state.sessions[index];
                return ListTile(
                  title: Text(session.title),
                  subtitle: Text(session.description),
                );
              },
            );
          } else {
            return const Center(child: Text('Failed to load sessions'));
          }
        },
      ),
    );
  }
}
