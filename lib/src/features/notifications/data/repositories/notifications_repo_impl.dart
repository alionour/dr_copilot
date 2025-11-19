import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/notifications/data/remote/abstract_notification_api.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';
import 'package:dr_copilot/src/features/notifications/domain/repositories/abstract_notifications_repository.dart';

class NotificationsRepositoryImpl implements AbstractNotificationsRepository {
  final AbstractNotificationApi api;

  NotificationsRepositoryImpl({required this.api});

  @override
  Future<Either<Failure, List<NotificationModel>>> getNotifications(String userId) async {
    try {
      final notifications = await api.getNotifications(userId);
      return Right(notifications);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await api.getUnreadCount(userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String notificationId) async {
    try {
      await api.markAsRead(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> markAllAsRead(String userId) async {
    try {
      await api.markAllAsRead(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(String notificationId) async {
    try {
      await api.deleteNotification(notificationId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllNotifications(String userId) async {
    try {
      await api.deleteAllNotifications(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, NotificationModel>> createNotification(NotificationModel notification) async {
    try {
      final created = await api.createNotification(notification);
      return Right(created);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Stream<Either<Failure, List<NotificationModel>>> watchNotifications(String userId) {
    try {
      return api.watchNotifications(userId).map((notifications) => Right(notifications));
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString(), 500)));
    }
  }

  @override
  Stream<Either<Failure, int>> watchUnreadCount(String userId) {
    try {
      return api.watchUnreadCount(userId).map((count) => Right(count));
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString(), 500)));
    }
  }

  @override
  Future<Either<Failure, int>> sendBulkNotification(NotificationTemplate template) async {
    try {
      final count = await api.sendBulkNotification(template);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getTargetUserIds(NotificationTarget target) async {
    try {
      final userIds = await api.getTargetUserIds(target);
      return Right(userIds);
    } catch (e) {
      return Left(ServerFailure(e.toString(), 500));
    }
  }
}
