import 'package:json_annotation/json_annotation.dart';
import 'package:dr_copilot/src/features/notifications/domain/models/notification_model.dart';

part 'notification_template.g.dart';

@JsonSerializable()
class NotificationTemplate {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationSender sender;
  final NotificationTarget target;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  NotificationTemplate({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.sender,
    required this.target,
    this.actionUrl,
    this.metadata,
  });

  factory NotificationTemplate.fromJson(Map<String, dynamic> json) =>
      _$NotificationTemplateFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTemplateToJson(this);
}
