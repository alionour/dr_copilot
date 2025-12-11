// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationModel _$NotificationModelFromJson(
  Map<String, dynamic> json,
) => NotificationModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  title: json['title'] as String,
  message: json['message'] as String,
  type: $enumDecode(_$NotificationTypeEnumMap, json['type']),
  isRead: json['isRead'] as bool? ?? false,
  createdAt: NotificationModel._timestampFromJson(json['createdAt']),
  actionUrl: json['actionUrl'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  sender: NotificationSender.fromJson(json['sender'] as Map<String, dynamic>),
  target: NotificationTarget.fromJson(json['target'] as Map<String, dynamic>),
);

Map<String, dynamic> _$NotificationModelToJson(NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'message': instance.message,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'isRead': instance.isRead,
      'createdAt': NotificationModel._timestampToJson(instance.createdAt),
      'actionUrl': instance.actionUrl,
      'metadata': instance.metadata,
      'sender': instance.sender,
      'target': instance.target,
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

NotificationSender _$NotificationSenderFromJson(Map<String, dynamic> json) =>
    NotificationSender(
      type: $enumDecode(_$NotificationSenderTypeEnumMap, json['type']),
      senderId: json['senderId'] as String?,
      senderName: json['senderName'] as String?,
    );

Map<String, dynamic> _$NotificationSenderToJson(NotificationSender instance) =>
    <String, dynamic>{
      'type': _$NotificationSenderTypeEnumMap[instance.type]!,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
    };

const _$NotificationSenderTypeEnumMap = {
  NotificationSenderType.programmer: 'programmer',
  NotificationSenderType.appSystem: 'app_system',
  NotificationSenderType.clinicOwner: 'clinic_owner',
};

NotificationTarget _$NotificationTargetFromJson(Map<String, dynamic> json) =>
    NotificationTarget(
      type: $enumDecode(_$NotificationTargetTypeEnumMap, json['type']),
      targetRoles: _$JsonConverterFromJson<List<dynamic>, List<AppRole>>(
        json['targetRoles'],
        const RoleListJsonConverter().fromJson,
      ),
      ownerId: json['ownerId'] as String?,
      clinicIds: (json['clinicIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      teamId: json['teamId'] as String?,
    );

Map<String, dynamic> _$NotificationTargetToJson(NotificationTarget instance) =>
    <String, dynamic>{
      'type': _$NotificationTargetTypeEnumMap[instance.type]!,
      'targetRoles': _$JsonConverterToJson<List<dynamic>, List<AppRole>>(
        instance.targetRoles,
        const RoleListJsonConverter().toJson,
      ),
      'ownerId': instance.ownerId,
      'clinicIds': instance.clinicIds,
      'teamId': instance.teamId,
    };

const _$NotificationTargetTypeEnumMap = {
  NotificationTargetType.allUsers: 'all_users',
  NotificationTargetType.allClinicOwners: 'all_clinic_owners',
  NotificationTargetType.allDoctors: 'all_doctors',
  NotificationTargetType.allStaff: 'all_staff',
  NotificationTargetType.specificRoles: 'specific_roles',
  NotificationTargetType.ownerClinics: 'owner_clinics',
  NotificationTargetType.specificClinic: 'specific_clinic',
  NotificationTargetType.customTeam: 'custom_team',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
