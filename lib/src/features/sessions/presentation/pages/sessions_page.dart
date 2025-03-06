import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/sessions_bloc.dart';
import '../bloc/sessions_event.dart';
import '../bloc/sessions_state.dart';

class SessionsPage extends StatelessWidget {
  const SessionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
      ),
      body: BlocBuilder<SessionsBloc, SessionsState>(
        builder: (context, state) {
          if (state is SessionsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is SessionsLoaded) {
            // Display session data
            return const Center(child: Text('Sessions Loaded'));
          } else if (state is SessionsError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Press button to load sessions'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<SessionsBloc>().add(LoadSessions());
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
