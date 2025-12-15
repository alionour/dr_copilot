import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_list_bloc.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_list_event.dart';
import 'package:dr_copilot/src/features/chatgpt_project/presentation/bloc/chatgpt_project_list_state.dart';

final getIt = GetIt.instance;

class ChatGptProjectListPage extends StatelessWidget {
  const ChatGptProjectListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('chatGptProject'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement navigation to add new ChatGPT project page
            },
          ),
        ],
      ),
      body: BlocProvider(
        create: (context) => getIt<ChatGptProjectListBloc>()
          ..add(const LoadChatGptProjectList()),
        child: BlocConsumer<ChatGptProjectListBloc, ChatGptProjectListState>(
          listener: (context, state) {
            if (state is ChatGptProjectListApiKeyMissing) {
              context.push('/settings/api_key?from=chatgpt_project');
            }
          },
          builder: (context, state) {
            if (state is ChatGptProjectListLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ChatGptProjectListApiKeyMissing) {
              // This state is handled by the listener, but we need to return a widget here
              // to avoid an error. The listener will navigate away.
              return const SizedBox.shrink();
            }
            if (state is ChatGptProjectListError) {
              return Center(child: Text('Error: ${state.message}'));
            }
            if (state is ChatGptProjectListLoaded) {
              if (state.projects.isEmpty) {
                return Center(
                  child: Text('noChatGptProjectsFound'.tr()),
                );
              }
              return ListView.builder(
                itemCount: state.projects.length,
                itemBuilder: (context, index) {
                  final project = state.projects[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 4.0, horizontal: 8.0),
                    child: ListTile(
                      title: Text(project.name),
                      subtitle: Text(project.description),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Implement navigation to ChatGPT project details page
                      },
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('Something went wrong.'));
          },
        ),
      ),
    );
  }
}

