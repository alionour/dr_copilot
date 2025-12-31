import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/appointments/evaluations/domain/models/evaluation_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'goal_model.g.dart';

// --- GoalTypeConverter for json_serializable ---
class GoalTypeConverter implements JsonConverter<GoalType, String> {
  const GoalTypeConverter();

  @override
  GoalType fromJson(String json) => goalTypeFromString(json);

  @override
  String toJson(GoalType object) => goalTypeToString(object);
}

/// Enum representing the type of financial goal.
enum GoalType {
  /// Goal based on yearly session count.
  sessionsYear,

  /// Goal based on monthly session count.
  sessionsMonth,

  /// Goal based on yearly evaluation count.
  evaluationsYear,

  /// Goal based on monthly evaluation count.
  evaluationsMonth,

  /// Goal to decrease overall expenses.
  decreaseExpenses,

  /// Goal to increase total revenue.
  increaseTotalRevenue,

  /// Goal to increase total profit.
  increaseTotalProfit,

  /// Goal to increase revenue specifically from sessions.
  increaseSessionsRevenue,

  /// Goal to increase revenue specifically from evaluations.
  increaseEvaluationsRevenue,

  /// Custom user-defined goal.
  custom;

  /// Returns true if the goal is based on counts (sessions/evaluations).
  bool get isCountBased =>
      this == GoalType.sessionsYear ||
      this == GoalType.sessionsMonth ||
      this == GoalType.evaluationsYear ||
      this == GoalType.evaluationsMonth;

  /// Returns true if the goal is based on monetary amounts.
  bool get isAmountBased =>
      this == GoalType.decreaseExpenses ||
      this == GoalType.increaseTotalRevenue ||
      this == GoalType.increaseTotalProfit ||
      this == GoalType.increaseSessionsRevenue ||
      this == GoalType.increaseEvaluationsRevenue;

  /// Returns true if it is a custom goal.
  bool get isCustom => this == GoalType.custom;
}

String goalTypeToString(GoalType type) {
  switch (type) {
    case GoalType.sessionsYear:
      return 'sessions_year';
    case GoalType.sessionsMonth:
      return 'sessions_month';
    case GoalType.evaluationsYear:
      return 'evaluations_year';
    case GoalType.evaluationsMonth:
      return 'evaluations_month';
    case GoalType.decreaseExpenses:
      return 'decrease_expenses';
    case GoalType.increaseTotalRevenue:
      return 'increase_total_revenue';
    case GoalType.increaseTotalProfit:
      return 'increase_total_profit';
    case GoalType.increaseSessionsRevenue:
      return 'increase_sessions_revenue';
    case GoalType.increaseEvaluationsRevenue:
      return 'increase_evaluations_revenue';
    case GoalType.custom:
      return 'custom';
  }
}

GoalType goalTypeFromString(String value) {
  switch (value) {
    case 'sessions_year':
      return GoalType.sessionsYear;
    case 'sessions_month':
      return GoalType.sessionsMonth;
    case 'evaluations_year':
      return GoalType.evaluationsYear;
    case 'evaluations_month':
      return GoalType.evaluationsMonth;
    case 'decrease_expenses':
      return GoalType.decreaseExpenses;
    case 'increase_total_revenue':
      return GoalType.increaseTotalRevenue;
    case 'increase_total_profit':
      return GoalType.increaseTotalProfit;
    case 'increase_sessions_revenue':
      return GoalType.increaseSessionsRevenue;
    case 'increase_evaluations_revenue':
      return GoalType.increaseEvaluationsRevenue;
    case 'custom':
      return GoalType.custom;
    default:
      return GoalType.custom;
  }
}

/// Abstract base class for all goal models.
abstract class GoalModelBase {
  /// The unique identifier of the goal.
  final String id;

  /// The title of the goal.
  final String title;

  /// An optional description of the goal.
  final String? description;

  /// The type of the goal.
  @GoalTypeConverter()
  final GoalType goalType;

  /// The color associated with the goal (integer representation).
  final int color;

  /// The timestamp when the goal was created.
  @TimestampConverter()
  final Timestamp createdAt;

  /// The timestamp when the goal was last updated.
  @NullableTimestampConverter()
  final Timestamp? updatedAt;

  /// The timestamp when the goal was deleted.
  @NullableTimestampConverter()
  final Timestamp? deletedAt;

  /// The ID of the user who created the goal.
  final String createdBy;

