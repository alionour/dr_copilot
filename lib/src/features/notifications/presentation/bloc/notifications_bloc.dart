import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/notifications/domain/usecases/notifications_usecase.dart';
import 'package:dr_copilot/src/features/notifications/domain/usecases/send_bulk_notification_usecase.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_event.dart';
import 'package:dr_copilot/src/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:flutter/foundation.dart';
import 'package:dr_copilot/src/features/inventory/domain/usecases/inventory_usecase.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:uuid/uuid.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsUseCase useCase;
  final SendBulkNotificationUseCase? sendBulkUseCase;
  final InventoryUseCase? inventoryUseCase;
  StreamSubscription? _notificationsSubscription;
  StreamSubscription? _unreadCountSubscription;

  NotificationsBloc({
    required this.useCase,
    this.sendBulkUseCase,
    this.inventoryUseCase,
  }) : super(NotificationsInitial()) {
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

    // Fetch low stock items if inventory use case is available
    List<NotificationModel> lowStockNotifications = [];
    if (inventoryUseCase != null) {
      final lowStockResult = await inventoryUseCase!.getLowStockItems();
      lowStockResult.fold(
        (failure) =>
            debugPrint('Failed to load low stock items: ${failure.message}'),
        (items) {
          if (items.isNotEmpty) {
            final itemNames = items.map((e) => e.name).join(', ');
            final notification = NotificationModel(
              id: const Uuid().v4(),
              userId: event.userId,
              title: 'lowStockAlert'.tr(),
              message: 'lowStockMessage'.tr(args: [itemNames]),
              type: NotificationType.alert,
              isRead: false,
              createdAt: DateTime.now(),
              sender: NotificationSender(
                type: NotificationSenderType.appSystem,
                senderName: 'System',
              ),
              target: NotificationTarget(
                type: NotificationTargetType.specificRoles,
              ),
            );
            lowStockNotifications.add(notification);
          }
        },
      );
    }

    notificationsResult.fold(
      (failure) => emit(NotificationsError(failure.message)),
      (notifications) {
        unreadCountResult.fold(
          (failure) => emit(NotificationsError(failure.message)),
          (unreadCount) {
            // Combine real notifications with local low stock notifications
            final allNotifications = [
              ...lowStockNotifications,
              ...notifications
            ];
            // Sort by date desc
            allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            emit(
              NotificationsLoaded(
                notifications: allNotifications,
                unreadCount: unreadCount + lowStockNotifications.length,
              ),
            );
          },
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
            // Note: In watch mode, we might miss real-time updates for low stock
            // unless we also watch inventory. For now, we rely on initial load
            // or manual refresh to show low stock alerts, which is acceptable
            // to avoid complex stream merging logic for this phase.

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

    // For local notifications (like low stock), we just update state locally
    // since they don't exist in backend to mark as read.
    // However, since we regenerate them on load, they might reappear.
    // For a robust system, we would save "seen" state locally or upload them to backend.
    // For this MVP, we will try to mark backend notification, and if it fails (not found), ignore.

    final result = await useCase.markAsRead(event.notificationId);

    result.fold(
      (failure) {
        // If it's a local notification, it won't be found in DB.
        // We can optionally handle local state update here if needed.
        if (!emit.isDone) {
          // emit(NotificationsError(failure.message)); // Don't error UI on local/missing notif
          debugPrint(
              'Failed to mark read (might be local): ${failure.message}');
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
          // emit(NotificationsError(failure.message));
          debugPrint('Failed to delete (might be local): ${failure.message}');
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
