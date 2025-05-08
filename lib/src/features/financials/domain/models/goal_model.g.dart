// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountGoalModel _$CountGoalModelFromJson(Map<String, dynamic> json) =>
    CountGoalModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      goalType: const GoalTypeConverter().fromJson(json['goalType'] as String),
      targetCount: (json['targetCount'] as num).toInt(),
      color: (json['color'] as num).toInt(),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      year: (json['year'] as num?)?.toInt(),
      month: (json['month'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CountGoalModelToJson(CountGoalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'goalType': const GoalTypeConverter().toJson(instance.goalType),
      'color': instance.color,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'year': instance.year,
      'month': instance.month,
      'targetCount': instance.targetCount,
    };

AmountGoalModel _$AmountGoalModelFromJson(Map<String, dynamic> json) =>
    AmountGoalModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      goalType: const GoalTypeConverter().fromJson(json['goalType'] as String),
      targetAmount: (json['targetAmount'] as num).toDouble(),
      color: (json['color'] as num).toInt(),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      year: (json['year'] as num?)?.toInt(),
      month: (json['month'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AmountGoalModelToJson(AmountGoalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'goalType': const GoalTypeConverter().toJson(instance.goalType),
      'color': instance.color,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'year': instance.year,
      'month': instance.month,
      'targetAmount': instance.targetAmount,
    };

CustomGoalModel _$CustomGoalModelFromJson(Map<String, dynamic> json) =>
    CustomGoalModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      goalType: const GoalTypeConverter().fromJson(json['goalType'] as String),
      metricName: json['metricName'] as String,
      targetValue: (json['targetValue'] as num).toDouble(),
      color: (json['color'] as num).toInt(),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      year: (json['year'] as num?)?.toInt(),
      month: (json['month'] as num?)?.toInt(),
      isMonthBased: json['isMonthBased'] as bool? ?? false,
      isYearBased: json['isYearBased'] as bool? ?? false,
    );

Map<String, dynamic> _$CustomGoalModelToJson(CustomGoalModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'goalType': const GoalTypeConverter().toJson(instance.goalType),
      'color': instance.color,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'year': instance.year,
      'month': instance.month,
      'metricName': instance.metricName,
      'targetValue': instance.targetValue,
      'isMonthBased': instance.isMonthBased,
      'isYearBased': instance.isYearBased,
    };
