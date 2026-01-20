import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/app/notifiers/owner_notifier.dart';
import '../../domain/models/task_model.dart';
import '../bloc/tasks_bloc.dart';

class AddEditTaskPage extends StatefulWidget {
  final TaskModel? task;

  const AddEditTaskPage({super.key, this.task});

  @override
  State<AddEditTaskPage> createState() => _AddEditTaskPageState();
}

class _AddEditTaskPageState extends State<AddEditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _priority;
  DateTime? _dueDate;
  String? _assignedToUserId;
  List<Map<String, String>> _teamMembers = [];
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? 'medium';
    _dueDate = widget.task?.dueDate;
    _assignedToUserId = widget.task?.assignedToUserId;
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    final ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId;

    if (clinicId == null) {
      setState(() => _loadingMembers = false);
      return;
    }

    try {
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('clinics')
          .doc(clinicId)
          .collection('members')
          .get();

      final members = <Map<String, String>>[];

      for (var doc in membersSnapshot.docs) {
        final data = doc.data();
        members.add({
          'id': doc.id,
          'name': data['displayName'] as String? ??
              data['email'] as String? ??
              'Unknown',
          'role': data['role'] as String? ?? 'staff',
        });
      }

      setState(() {
        _teamMembers = members;
        _loadingMembers = false;
      });
    } catch (e) {
      debugPrint('Error loading team members: $e');
      setState(() => _loadingMembers = false);
    }
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
        assignedToUserId:
            _assignedToUserId ?? userId, // Use selected user or self
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
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'editTask'.tr() : 'addTask'.tr()),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'taskTitle'.tr(),
                  border: const OutlineInputBorder(),
                ),
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
                decoration: InputDecoration(
                  labelText: 'description'.tr(),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              // Team Member Assignment Dropdown
              if (_loadingMembers)
                const LinearProgressIndicator()
              else
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'assignTo'.tr(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _assignedToUserId,
                      isExpanded: true,
                      hint: Text('selectTeamMember'.tr()),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('unassigned'.tr()),
                        ),
                        ..._teamMembers.map((member) {
                          return DropdownMenuItem<String?>(
                            value: member['id'],
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    member['name']!.isNotEmpty
                                        ? member['name']![0].toUpperCase()
                                        : '?',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${member['name']} (${member['role']})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _assignedToUserId = value;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: InputDecoration(
                  labelText: 'priority'.tr(),
                  border: const OutlineInputBorder(),
                ),
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
              InkWell(
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
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'dueDate'.tr(),
                    border: const OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_dueDate == null
                          ? 'setDueDate'.tr()
                          : DateFormat('yyyy-MM-dd').format(_dueDate!)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEdit ? 'save'.tr() : 'add'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
