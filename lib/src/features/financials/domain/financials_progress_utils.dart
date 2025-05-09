import 'package:dr_copilot/src/features/financials/domain/models/bill_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';

/// Utility class for calculating goal progress.
class FinancialsProgressCalculator {
  /// Calculates the progress for a given goal based on its type.
  /// Returns a value between 0.0 and 1.0.
  /// Uses real data from the state if possible.
  static double calculateGoalProgress({
    required GoalModelBase goal,
    required Map<String, int> sessionsCountPerMonth,
    required Map<String, int> evaluationsCountPerMonth,
    required List<BillModel> bills,
  }) {
    switch (goal.goalType) {
      case GoalType.sessionsYear:
        return _calculateSessionsYearProgress(
            goal as CountGoalModel, sessionsCountPerMonth);
      case GoalType.sessionsMonth:
        return _calculateSessionsMonthProgress(
            goal as CountGoalModel, sessionsCountPerMonth);
      case GoalType.decreaseExpenses:
        return _calculateDecreaseExpensesProgress(
            goal as AmountGoalModel, bills);
      case GoalType.increaseTotalRevenue:
        return _calculateIncreaseRevenueProgress(
            goal as AmountGoalModel, bills);
      case GoalType.increaseTotalProfit:
        return _calculateIncreaseProfitProgress(goal as AmountGoalModel, bills);
      case GoalType.increaseSessionsRevenue:
        return _calculateIncreaseSessionsRevenueProgress(
            goal as AmountGoalModel, bills);
      case GoalType.increaseEvaluationsRevenue:
        return _calculateIncreaseEvaluationsRevenueProgress(
            goal as AmountGoalModel, bills);
      case GoalType.evaluationsYear:
        return _calculateEvaluationsYearProgress(
            goal as CountGoalModel, evaluationsCountPerMonth);
      case GoalType.evaluationsMonth:
        return _calculateEvaluationsMonthProgress(
            goal as CountGoalModel, evaluationsCountPerMonth);
      case GoalType.custom:
        // For custom, you may want to implement a custom progress calculation
        // For now, always return 0.0
        return 0.0;
    }
  }

  static double _calculateSessionsYearProgress(
      CountGoalModel goal, Map<String, int> sessionsCountPerMonth) {
    final year = goal.year ?? DateTime.now().year;
    final key = year.toString().padLeft(4, '0');
    final sessions = sessionsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (sessions / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateSessionsMonthProgress(
      CountGoalModel goal, Map<String, int> sessionsCountPerMonth) {
    final year = goal.year ?? DateTime.now().year;
    final month = goal.month ?? DateTime.now().month;
    final key =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final sessions = sessionsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (sessions / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateEvaluationsYearProgress(
      CountGoalModel goal, Map<String, int> evaluationsCountPerMonth) {
    final year = goal.year ?? DateTime.now().year;
    final key = year.toString().padLeft(4, '0');
    final evals = evaluationsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (evals / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateEvaluationsMonthProgress(
      CountGoalModel goal, Map<String, int> evaluationsCountPerMonth) {
    final year = goal.year ?? DateTime.now().year;
    final month = goal.month ?? DateTime.now().month;
    final key =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final evals = evaluationsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (evals / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateDecreaseExpensesProgress(
      AmountGoalModel goal, List<BillModel> bills) {
    final year = goal.year ?? DateTime.now().year;
    final expenses = bills
        .where((b) =>
            b.dueDate.toDate().year == year &&
            b.amount > 0 &&
            b.status == BillStatus.paid &&
            b.title.toLowerCase().contains('expense'))
        .fold<double>(0.0, (sum, b) => sum + b.amount);
    return goal.targetAmount > 0
        ? (expenses / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateIncreaseRevenueProgress(
      AmountGoalModel goal, List<BillModel> bills) {
    final year = goal.year ?? DateTime.now().year;
    final revenue = bills
        .where((b) =>
            b.dueDate.toDate().year == year &&
            b.amount > 0 &&
            b.status == BillStatus.paid &&
            b.title.toLowerCase().contains('revenue'))
        .fold<double>(0.0, (sum, b) => sum + b.amount);
    return goal.targetAmount > 0
        ? (revenue / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateIncreaseProfitProgress(
      AmountGoalModel goal, List<BillModel> bills) {
    final year = goal.year ?? DateTime.now().year;
    final revenue = bills
        .where((b) =>
            b.dueDate.toDate().year == year &&
            b.amount > 0 &&
            b.status == BillStatus.paid &&
            b.title.toLowerCase().contains('revenue'))
        .fold<double>(0.0, (sum, b) => sum + b.amount);
    final expenses = bills
        .where((b) =>
            b.dueDate.toDate().year == year &&
            b.amount > 0 &&
            b.status == BillStatus.paid &&
            b.title.toLowerCase().contains('expense'))
        .fold<double>(0.0, (sum, b) => sum + b.amount);
    final profit = revenue - expenses;
    return goal.targetAmount > 0
        ? (profit / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateIncreaseSessionsRevenueProgress(
      AmountGoalModel goal, List<BillModel> bills) {
    final year = goal.year ?? DateTime.now().year;
    final sessionRevenue = bills
        .where((b) =>
            b.dueDate.toDate().year == year &&
            b.amount > 0 &&
            b.status == BillStatus.paid &&
            b.title.toLowerCase().contains('session'))
        .fold<double>(0.0, (sum, b) => sum + b.amount);
    return goal.targetAmount > 0
        ? (sessionRevenue / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
  }

  static double _calculateIncreaseEvaluationsRevenueProgress(
      AmountGoalModel goal, List<BillModel> bills) {
    final year = goal.year ?? DateTime.now().year;
    final evalRevenue = bills
        .where((b) =>
            b.dueDate.toDate().year == year &&
            b.amount > 0 &&
            b.status == BillStatus.paid &&
            b.title.toLowerCase().contains('evaluation'))
        .fold<double>(0.0, (sum, b) => sum + b.amount);
    return goal.targetAmount > 0
        ? (evalRevenue / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
  }
}
