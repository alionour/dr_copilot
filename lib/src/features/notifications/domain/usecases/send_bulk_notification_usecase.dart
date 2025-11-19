import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';
import 'package:dr_copilot/src/features/notifications/domain/repositories/abstract_notifications_repository.dart';

class SendBulkNotificationUseCase {
  final AbstractNotificationsRepository repository;

  SendBulkNotificationUseCase(this.repository);

  Future<Either<Failure, int>> call(NotificationTemplate template) async {
    return await repository.sendBulkNotification(template);
  }
}
