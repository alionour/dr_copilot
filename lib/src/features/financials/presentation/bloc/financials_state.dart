part of 'financials_bloc.dart';

/// Base class for all financial states.
abstract class FinancialsState extends Equatable {
  /// A list containing all scheduled bill models associated with the current financial state.
  ///
  /// Each [ScheduledBillModel] in the list represents a bill that has been scheduled
  /// for payment or tracking within the application.
  final List<ScheduledBillModel> scheduledBills;

  /// A list of [GoalModelBase] objects representing the financial goals.
  ///
  /// This list contains all the goals associated with the current financial state.
  final List<GoalModelBase> goals;

  /// A list containing the currency profiles associated with the financials feature.
  ///
  /// Each item in the list is an instance of [CurrencyProfileModel], representing
  /// the details of a specific currency profile.
  final List<CurrencyProfileModel> currencyProfiles;

  /// A list containing all bill models associated with the current financial state.
  ///
  /// Each [BillModel] in the list represents an individual bill with its details.
  /// This list is typically used to display, manage, or process bills within the financials feature.
  final List<BillModel> bills;

  /// Map of session counts per month, keyed as 'YYYY-MM'.
  final Map<String, int> sessionsCountPerMonth;

  /// Map of evaluations counts per month, keyed as 'YYYY-MM'.
  final Map<String, int> evaluationsCountPerMonth;

  /// Map of revenue per month, keyed as 'YYYY-MM'.
  final Map<String, double> revenuePerMonth;

  /// Map of expenses per month, keyed as 'YYYY-MM'.
  final Map<String, double> expensesPerMonth;

  /// Map of revenue per year, keyed as 'YYYY'.
  final Map<String, double> revenuePerYear;

  /// Map of expenses per year, keyed as 'YYYY'.
  final Map<String, double> expensesPerYear;

  const FinancialsState({
    required this.scheduledBills,
    required this.goals,
    required this.currencyProfiles,
    required this.bills,
    required this.sessionsCountPerMonth,
    required this.evaluationsCountPerMonth,
    required this.revenuePerMonth,
    required this.expensesPerMonth,
    required this.revenuePerYear,
    required this.expensesPerYear,
  });

  @override
  List<Object?> get props => [
        scheduledBills,
        goals,
        currencyProfiles,
        bills,
        sessionsCountPerMonth,
        evaluationsCountPerMonth,
        revenuePerMonth,
        expensesPerMonth,
        revenuePerYear,
        expensesPerYear,
      ];

  FinancialsState copyWith({
    List<CurrencyProfileModel>? currencyProfiles,
    List<ScheduledBillModel>? scheduledBills,
    List<GoalModelBase>? goals,
    List<BillModel>? bills,
    Map<String, int>? sessionsCountPerMonth,
    Map<String, int>? evaluationsCountPerMonth,
    Map<String, double>? revenuePerMonth,
    Map<String, double>? expensesPerMonth,
    Map<String, double>? revenuePerYear,
    Map<String, double>? expensesPerYear,
  });
}

// --- copyWith for all concrete states ---
class FinancialsInitial extends FinancialsState {
  const FinancialsInitial({
    required super.scheduledBills,
    required super.goals,
    required super.currencyProfiles,
    required super.bills,
    required super.sessionsCountPerMonth,
    required super.evaluationsCountPerMonth,
    required super.revenuePerMonth,
    required super.expensesPerMonth,
    required super.revenuePerYear,
    required super.expensesPerYear,
  });

  @override
  FinancialsInitial copyWith({
    List<CurrencyProfileModel>? currencyProfiles,
    List<ScheduledBillModel>? scheduledBills,
    List<GoalModelBase>? goals,
    List<BillModel>? bills,
    Map<String, int>? sessionsCountPerMonth,
    Map<String, int>? evaluationsCountPerMonth,
    Map<String, double>? revenuePerMonth,
    Map<String, double>? expensesPerMonth,
    Map<String, double>? revenuePerYear,
    Map<String, double>? expensesPerYear,
  }) {
    return FinancialsInitial(
      currencyProfiles: currencyProfiles ?? this.currencyProfiles,
      scheduledBills: scheduledBills ?? this.scheduledBills,
      goals: goals ?? this.goals,
      bills: bills ?? this.bills,
      sessionsCountPerMonth:
          sessionsCountPerMonth ?? this.sessionsCountPerMonth,
      evaluationsCountPerMonth:
          evaluationsCountPerMonth ?? this.evaluationsCountPerMonth,
      revenuePerMonth: revenuePerMonth ?? this.revenuePerMonth,
      expensesPerMonth: expensesPerMonth ?? this.expensesPerMonth,
      revenuePerYear: revenuePerYear ?? this.revenuePerYear,
      expensesPerYear: expensesPerYear ?? this.expensesPerYear,
    );
  }
}