  /// The ID of the user who last updated the goal.
  final String? updatedBy;

  /// The ID of the user who deleted the goal.
  final String? deletedBy;

  /// The target year for the goal (if applicable).
  final int? year;

  /// The target month for the goal (if applicable).
  final int? month;

  const GoalModelBase({
    required this.id,
    required this.title,
    this.description,
    required this.goalType,
    required this.color,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.createdBy,
    this.updatedBy,
    this.deletedBy,
    this.year,
    this.month,
  });
}

/// A goal model specifically for count-based targets (e.g., number of sessions).
@JsonSerializable(explicitToJson: true)
class CountGoalModel extends GoalModelBase {
  /// The target count value.
  final int targetCount;

  const CountGoalModel({
    required super.id,
    required super.title,
    super.description,
    required super.goalType,
    required this.targetCount,
    required super.color,
    required super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.year,
    super.month,
    required super.createdBy,
    super.updatedBy,
    super.deletedBy,
  });

  factory CountGoalModel.fromJson(Map<String, dynamic> json) =>
      _$CountGoalModelFromJson(json);
  Map<String, dynamic> toJson() => _$CountGoalModelToJson(this);

  CountGoalModel copyWith({
    String? id,
    String? title,
    String? description,
    GoalType? goalType,
    int? targetCount,
    int? color,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    int? year,
    int? month,
  }) {
    return CountGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      targetCount: targetCount ?? this.targetCount,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

/// A goal model specifically for monetary amount-based targets (e.g., revenue target).
@JsonSerializable(explicitToJson: true)
class AmountGoalModel extends GoalModelBase {
  /// The target monetary amount.
  final double targetAmount;

  const AmountGoalModel({
    required super.id,
    required super.title,
    super.description,
    required super.goalType,
    required this.targetAmount,
    required super.color,
    required super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.year,
    super.month,
    required super.createdBy,
    super.updatedBy,
    super.deletedBy,
  });

  factory AmountGoalModel.fromJson(Map<String, dynamic> json) =>
      _$AmountGoalModelFromJson(json);
  Map<String, dynamic> toJson() => _$AmountGoalModelToJson(this);

  AmountGoalModel copyWith({
    String? id,
    String? title,
    String? description,
    GoalType? goalType,
    double? targetAmount,
    int? color,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? deletedBy,
    String? createdBy,
    String? updatedBy,
    int? year,
    int? month,
  }) {
    return AmountGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      targetAmount: targetAmount ?? this.targetAmount,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
}

/// A model for custom goals, allowing the user to define their own metric and target value.
@JsonSerializable(explicitToJson: true)
class CustomGoalModel extends GoalModelBase {
  /// The name of the custom metric (e.g., "Patients Helped", "Books Read").
  final String metricName;

  /// The numeric target for the custom metric.
  final double targetValue;

  /// Indicates if this custom goal is month-based, year-based, or neither.
  final bool isMonthBased;
  final bool isYearBased;

  const CustomGoalModel({
    required super.id,
    required super.title,
    super.description,
    required super.goalType,
    required this.metricName,
    required this.targetValue,
    required super.color,
    required super.createdAt,
    super.updatedAt,
    super.deletedAt,
    super.year,
    super.month,
    this.isMonthBased = false,
    this.isYearBased = false,
    required super.createdBy,
    super.updatedBy,
    super.deletedBy,
  });

  factory CustomGoalModel.fromJson(Map<String, dynamic> json) =>
      _$CustomGoalModelFromJson(json);
  Map<String, dynamic> toJson() => _$CustomGoalModelToJson(this);

  CustomGoalModel copyWith({
    String? id,
    String? title,
    String? description,
    GoalType? goalType,
    String? metricName,
    double? targetValue,
    int? color,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    Timestamp? deletedAt,
    String? createdBy,
    String? updatedBy,
    String? deletedBy,
    int? year,
    int? month,
    bool? isMonthBased,
    bool? isYearBased,
  }) {
    return CustomGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      goalType: goalType ?? this.goalType,
      metricName: metricName ?? this.metricName,
      targetValue: targetValue ?? this.targetValue,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedBy: deletedBy ?? this.deletedBy,
      year: year ?? this.year,
      month: month ?? this.month,
      isMonthBased: isMonthBased ?? this.isMonthBased,
      isYearBased: isYearBased ?? this.isYearBased,
    );
  }
}
