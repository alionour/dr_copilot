import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app/notifiers/owner_notifier.dart';
import '../../../../core/injections.dart';
import '../bloc/tasks_bloc.dart';
import '../widgets/task_item_widget.dart';

class TasksDashboardPage extends StatefulWidget {
  const TasksDashboardPage({super.key});

  @override
  State<TasksDashboardPage> createState() => _TasksDashboardPageState();
}

class _TasksDashboardPageState extends State<TasksDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TasksBloc _tasksBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tasksBloc = sl<TasksBloc>();
    _fetchTasks();
  }

  void _fetchTasks() {
    final ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId ?? '';
    final userId = ownerNotifier.ownerId;

    debugPrint(
        '📋 TasksDashboard: Fetching tasks - clinicId: $clinicId, userId: $userId');

    if (clinicId.isNotEmpty) {
      _tasksBloc.add(StreamTasks(clinicId, userId: userId));
    } else {
      debugPrint('⚠️ TasksDashboard: Clinic ID is empty!');
    }
  }

  void _onTabChanged(int index) {
    final ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId ?? '';
    final userId = ownerNotifier.ownerId;

    if (index == 0) {
      // My Tasks
      _tasksBloc.add(StreamTasks(clinicId, userId: userId));
    } else {
      // All Tasks (Team Tasks)
      // Only if admin/manager? Or visible to all? usually visible to all but only editable by owner/admin.
      // Let's allow viewing all.
      _tasksBloc
          .add(StreamTasks(clinicId, userId: null)); // userId null means all
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tasksBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We need to listen to tab changes to switch data
    // But TabController doesn't automatically trigger rebuilds or events.
    // Let's add listener in initState? better:
    // Just use `TabBar(onTap: ...)`

    return BlocProvider.value(
      value: _tasksBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('tasks'.tr()),
          bottom: TabBar(
            controller: _tabController,
            onTap: _onTabChanged,
            tabs: [
              Tab(text: 'myTasks'.tr()),
              Tab(text: 'allTasks'.tr()),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                context.pushNamed('add_task');
              },
            ),
          ],
        ),
        body: BlocConsumer<TasksBloc, TasksState>(
          listener: (context, state) {
            if (state is TasksError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: SelectionArea(child: Text('Error: ${state.message}')),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 10),
                  action: SnackBarAction(
                    label: 'Copy',
                    textColor: Colors.white,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: state.message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: SelectionArea(child: Text('Error copied to clipboard')),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is TasksLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is TasksLoaded) {
              if (state.tasks.isEmpty) {
                return Center(child: Text('noTasksFound'.tr()));
              }
              return ListView.builder(
                itemCount: state.tasks.length,
                itemBuilder: (context, index) {
                  return TaskItemWidget(task: state.tasks[index]);
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
