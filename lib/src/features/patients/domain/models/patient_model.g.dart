// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatientModel _$PatientModelFromJson(Map<String, dynamic> json) => PatientModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      ownerId: json['ownerId'] as String,
      clinicId: json['clinicId'] as String,
      phone1: json['phone1'] as String?,
      phone2: json['phone2'] as String?,
      treatingDoctorId: json['treatingDoctorId'] as String?,
      departmentId: json['departmentId'] as String?,
      teamId: json['teamId'] as String?,
      occupation: json['occupation'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
      deletedBy: json['deletedBy'] as String?,
      deletedAt: const TimestampConverter().fromJson(json['deletedAt']),
    );

Map<String, dynamic> _$PatientModelToJson(PatientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'age': instance.age,
      'gender': instance.gender,
      'address': instance.address,
      'ownerId': instance.ownerId,
      'clinicId': instance.clinicId,
      'phone1': instance.phone1,
      'phone2': instance.phone2,
      'treatingDoctorId': instance.treatingDoctorId,
      'departmentId': instance.departmentId,
      'teamId': instance.teamId,
      'occupation': instance.occupation,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'createdBy': instance.createdBy,
      'updatedBy': instance.updatedBy,
      'deletedBy': instance.deletedBy,
      'deletedAt': const TimestampConverter().toJson(instance.deletedAt),
    };
