import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/core/widgets/shimmer_loading.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_bloc.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_event.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_state.dart';
import 'package:dr_copilot/src/features/departments/presentation/pages/create_edit_department_page.dart';
import 'package:dr_copilot/src/features/departments/presentation/pages/department_detail_page.dart';
import 'package:dr_copilot/src/features/departments/domain/models/department_model.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/auth/domain/models/permission_enum.dart';

class DepartmentsDashboardPage extends StatefulWidget {
  const DepartmentsDashboardPage({super.key});

  @override
  State<DepartmentsDashboardPage> createState() => _DepartmentsDashboardPageState();
}

class _DepartmentsDashboardPageState extends State<DepartmentsDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDepartments();
    });
  }

  void _loadDepartments() {
    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (clinicId != null) {
      context.read<DepartmentsBloc>().add(
            LoadDepartmentsEvent(clinicId),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('departmentsTitle'.tr()),
        actions: [
          if (OwnerNotifier().hasPermission(AppPermission.manageDepartments))
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'createDepartment'.tr(),
              onPressed: () => _navigateToCreateEdit(null),
            ),
        ],
      ),
      body: BlocConsumer<DepartmentsBloc, DepartmentsState>(
        listener: (context, state) {
          if (state is DepartmentOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectionArea(child: Text(state.message)),
                backgroundColor: Colors.green,
              ),
            );
            _loadDepartments();
          } else if (state is DepartmentsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: SelectionArea(child: Text(state.message)),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DepartmentsLoading) {
            return const ShimmerList();
          }

          if (state is DepartmentsLoaded) {
            if (state.departments.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.business_outlined,
                        size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'noDepartmentsYet'.tr(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'createFirstDepartment'.tr(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.departments.length,
              itemBuilder: (context, index) {
                final dept = state.departments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    onTap: () => _navigateToDepartmentDetail(dept),
                    leading: CircleAvatar(
                      child: Text(dept.name.substring(0, 1).toUpperCase()),
                    ),
                    title: Text(dept.name),
                    subtitle: dept.description != null && dept.description!.isNotEmpty
                        ? Text(dept.description!)
                        : null,
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit_outlined),
                              const SizedBox(width: 8),
                              Text('edit'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _navigateToCreateEdit(dept);
                        } else if (value == 'delete') {
                          _showDeleteConfirmation(dept.id, dept.name);
                        }
                      },
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _navigateToCreateEdit(dynamic department) async {
    final departmentsBloc = context.read<DepartmentsBloc>();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(
          value: departmentsBloc,
          child: CreateEditDepartmentPage(department: department),
        ),
      ),
    );

    if (result == true) {
      _loadDepartments();
    }
  }

  void _navigateToDepartmentDetail(DepartmentModel department) {
    final departmentsBloc = context.read<DepartmentsBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: departmentsBloc,
          child: DepartmentDetailPage(department: department),
        ),
      ),
    ).then((_) => _loadDepartments());
  }

  void _showDeleteConfirmation(String id, String name) {
    final departmentsBloc = context.read<DepartmentsBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('deleteDepartment'.tr()),
        content: SelectionArea(child: Text('deleteDepartmentConfirm'.tr(namedArgs: {'name': name}))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              final clinicId = context.read<OwnerNotifier>().clinicId;
              if (clinicId != null) {
                departmentsBloc.add(DeleteDepartmentEvent(id, clinicId));
              }
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
  }
}
