import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:dr_copilot/src/features/notifications/domain/repositories/abstract_notifications_repository.dart';

class GetTargetUsersUseCase {
  final AbstractNotificationsRepository repository;

  GetTargetUsersUseCase(this.repository);

  Future<Either<Failure, List<String>>> call(NotificationTarget target) async {
    return await repository.getTargetUserIds(target);
  }
}

