// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationTemplate _$NotificationTemplateFromJson(
        Map<String, dynamic> json) =>
    NotificationTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
      sender:
          NotificationSender.fromJson(json['sender'] as Map<String, dynamic>),
      target:
          NotificationTarget.fromJson(json['target'] as Map<String, dynamic>),
      actionUrl: json['actionUrl'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$NotificationTemplateToJson(
        NotificationTemplate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'message': instance.message,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'sender': instance.sender,
      'target': instance.target,
      'actionUrl': instance.actionUrl,
      'metadata': instance.metadata,
    };

const _$NotificationTypeEnumMap = {
  NotificationType.appointment: 'appointment',
  NotificationType.message: 'message',
  NotificationType.reminder: 'reminder',
  NotificationType.system: 'system',
  NotificationType.payment: 'payment',
  NotificationType.report: 'report',
  NotificationType.alert: 'alert',
};
