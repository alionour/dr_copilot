import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/notifications/domain/usecases/notifications_usecase.dart';
import 'package:dr_copilot/src/features/notifications/domain/usecases/send_bulk_notification_usecase.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:flutter/foundation.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsUseCase useCase;
  final SendBulkNotificationUseCase? sendBulkUseCase;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountSubscription;

  NotificationsBloc({required this.useCase, this.sendBulkUseCase})
    : super(NotificationsInitial()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<WatchNotificationsEvent>(_onWatchNotifications);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<DeleteNotificationEvent>(_onDeleteNotification);
    on<DeleteAllNotificationsEvent>(_onDeleteAllNotifications);
    on<RefreshNotificationsEvent>(_onRefreshNotifications);
    on<SendBulkNotificationEvent>(_onSendBulkNotification);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    final notificationsResult = await useCase.getNotifications(event.userId);
    final unreadCountResult = await useCase.getUnreadCount(event.userId);

    notificationsResult.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (notifications) {
        unreadCountResult.fold(
          (failure) => emit(NotificationsError(failure.message)),
          (unreadCount) => emit(
            NotificationsLoaded(
              notifications: notifications,
              unreadCount: unreadCount,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onWatchNotifications(
    WatchNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    emit(NotificationsLoading());

    await _notificationsSubscription?.cancel();
    await _unreadCountSubscription?.cancel();

    await emit.forEach(
      useCase.watchNotifications(event.userId),
      onData: (notificationsResult) {
        return notificationsResult.fold(
          (failure) => NotificationsError(failure.message),
          (notifications) {
            final unreadCount = notifications.where((n) => !n.isRead).length;

            return NotificationsLoaded(
              notifications: notifications,
              unreadCount: unreadCount,
            );
          },
        );
      },
      onError: (error, stackTrace) {
        debugPrint('Error watching notifications: $error');
        return NotificationsError(error.toString());
      },
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;

    final result = await useCase.markAsRead(event.notificationId);

    result.fold(
      (failure) {
        if (!emit.isDone) {
          emit(NotificationsError(failure.message));
        }
      },
      (_) {
        // State will be updated by the stream
        debugPrint('Notification marked as read');
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;

    final result = await useCase.markAllAsRead(event.userId);

    result.fold(
      (failure) {
        if (!emit.isDone) {
          emit(NotificationsError(failure.message));
        }
      },
      (_) {
        // State will be updated by the stream
        debugPrint('All notifications marked as read');
      },
    );
  }

  Future<void> _onDeleteNotification(
    DeleteNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (state is! NotificationsLoaded) return;

    final result = await useCase.deleteNotification(event.notificationId);

    result.fold(
      (failure) {
        if (!emit.isDone) {
          emit(NotificationsError(failure.message));
        }
      },
      (_) {
        // State will be updated by the stream
        debugPrint('Notification deleted');
      },
    );
  }

  Future<void> _onDeleteAllNotifications(
    DeleteAllNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    final result = await useCase.deleteAllNotifications(event.userId);

    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (_) => emit(const NotificationsLoaded(notifications: [], unreadCount: 0)),
    );
  }

  Future<void> _onRefreshNotifications(
    RefreshNotificationsEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    add(LoadNotificationsEvent(event.userId));
  }

  Future<void> _onSendBulkNotification(
    SendBulkNotificationEvent event,
    Emitter<NotificationsState> emit,
  ) async {
    if (sendBulkUseCase == null) {
      emit(const NotificationsError('Bulk notification feature not available'));
      return;
    }

    // Don't emit NotificationsLoading here - it interferes with the main list's state
    // The CreateNotificationPage manages its own loading state

    final result = await sendBulkUseCase!.call(event.template);

    result.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (count) => emit(NotificationSentSuccess(count)),
    );
  }

  @override
  Future<void> close() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
    return super.close();
  }
}

