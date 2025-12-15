import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_bloc.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/widgets/chatgpt_project_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatGptProjectPage extends StatelessWidget {
  const ChatGptProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final clinicNameController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatGPT Project'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: clinicNameController,
              decoration: const InputDecoration(
                labelText: 'Clinic Name',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final clinicName = clinicNameController.text;
                if (clinicName.isNotEmpty) {
                  context
                      .read<ChatGptProjectBloc>()
                      .add(GetProject(name: clinicName));
                }
              },
              child: const Text('Get or Create Project'),
            ),
            const SizedBox(height: 16),
            BlocBuilder<ChatGptProjectBloc, ChatGptProjectState>(
              builder: (context, state) {
                if (state is ChatGptProjectLoading) {
                  return const CircularProgressIndicator();
                } else if (state is ChatGptProjectLoaded) {
                  return ChatGptProjectWidget(project: state.project);
                } else if (state is ChatGptProjectError) {
                  return Text(state.message);
                } else {
                  return const SizedBox.shrink();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

