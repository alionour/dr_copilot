part of 'tasks_bloc.dart';

abstract class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

class StreamTasks extends TasksEvent {
  final String clinicId;
  final String?
      userId; // If null, fetch all tasks (e.g. for admin/manager view, or unfiltered)

  const StreamTasks(this.clinicId, {this.userId});

  @override
  List<Object?> get props => [clinicId, userId];
}

class UpdateTasksList extends TasksEvent {
  final List<TaskModel> tasks;

  const UpdateTasksList(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class CreateTask extends TasksEvent {
  final TaskModel task;

  const CreateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class UpdateTask extends TasksEvent {
  final TaskModel task;

  const UpdateTask(this.task);

  @override
  List<Object?> get props => [task];
}

class DeleteTask extends TasksEvent {
  final String taskId;

  const DeleteTask(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class MarkTaskAsDone extends TasksEvent {
  final String taskId;

  const MarkTaskAsDone(this.taskId);

  @override
  List<Object?> get props => [taskId];
}

class TasksStreamError extends TasksEvent {
  final String message;

  const TasksStreamError(this.message);

  @override
  List<Object?> get props => [message];
}
