import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';

abstract class AbstractNotificationsRepository {
  /// Get all notifications for a user
  Future<Either<Failure, List<NotificationModel>>> getNotifications(String userId);

  /// Get unread notifications count
  Future<Either<Failure, int>> getUnreadCount(String userId);

  /// Mark notification as read
  Future<Either<Failure, void>> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<Either<Failure, void>> markAllAsRead(String userId);

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification(String notificationId);

  /// Delete all notifications for a user
  Future<Either<Failure, void>> deleteAllNotifications(String userId);

  /// Create a new notification
  Future<Either<Failure, NotificationModel>> createNotification(NotificationModel notification);

  /// Stream of notifications
  Stream<Either<Failure, List<NotificationModel>>> watchNotifications(String userId);

  /// Stream of unread count
  Stream<Either<Failure, int>> watchUnreadCount(String userId);
  
  /// Send notification to multiple users based on template
  Future<Either<Failure, int>> sendBulkNotification(NotificationTemplate template);
  
  /// Get target user IDs based on notification target
  Future<Either<Failure, List<String>>> getTargetUserIds(NotificationTarget target);
}

