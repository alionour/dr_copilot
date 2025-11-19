import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationListItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkAsRead;

  const NotificationListItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
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
      return '${difference.inMinutes}${'minutesAgo'.tr()}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${'hoursAgo'.tr()}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${'daysAgo'.tr()}';
    } else {
      return DateFormat.yMMMd().format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: notification.isRead ? 0 : 2,
      color: notification.isRead
          ? Theme.of(context).cardColor
          : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
      child: ListTile(
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
        leading: CircleAvatar(
          backgroundColor: _getColorForType(notification.type).withValues(alpha: 0.2),
          child: Icon(
            _getIconForType(notification.type),
            color: _getColorForType(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            if (!notification.isRead) const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, size: 20),
              onSelected: (value) {
                if (value == 'markAsRead' && onMarkAsRead != null) {
                  onMarkAsRead!();
                } else if (value == 'delete' && onDelete != null) {
                  onDelete!();
                }
              },
              itemBuilder: (context) => [
                if (!notification.isRead)
                  PopupMenuItem(
                    value: 'markAsRead',
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 20),
                        const SizedBox(width: 8),
                        Text('markAsRead'.tr()),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      Text('delete'.tr(), style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}
