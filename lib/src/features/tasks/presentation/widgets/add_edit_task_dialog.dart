import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/app/notifiers/owner_notifier.dart';
import '../../domain/models/task_model.dart';
import '../bloc/tasks_bloc.dart';

class AddEditTaskDialog extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskDialog({super.key, this.task});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final ownerNotifier = context.read<OwnerNotifier>();
      final clinicId = ownerNotifier.clinicId;
      final userId = ownerNotifier.ownerId;

      if (clinicId == null || userId == null) return;

      final now = DateTime.now();

      final newTask = TaskModel(
        id: widget.task?.id ?? const Uuid().v4(),
        clinicId: clinicId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        assignedToUserId: userId, // assigning to self by default for now
        assignedByUserId: userId,
        status: widget.task?.status ?? 'pending',
        priority: _priority,
        dueDate: _dueDate,
        createdAt: widget.task?.createdAt ?? now,
        updatedAt: now,
      );

      if (widget.task == null) {
        context.read<TasksBloc>().add(CreateTask(newTask));
      } else {
        context.read<TasksBloc>().add(UpdateTask(newTask));
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    return AlertDialog(
      title: Text(isEdit ? 'editTask'.tr() : 'addTask'.tr()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'taskTitle'.tr()),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'pleaseEnterTitle'.tr();
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'description'.tr()),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: InputDecoration(labelText: 'priority'.tr()),
                items: ['low', 'medium', 'high', 'urgent']
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate == null
                    ? 'setDueDate'.tr()
                    : DateFormat('yyyy-MM-dd').format(_dueDate!)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      _dueDate = picked;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEdit ? 'save'.tr() : 'add'.tr()),
        ),
      ],
    );
  }
}
