import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';

abstract class AbstractNotificationApi {
  /// Get all notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId);

  /// Get unread notifications count
  Future<int> getUnreadCount(String userId);

  /// Mark notification as read
  Future<void> markAsRead(String notificationId);

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId);

  /// Delete a notification
  Future<void> deleteNotification(String notificationId);

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId);

  /// Create a new notification
  Future<NotificationModel> createNotification(NotificationModel notification);

  /// Stream of notifications
  Stream<List<NotificationModel>> watchNotifications(String userId);

  /// Stream of unread count
  Stream<int> watchUnreadCount(String userId);
  
  /// Send notification to multiple users based on template
  Future<int> sendBulkNotification(NotificationTemplate template);
  
  /// Get target user IDs based on notification target
  Future<List<String>> getTargetUserIds(NotificationTarget target);
}

