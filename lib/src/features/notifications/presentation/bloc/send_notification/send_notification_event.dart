part of 'send_notification_bloc.dart';

abstract class SendNotificationEventBase extends Equatable {
  const SendNotificationEventBase();

  @override
  List<Object?> get props => [];
}

class SendNotificationEvent extends SendNotificationEventBase {
  final NotificationTemplate template;

  const SendNotificationEvent(this.template);

  @override
  List<Object?> get props => [template];
}