/// State when financial transactions are being loaded.
class FinancialsLoading extends FinancialsState {
  const FinancialsLoading({
    required super.scheduledBills,
    required super.goals,
    required super.currencyProfiles,
    required super.bills,
    required super.sessionsCountPerMonth,
    required super.evaluationsCountPerMonth,
    required super.revenuePerMonth,
    required super.expensesPerMonth,
    required super.revenuePerYear,
    required super.expensesPerYear,
  });

  @override
  FinancialsLoading copyWith({
    List<ScheduledBillModel>? scheduledBills,
    List<GoalModelBase>? goals,
    List<CurrencyProfileModel>? currencyProfiles,
    List<BillModel>? bills,
    Map<String, int>? sessionsCountPerMonth,
    Map<String, int>? evaluationsCountPerMonth,
    Map<String, double>? revenuePerMonth,
    Map<String, double>? expensesPerMonth,
    Map<String, double>? revenuePerYear,
    Map<String, double>? expensesPerYear,
  }) {
    return FinancialsLoading(
      scheduledBills: scheduledBills ?? this.scheduledBills,
      goals: goals ?? this.goals,
      currencyProfiles: currencyProfiles ?? this.currencyProfiles,
      bills: bills ?? this.bills,
      sessionsCountPerMonth:
          sessionsCountPerMonth ?? this.sessionsCountPerMonth,
      evaluationsCountPerMonth:
          evaluationsCountPerMonth ?? this.evaluationsCountPerMonth,
      revenuePerMonth: revenuePerMonth ?? this.revenuePerMonth,
      expensesPerMonth: expensesPerMonth ?? this.expensesPerMonth,
      revenuePerYear: revenuePerYear ?? this.revenuePerYear,
      expensesPerYear: expensesPerYear ?? this.expensesPerYear,
    );
  }
}

/// Represents the state when financial data has been successfully loaded.
///
/// This state contains the loaded financial information and is used to update
/// the UI accordingly.
class FinancialsLoaded extends FinancialsState {
  const FinancialsLoaded({
    required super.scheduledBills,
    required super.goals,
    required super.currencyProfiles,
    required super.bills,
    required super.sessionsCountPerMonth,
    required super.evaluationsCountPerMonth,
    required super.revenuePerMonth,
    required super.expensesPerMonth,
    required super.revenuePerYear,
    required super.expensesPerYear,
  });

  @override
  FinancialsLoaded copyWith({
    String? message,
    List<CurrencyProfileModel>? currencyProfiles,
    List<ScheduledBillModel>? scheduledBills,
    List<GoalModelBase>? goals,
    List<BillModel>? bills,
    Map<String, int>? sessionsCountPerMonth,
    Map<String, int>? evaluationsCountPerMonth,
    Map<String, double>? revenuePerMonth,
    Map<String, double>? expensesPerMonth,
    Map<String, double>? revenuePerYear,
    Map<String, double>? expensesPerYear,
  }) {
    return FinancialsLoaded(
      currencyProfiles: currencyProfiles ?? this.currencyProfiles,
      scheduledBills: scheduledBills ?? this.scheduledBills,
      goals: goals ?? this.goals,
      bills: bills ?? this.bills,
      sessionsCountPerMonth:
          sessionsCountPerMonth ?? this.sessionsCountPerMonth,
      evaluationsCountPerMonth:
          evaluationsCountPerMonth ?? this.evaluationsCountPerMonth,
      revenuePerMonth: revenuePerMonth ?? this.revenuePerMonth,
      expensesPerMonth: expensesPerMonth ?? this.expensesPerMonth,
      revenuePerYear: revenuePerYear ?? this.revenuePerYear,
      expensesPerYear: expensesPerYear ?? this.expensesPerYear,
    );
  }
}

