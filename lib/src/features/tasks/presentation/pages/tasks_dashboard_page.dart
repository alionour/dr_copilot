import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app/notifiers/owner_notifier.dart';
import '../../../../features/auth/domain/models/permission_enum.dart';
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
  TabController? _tabController;
  late TasksBloc _tasksBloc;
  bool _canViewAll = false;
  bool _canCreate = false;
  bool _hasAnyPermission = false;

  @override
  void initState() {
    super.initState();
    _tasksBloc = sl<TasksBloc>();
    
    // We'll initialize controller in didChangeDependencies or build 
    // because we need access to OwnerNotifier via context.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ownerNotifier = context.watch<OwnerNotifier>();
    
    _canViewAll = ownerNotifier.hasPermission(AppPermission.viewAllTasks);
    _canCreate = ownerNotifier.hasPermission(AppPermission.createTask);
    _hasAnyPermission = _canViewAll || 
                       ownerNotifier.hasPermission(AppPermission.viewOwnTasks) ||
                       _canCreate ||
                       ownerNotifier.hasPermission(AppPermission.updateTask) ||
                       ownerNotifier.hasPermission(AppPermission.deleteTask);

    final tabCount = _canViewAll ? 2 : 1;
    if (_tabController == null || _tabController!.length != tabCount) {
      _tabController?.dispose();
      _tabController = TabController(length: tabCount, vsync: this);
    }

    _fetchTasks();
  }

  void _fetchTasks() {
    final ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId ?? '';
    final userId = ownerNotifier.ownerId;

    debugPrint(
        '📋 TasksDashboard: Fetching tasks - clinicId: $clinicId, userId: $userId');

    if (clinicId.isNotEmpty) {
      if (_tabController?.index == 0 || !_canViewAll) {
        _tasksBloc.add(StreamTasks(clinicId, userId: userId));
      } else {
        _tasksBloc.add(StreamTasks(clinicId, userId: null));
      }
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
    } else if (_canViewAll) {
      // All Tasks (Team Tasks)
      _tasksBloc
          .add(StreamTasks(clinicId, userId: null)); // userId null means all
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _tasksBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyPermission) {
      return Scaffold(
        appBar: AppBar(title: Text('tasks'.tr())),
        body: Center(child: Text('noPermissionToViewTasks'.tr())),
      );
    }

    return BlocProvider.value(
      value: _tasksBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Text('tasks'.tr()),
          bottom: _canViewAll
              ? TabBar(
                  controller: _tabController,
                  onTap: _onTabChanged,
                  tabs: [
                    Tab(text: 'myTasks'.tr()),
                    Tab(text: 'allTasks'.tr()),
                  ],
                )
              : null,
          actions: [
            if (_canCreate)
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
              return const ShimmerList();
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
