import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/models/task_model.dart';
import '../../domain/repositories/abstract_task_repository.dart';
import '../remote/task_firebase_api.dart';
import '../../../notifications/domain/repositories/abstract_notifications_repository.dart';
import '../../../notifications/domain/models/notification_model.dart';

class TaskRepositoryImpl implements AbstractTaskRepository {
  final TaskFirebaseApi _api;
  final AbstractNotificationsRepository _notificationsRepository;

  TaskRepositoryImpl(this._api, this._notificationsRepository);

  @override
  Stream<List<TaskModel>> streamTasks(String clinicId, {String? userId}) {
    return _api.streamTasks(clinicId, userId: userId);
  }

  @override
  Future<Either<Failure, TaskModel>> createTask(TaskModel task) async {
    try {
      await _api.createTask(task);

      // Send notification if assigned to someone else
      if (task.assignedToUserId != null &&
          task.assignedToUserId != task.assignedByUserId) {
        final notification = NotificationModel(
          id: '',
          userId: task.assignedToUserId!,
          title: 'New Task Assigned',
          message: 'You have been assigned a new task: ${task.title}',
          type: NotificationType.task,
          isRead: false,
          createdAt: DateTime.now(),
          sender: NotificationSender(
            type: NotificationSenderType
                .clinicOwner, // Assuming assigned by owner/admin for now, or just 'system'
            senderId: task.assignedByUserId,
            senderName:
                'Manager', // TODO: Get actual name if possible, or keep generic
          ),
          target: NotificationTarget(
            type: NotificationTargetType
                .specificRoles, // Not used for single user target really
            // We are manually targeting userId above, so target field is metadata mostly here for single user
          ),
          actionUrl: '/tasks',
        );
        await _notificationsRepository.createNotification(notification);
      }

      return Right(task);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, TaskModel>> updateTask(TaskModel task) async {
    try {
      await _api.updateTask(task);
      // Logic for update notifications (e.g. status change) could go here
      return Right(task);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTask(String taskId) async {
    try {
      await _api.deleteTask(taskId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> markAsDone(String taskId) async {
    try {
      await _api.markAsDone(taskId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
