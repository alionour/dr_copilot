import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../models/task_model.dart';
import '../repositories/abstract_task_repository.dart';

class TaskUseCase {
  final AbstractTaskRepository _repository;

  TaskUseCase(this._repository);

  Stream<List<TaskModel>> streamTasks(String clinicId, {String? userId}) {
    // Business logic: e.g. enforce clinicId is not empty
    if (clinicId.isEmpty) {
      return Stream.error(ValidationFailure('Clinic ID cannot be empty'));
    }
    return _repository.streamTasks(clinicId, userId: userId);
  }

  Future<Either<Failure, TaskModel>> createTask(TaskModel task) async {
    // Validate required fields
    if (task.title.trim().isEmpty) {
      return Left(ValidationFailure('Title cannot be empty'));
    }
    return _repository.createTask(task);
  }

  Future<Either<Failure, TaskModel>> updateTask(TaskModel task) async {
    if (task.title.trim().isEmpty) {
      return Left(ValidationFailure('Title cannot be empty'));
    }
    return _repository.updateTask(task);
  }

  Future<Either<Failure, void>> deleteTask(String taskId) async {
    return _repository.deleteTask(taskId);
  }

  Future<Either<Failure, void>> markAsDone(String taskId) async {
    return _repository.markAsDone(taskId);
  }
}
