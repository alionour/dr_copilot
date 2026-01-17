import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/task_model.dart';

abstract class AbstractTaskRepository {
  /// Stream of tasks for a specific clinic.
  /// Optionally filtered by user ID (e.g., "My Tasks").
  Stream<List<TaskModel>> streamTasks(String clinicId, {String? userId});

  /// Create a new task.
  Future<Either<Failure, TaskModel>> createTask(TaskModel task);

  /// Update an existing task.
  Future<Either<Failure, TaskModel>> updateTask(TaskModel task);

  /// Delete a task by ID.
  Future<Either<Failure, void>> deleteTask(String taskId);

  /// Helper to quickly mark a task as done.
  Future<Either<Failure, void>> markAsDone(String taskId);
}
