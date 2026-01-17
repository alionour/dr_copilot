import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/task_model.dart';
import '../bloc/tasks_bloc.dart';

class TaskItemWidget extends StatelessWidget {
  final TaskModel task;

  const TaskItemWidget({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    // Determine priority color
    Color priorityColor;
    switch (task.priority.toLowerCase()) {
      case 'urgent':
        priorityColor = Colors.red;
        break;
      case 'high':
        priorityColor = Colors.orange;
        break;
      case 'medium':
        priorityColor = Colors.blue;
        break;
      default:
        priorityColor = Colors.grey;
    }

    final isDone = task.status == 'done';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Checkbox(
          value: isDone,
          onChanged: (bool? value) {
            if (value == true) {
              context.read<TasksBloc>().add(MarkTaskAsDone(task.id));
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: isDone ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description.isNotEmpty)
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            if (task.dueDate != null)
              Text(
                'Due: ${_formatDate(task.dueDate!)}',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: priorityColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: priorityColor),
          ),
          child: Text(
            task.priority.toUpperCase(),
            style: TextStyle(
              color: priorityColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // TODO: Open edit dialog or details
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
