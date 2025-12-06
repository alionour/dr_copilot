import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationListItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkAsRead,
  });

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return Icons.event_outlined;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.reminder:
        return Icons.alarm_outlined;
      case NotificationType.system:
        return Icons.info_outline;
      case NotificationType.payment:
        return Icons.payment_outlined;
      case NotificationType.report:
        return Icons.description_outlined;
      case NotificationType.alert:
        return Icons.warning_amber_outlined;
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.appointment:
        return Colors.blue;
      case NotificationType.message:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.payment:
        return Colors.purple;
      case NotificationType.report:
        return Colors.teal;
      case NotificationType.alert:
        return Colors.red;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'justNow'.tr();
    } else if (difference.inMinutes < 60) {
      return 'minutesAgo'.tr(args: [difference.inMinutes.toString()]);
    } else if (difference.inHours < 24) {
      return 'hoursAgo'.tr(args: [difference.inHours.toString()]);
    } else if (difference.inDays < 7) {
      return 'daysAgo'.tr(args: [difference.inDays.toString()]);
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Theme.of(context).cardColor
            : Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [
          if (!notification.isRead)
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
          } else if (notification.actionUrl != null) {
            context.go(notification.actionUrl!);
          }
          if (!notification.isRead && onMarkAsRead != null) {
            onMarkAsRead!();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getColorForType(
                  notification.type,
                ).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIconForType(notification.type),
                color: _getColorForType(notification.type),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.color,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const Spacer(),
                      if (!notification.isRead && onMarkAsRead != null)
                        InkWell(
                          onTap: onMarkAsRead,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'markAsRead'.tr(),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
