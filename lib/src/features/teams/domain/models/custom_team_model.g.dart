// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_team_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomTeamModel _$CustomTeamModelFromJson(Map<String, dynamic> json) =>
    CustomTeamModel(
      id: json['id'] as String,
      clinicId: json['clinicId'] as String,
      ownerId: json['ownerId'] as String,
      name: json['name'] as String,
      memberIds:
          (json['memberIds'] as List<dynamic>).map((e) => e as String).toList(),
      isArchived: json['isArchived'] as bool? ?? false,
      createdAt: CustomTeamModel._timestampFromJson(json['createdAt']),
    );

Map<String, dynamic> _$CustomTeamModelToJson(CustomTeamModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clinicId': instance.clinicId,
      'ownerId': instance.ownerId,
      'name': instance.name,
      'memberIds': instance.memberIds,
      'isArchived': instance.isArchived,
      'createdAt': CustomTeamModel._timestampToJson(instance.createdAt),
    };
