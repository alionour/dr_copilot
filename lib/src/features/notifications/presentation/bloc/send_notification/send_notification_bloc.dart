import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_template.dart';
import 'package:dr_copilot/src/features/notifications/domain/usecases/send_bulk_notification_usecase.dart';
import 'package:equatable/equatable.dart';

part 'send_notification_event.dart';
part 'send_notification_state.dart';

class SendNotificationBloc extends Bloc<SendNotificationEvent, SendNotificationState> {
  final SendBulkNotificationUseCase sendBulkNotificationUseCase;

  SendNotificationBloc({
    required this.sendBulkNotificationUseCase,
  }) : super(SendNotificationInitial()) {
    on<SendNotificationEvent>(_onSendNotification);
  }

  Future<void> _onSendNotification(
    SendNotificationEvent event,
    Emitter<SendNotificationState> emit,
  ) async {
    emit(SendNotificationLoading());

    final result = await sendBulkNotificationUseCase(event.template);

    result.fold(
      (failure) => emit(SendNotificationFailure(failure.message)),
      (count) => emit(SendNotificationSuccess(count)),
    );
  }
}
