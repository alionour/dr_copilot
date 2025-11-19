import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationsEvent {
  final String userId;

  const LoadNotificationsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class WatchNotificationsEvent extends NotificationsEvent {
  final String userId;

  const WatchNotificationsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MarkNotificationAsReadEvent extends NotificationsEvent {
  final String notificationId;

  const MarkNotificationAsReadEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllAsReadEvent extends NotificationsEvent {
  final String userId;

  const MarkAllAsReadEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DeleteNotificationEvent extends NotificationsEvent {
  final String notificationId;

  const DeleteNotificationEvent(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

class DeleteAllNotificationsEvent extends NotificationsEvent {
  final String userId;

  const DeleteAllNotificationsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class RefreshNotificationsEvent extends NotificationsEvent {
  final String userId;

  const RefreshNotificationsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SendBulkNotificationEvent extends NotificationsEvent {
  final NotificationTemplate template;

  const SendBulkNotificationEvent(this.template);

  @override
  List<Object?> get props => [template];
}
