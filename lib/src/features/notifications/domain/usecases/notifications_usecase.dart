import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/repositories/abstract_notifications_repository.dart';

class NotificationsUseCase {
  final AbstractNotificationsRepository repository;

  NotificationsUseCase({required this.repository});

  Future<Either<Failure, List<NotificationModel>>> getNotifications(String userId) {
    return repository.getNotifications(userId);
  }

  Future<Either<Failure, int>> getUnreadCount(String userId) {
    return repository.getUnreadCount(userId);
  }

  Future<Either<Failure, void>> markAsRead(String notificationId) {
    return repository.markAsRead(notificationId);
  }

  Future<Either<Failure, void>> markAllAsRead(String userId) {
    return repository.markAllAsRead(userId);
  }

  Future<Either<Failure, void>> deleteNotification(String notificationId) {
    return repository.deleteNotification(notificationId);
  }

  Future<Either<Failure, void>> deleteAllNotifications(String userId) {
    return repository.deleteAllNotifications(userId);
  }

  Future<Either<Failure, NotificationModel>> createNotification(NotificationModel notification) {
    return repository.createNotification(notification);
  }

  Stream<Either<Failure, List<NotificationModel>>> watchNotifications(String userId) {
    return repository.watchNotifications(userId);
  }

  Stream<Either<Failure, int>> watchUnreadCount(String userId) {
    return repository.watchUnreadCount(userId);
  }
}
