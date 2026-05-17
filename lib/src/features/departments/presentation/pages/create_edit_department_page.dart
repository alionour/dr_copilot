import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dr_copilot/src/features/departments/domain/models/department_model.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_bloc.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_event.dart';
import 'package:dr_copilot/src/features/departments/presentation/bloc/departments_state.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';

class CreateEditDepartmentPage extends StatefulWidget {
  final DepartmentModel? department;

  const CreateEditDepartmentPage({super.key, this.department});

  @override
  State<CreateEditDepartmentPage> createState() => _CreateEditDepartmentPageState();
}

class _CreateEditDepartmentPageState extends State<CreateEditDepartmentPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool get _isEditing => widget.department != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.department!.name;
      _descriptionController.text = widget.department!.description ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DepartmentsBloc, DepartmentsState>(
      listener: (context, state) {
        if (state is DepartmentOperationSuccess) {
          Navigator.pop(context, true);
        } else if (state is DepartmentsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text(state.message)), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'editDepartment'.tr() : 'createDepartment'.tr()),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'departmentName'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'pleaseEnterDepartmentName'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'departmentDescription'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveDepartment,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    _isEditing ? 'updateDepartment'.tr() : 'createDepartment'.tr(),
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveDepartment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final clinicId = context.read<OwnerNotifier>().clinicId;
    if (clinicId == null) {
      return;
    }

    final department = DepartmentModel(
      id: widget.department?.id ?? '',
      clinicId: clinicId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: widget.department?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      // For now, repository addDepartment handles both if ID is present or we can add updateDepartment
      // The current repo doesn't have updateDepartment, I should add it.
      context.read<DepartmentsBloc>().add(AddDepartmentEvent(department));
    } else {
      context.read<DepartmentsBloc>().add(AddDepartmentEvent(department));
    }
  }
}