/// State when a financial operation is successful.
class FinancialsSuccess extends FinancialsState {
  final String message;

  const FinancialsSuccess({
    required this.message,
    required super.scheduledBills,
    required super.goals,
    required super.currencyProfiles,
    required super.bills,
    required super.sessionsCountPerMonth,
    required super.evaluationsCountPerMonth,
    required super.revenuePerMonth,
    required super.expensesPerMonth,
    required super.revenuePerYear,
    required super.expensesPerYear,
  });

  @override
  List<Object?> get props => [message, ...super.props];

  @override
  FinancialsSuccess copyWith({
    String? message,
    List<CurrencyProfileModel>? currencyProfiles,
    List<ScheduledBillModel>? scheduledBills,
    List<GoalModelBase>? goals,
    List<BillModel>? bills,
    Map<String, int>? sessionsCountPerMonth,
    Map<String, int>? evaluationsCountPerMonth,
    Map<String, double>? revenuePerMonth,
    Map<String, double>? expensesPerMonth,
    Map<String, double>? revenuePerYear,
    Map<String, double>? expensesPerYear,
  }) {
    return FinancialsSuccess(
      message: message ?? this.message,
      scheduledBills: scheduledBills ?? this.scheduledBills,
      goals: goals ?? this.goals,
      currencyProfiles: currencyProfiles ?? this.currencyProfiles,
      bills: bills ?? this.bills,
      sessionsCountPerMonth:
          sessionsCountPerMonth ?? this.sessionsCountPerMonth,
      evaluationsCountPerMonth:
          evaluationsCountPerMonth ?? this.evaluationsCountPerMonth,
      revenuePerMonth: revenuePerMonth ?? this.revenuePerMonth,
      expensesPerMonth: expensesPerMonth ?? this.expensesPerMonth,
      revenuePerYear: revenuePerYear ?? this.revenuePerYear,
      expensesPerYear: expensesPerYear ?? this.expensesPerYear,
    );
  }
}

/// State when an error occurs in financial operations.
class FinancialsError extends FinancialsState {
  final String message;

  const FinancialsError({
    required this.message,
    required super.scheduledBills,
    required super.goals,
    required super.currencyProfiles,
    required super.bills,
    required super.sessionsCountPerMonth,
    required super.evaluationsCountPerMonth,
    required super.revenuePerMonth,
    required super.expensesPerMonth,
    required super.revenuePerYear,
    required super.expensesPerYear,
  });

  @override
  List<Object?> get props => [message, ...super.props];

  @override
  FinancialsError copyWith({
    String? message,
    List<CurrencyProfileModel>? currencyProfiles,
    List<ScheduledBillModel>? scheduledBills,
    List<GoalModelBase>? goals,
    List<BillModel>? bills,
    Map<String, int>? sessionsCountPerMonth,
    Map<String, int>? evaluationsCountPerMonth,
    Map<String, double>? revenuePerMonth,
    Map<String, double>? expensesPerMonth,
    Map<String, double>? revenuePerYear,
    Map<String, double>? expensesPerYear,
  }) {
    return FinancialsError(
      message: message ?? this.message,
      currencyProfiles: currencyProfiles ?? this.currencyProfiles,
      scheduledBills: scheduledBills ?? this.scheduledBills,
      goals: goals ?? this.goals,
      bills: bills ?? this.bills,
      sessionsCountPerMonth:
          sessionsCountPerMonth ?? this.sessionsCountPerMonth,
      evaluationsCountPerMonth:
          evaluationsCountPerMonth ?? this.evaluationsCountPerMonth,
      revenuePerMonth: revenuePerMonth ?? this.revenuePerMonth,
      expensesPerMonth: expensesPerMonth ?? this.expensesPerMonth,
      revenuePerYear: revenuePerYear ?? this.revenuePerYear,
      expensesPerYear: expensesPerYear ?? this.expensesPerYear,
    );
  }
}
