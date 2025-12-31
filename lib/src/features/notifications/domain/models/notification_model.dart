import 'package:json_annotation/json_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/auth/domain/models/role_enum.dart';

part 'notification_model.g.dart';

/// A model class representing a notification.
@JsonSerializable()
class NotificationModel {
  /// The unique identifier of the notification.
  final String id;

  /// The ID of the user who should receive this notification.
  final String userId;

  /// The title of the notification.
  final String title;

  /// The message body of the notification.
  final String message;

  /// The type/category of the notification.
  final NotificationType type;

  /// Whether the notification has been read by the user.
  final bool isRead;

  /// The timestamp when the notification was created.
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;

  /// An optional URL for navigation when the notification is tapped.
  final String? actionUrl;

  /// Additional metadata associated with the notification.
  final Map<String, dynamic>? metadata;

  /// Information about who sent the notification.
  final NotificationSender sender;

  /// Information about who should receive the notification.
  final NotificationTarget target;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.actionUrl,
    this.metadata,
    required this.sender,
    required this.target,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
    String? actionUrl,
    Map<String, dynamic>? metadata,
    NotificationSender? sender,
    NotificationTarget? target,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      actionUrl: actionUrl ?? this.actionUrl,
      metadata: metadata ?? this.metadata,
      sender: sender ?? this.sender,
      target: target ?? this.target,
    );
  }

  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}

/// Enum representing the type of notification.
enum NotificationType {
  @JsonValue('appointment')
  appointment,
  @JsonValue('message')
  message,
  @JsonValue('reminder')
  reminder,
  @JsonValue('system')
  system,
  @JsonValue('payment')
  payment,
  @JsonValue('report')
  report,
  @JsonValue('alert')
  alert,
}

enum NotificationSenderType {
  @JsonValue('programmer')
  programmer,
  @JsonValue('app_system')
  appSystem,
  @JsonValue('clinic_owner')
  clinicOwner,
}

@JsonSerializable()
class NotificationSender {
  final NotificationSenderType type;
  final String? senderId;
  final String? senderName;

  NotificationSender({required this.type, this.senderId, this.senderName});

  factory NotificationSender.fromJson(Map<String, dynamic> json) =>
      _$NotificationSenderFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationSenderToJson(this);
}

enum NotificationTargetType {
  @JsonValue('all_users')
  allUsers,
  @JsonValue('all_clinic_owners')
  allClinicOwners,
  @JsonValue('all_doctors')
  allDoctors,
  @JsonValue('all_staff')
  allStaff,
  @JsonValue('specific_roles')
  specificRoles,
  @JsonValue('owner_clinics')
  ownerClinics,
  @JsonValue('specific_clinic')
  specificClinic,
  @JsonValue('custom_team')
  customTeam,
}

@JsonSerializable()
class NotificationTarget {
  final NotificationTargetType type;

  @RoleListJsonConverter()
  final List<AppRole>? targetRoles;

  final String? ownerId;

  final List<String>? clinicIds;

  final String? teamId;

  NotificationTarget({
    required this.type,
    this.targetRoles,
    this.ownerId,
    this.clinicIds,
    this.teamId,
  });

  factory NotificationTarget.fromJson(Map<String, dynamic> json) =>
      _$NotificationTargetFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTargetToJson(this);
}
