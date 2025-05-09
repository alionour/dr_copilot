import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/features/financials/domain/models/bill_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/scheduled_bill_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../../domain/usecases/financials_usecase.dart';
import '../../../../core/error/failures.dart';

part 'financials_event.dart';
part 'financials_state.dart';

/// Bloc for managing financial transactions.
class FinancialsBloc extends Bloc<FinancialsEvent, FinancialsState> {
  /// Triggers fetching of session and evaluation counts for a given year and month.
  /// Call this after adding/updating/deleting goals or bills to keep progress up-to-date.
  void triggerCountsForGoal(GoalModelBase goal) {
    if (goal is CountGoalModel) {
      final year = goal.year ?? DateTime.now().year;
      final month = goal.month ?? DateTime.now().month;
      switch (goal.goalType) {
        case GoalType.sessionsYear:
          add(GetSessionsCountForYear(year));
          break;
        case GoalType.sessionsMonth:
          add(GetSessionsCountForMonth(year, month));
          break;
        case GoalType.evaluationsYear:
          add(GetEvaluationsCountForYear(year));
          break;
        case GoalType.evaluationsMonth:
          add(GetEvaluationsCountForMonth(year, month));
          break;
        default:
          break;
      }
    }
  }

  /// Triggers fetching of all session and evaluation counts for all goals in state.
  void triggerCountsForAllGoals() {
    for (final goal in state.goals) {
      triggerCountsForGoal(goal);
    }
  }

  /// Calculates the progress for a given goal based on its type.
  /// Returns a value between 0.0 and 1.0.
  /// Uses real data from the state if possible.
  double calculateGoalProgress(GoalModelBase goal) {
    switch (goal.goalType) {
      case GoalType.sessionsYear:
        return _calculateSessionsYearProgress(goal as CountGoalModel);
      case GoalType.sessionsMonth:
        return _calculateSessionsMonthProgress(goal as CountGoalModel);
      case GoalType.decreaseExpenses:
        return _calculateDecreaseExpensesProgress(goal as AmountGoalModel);
      case GoalType.increaseTotalRevenue:
        return _calculateIncreaseRevenueProgress(goal as AmountGoalModel);
      case GoalType.increaseTotalProfit:
        return _calculateIncreaseProfitProgress(goal as AmountGoalModel);
      case GoalType.increaseSessionsRevenue:
        return _calculateIncreaseSessionsRevenueProgress(
            goal as AmountGoalModel);
      case GoalType.increaseEvaluationsRevenue:
        return _calculateIncreaseEvaluationsRevenueProgress(
            goal as AmountGoalModel);
      case GoalType.evaluationsYear:
        return _calculateEvaluationsYearProgress(goal as CountGoalModel);
      case GoalType.evaluationsMonth:
        return _calculateEvaluationsMonthProgress(goal as CountGoalModel);
      case GoalType.custom:
        // For custom, you may want to implement a custom progress calculation
        // For now, always return 0.0
        return 0.0;
    }
  }

  // --- Real calculation methods using state data ---
  double _calculateSessionsYearProgress(CountGoalModel goal) {
    // Use backend-driven state for year count
    final year = goal.year ?? DateTime.now().year;
    final key = year.toString().padLeft(4, '0');
    final sessions = state.sessionsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (sessions / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  double _calculateSessionsMonthProgress(CountGoalModel goal) {
    final year = goal.year ?? DateTime.now().year;
    final month = goal.month ?? DateTime.now().month;
    final key =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final sessions = state.sessionsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (sessions / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  // Use state.evaluationsCountPerMonth for year/month progress
  double _calculateEvaluationsYearProgress(CountGoalModel goal) {
    final year = goal.year ?? DateTime.now().year;
    final key = year.toString().padLeft(4, '0');
    final evals = state.evaluationsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (evals / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  double _calculateEvaluationsMonthProgress(CountGoalModel goal) {
    final year = goal.year ?? DateTime.now().year;
    final month = goal.month ?? DateTime.now().month;
    final key =
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    final evals = state.evaluationsCountPerMonth[key] ?? 0;
    return goal.targetCount > 0
        ? (evals / goal.targetCount).clamp(0.0, 1.0)
        : 0.0;
  }

  double _calculateDecreaseExpensesProgress(AmountGoalModel goal) {
    // Use the goal's year if set, otherwise current year
    final year = goal.year ?? DateTime.now().year;
    final expenses = state.bills
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

  double _calculateIncreaseRevenueProgress(AmountGoalModel goal) {
    // Use the goal's year if set, otherwise current year
    final year = goal.year ?? DateTime.now().year;
    final revenue = state.bills
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

  double _calculateIncreaseProfitProgress(AmountGoalModel goal) {
    // Use the goal's year if set, otherwise current year
    final year = goal.year ?? DateTime.now().year;
    final revenue = state.bills
        .where((b) =>
            b.dueDate.toDate().year == year &&
            b.amount > 0 &&
            b.status == BillStatus.paid &&
            b.title.toLowerCase().contains('revenue'))
        .fold<double>(0.0, (sum, b) => sum + b.amount);
    final expenses = state.bills
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

  double _calculateIncreaseSessionsRevenueProgress(AmountGoalModel goal) {
    // Use the goal's year if set, otherwise current year
    final year = goal.year ?? DateTime.now().year;
    final sessionRevenue = state.bills
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

  double _calculateIncreaseEvaluationsRevenueProgress(AmountGoalModel goal) {
    // Use the goal's year if set, otherwise current year
    final year = goal.year ?? DateTime.now().year;
    final evalRevenue = state.bills
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

  final FinancialsUseCase _financialsUseCase;

  FinancialsBloc(FinancialsUseCase financialsUseCase)
      : _financialsUseCase = financialsUseCase,
        super(FinancialsInitial(
          scheduledBills: const [],
          goals: const [],
          currencyProfiles: const [],
          bills: const [],
          sessionsCountPerMonth: const {},
          evaluationsCountPerMonth: const {},
        )) {
    on<GetSessionsCountForYear>(_onGetSessionsCountForYear);
    on<GetSessionsCountForMonth>(_onGetSessionsCountForMonth);
    on<GetEvaluationsCountForYear>(_onGetEvaluationsCountForYear);
    on<GetEvaluationsCountForMonth>(_onGetEvaluationsCountForMonth);

    // Currency Profile Events
    on<FetchCurrencyProfiles>(_onFetchCurrencyProfiles);
    on<AddCurrencyProfile>(_onAddCurrencyProfile);
    on<DeleteCurrencyProfile>(_onDeleteCurrencyProfile);
    on<UpdateCurrencyProfile>(_onUpdateCurrencyProfile);

    // Goal Events
    on<FetchGoals>(_onFetchGoals);
    on<AddGoal>(_onAddGoal);
    on<UpdateGoal>(_onUpdateGoal);
    on<DeleteGoal>(_onDeleteGoal);

    // Scheduled Bill Events
    on<FetchScheduledBills>(_onFetchScheduledBills);
    on<AddScheduledBill>(_onAddScheduledBill);
    on<UpdateScheduledBill>(_onUpdateScheduledBill);
    on<DeleteScheduledBill>(_onDeleteScheduledBill);

    // Generate bills from scheduled bills
    on<GenerateBillsFromScheduled>(_onGenerateBillsFromScheduled);

    /// Initiates the bill generation workflow by dispatching the [GenerateBillsFromScheduled]
    /// event to the bloc.
    ///
    /// This event triggers the underlying logic responsible for creating new bill
    /// entries based on predefined
    /// schedules, recurring payment plans, or other specified criteria.
    /// The process may involve fetching scheduled
    /// financial data, validating eligibility, and generating corresponding bill records within the system.
    ///
    /// Use this event to automate the creation of bills, ensuring that all scheduled or recurring financial
    /// obligations are accurately reflected and up-to-date in the application's financial records.
    ///
    /// Typical use cases include:
    /// - Generating monthly utility bills for customers with active subscriptions.
    /// - Creating invoices for recurring service agreements.
    /// - Automating payment reminders based on scheduled due dates.
    ///
    /// Ensure that all necessary scheduled data is available and up-to-date before triggering this event to
    /// avoid inconsistencies or missed bill generations.
    /// Adds the [GenerateBillsFromScheduled] event to the bloc, triggering the process
    /// of generating bills based on scheduled data or criteria.
    add(GenerateBillsFromScheduled());
  }

  /// Emits a [FinancialsSuccess] state with the provided [message].
  FinancialsSuccess successState({required String message}) {
    return FinancialsSuccess(
      message: message,
      scheduledBills: state.scheduledBills,
      goals: state.goals,
      currencyProfiles: state.currencyProfiles,
      bills: state.bills,
      sessionsCountPerMonth: state.sessionsCountPerMonth,
      evaluationsCountPerMonth: state.evaluationsCountPerMonth,
    );
  }

  /// Creates and returns a [FinancialsError] state with the provided error [message].
  FinancialsError errorState({required String message}) {
    return FinancialsError(
      message: message,
      scheduledBills: state.scheduledBills,
      goals: state.goals,
      currencyProfiles: state.currencyProfiles,
      bills: state.bills,
      sessionsCountPerMonth: state.sessionsCountPerMonth,
      evaluationsCountPerMonth: state.evaluationsCountPerMonth,
    );
  }

  Future<void> _onGenerateBillsFromScheduled(
      GenerateBillsFromScheduled event, Emitter<FinancialsState> emit) async {
    // 1. Fetch all scheduled bills
    final scheduledBillsResult = await _financialsUseCase.fetchScheduledBills();
    if (scheduledBillsResult.isLeft()) return;
    final scheduledBills = scheduledBillsResult.getOrElse(() => []);

    // 2. Fetch all existing bills
    final billsResult = await _financialsUseCase.fetchBills();
    if (billsResult.isLeft()) return;
    final bills = billsResult.getOrElse(() => []);

    // 3. For each scheduled bill, generate missing bills, skipping suppressed dates
    final now = DateTime.now();
    final List<BillModel> newBills = [];
    for (final scheduledBill in scheduledBills) {
      // Get existing due dates from bills
      final existingDueDates = bills
          .where((b) => b.scheduledBillId == scheduledBill.id)
          .map((b) => b.dueDate.toDate().toIso8601String().split('T')[0])
          .toSet();

      // Fetch suppressed due dates for this scheduled bill
      final suppressedDueDates =
          await _financialsUseCase.fetchSuppressedDueDates(scheduledBill.id);
      final allSuppressed = existingDueDates.union(suppressedDueDates);
      final generated = generateMissingBills(
        scheduledBill: scheduledBill,
        from: scheduledBill.scheduledAt.toDate(),
        to: now,
        existingBillsDueDates: allSuppressed,
      );
      newBills.addAll(generated);
    }

    // 4. Add new bills to the backend (Firestore)
    for (final bill in newBills) {
      await _financialsUseCase.addBill(bill: bill);
    }
    // Optionally, emit a state or refetch bills
  }

  Future<void> _onGetSessionsCountForYear(
      GetSessionsCountForYear event, Emitter<FinancialsState> emit) async {
    final result =
        await _financialsUseCase.getSessionsCountForYear(year: event.year);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (count) {
        final key = event.year.toString().padLeft(4, '0');
        final updatedMap = Map<String, int>.from(state.sessionsCountPerMonth);
        updatedMap[key] = count;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: updatedMap,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
        ));
      },
    );
  }

  Future<void> _onGetSessionsCountForMonth(
      GetSessionsCountForMonth event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.getSessionsCountForMonth(
        year: event.year, month: event.month);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (count) {
        final key =
            '${event.year.toString().padLeft(4, '0')}-${event.month.toString().padLeft(2, '0')}';
        final updatedMap = Map<String, int>.from(state.sessionsCountPerMonth);
        updatedMap[key] = count;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: updatedMap,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
        ));
      },
    );
  }

  Future<void> _onGetEvaluationsCountForYear(
      GetEvaluationsCountForYear event, Emitter<FinancialsState> emit) async {
    final result =
        await _financialsUseCase.getEvaluationsCountForYear(year: event.year);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (count) {
        final key = event.year.toString().padLeft(4, '0');
        final updatedMap =
            Map<String, int>.from(state.evaluationsCountPerMonth);
        updatedMap[key] = count;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: updatedMap,
        ));
      },
    );
  }

  Future<void> _onGetEvaluationsCountForMonth(
      GetEvaluationsCountForMonth event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.getEvaluationsCountForMonth(
        year: event.year, month: event.month);
    result.fold(
      (failure) => emit(errorState(
        message: _mapFailureToMessage(failure),
      )),
      (count) {
        final key =
            '${event.year.toString().padLeft(4, '0')}-${event.month.toString().padLeft(2, '0')}';
        final updatedMap =
            Map<String, int>.from(state.evaluationsCountPerMonth);
        updatedMap[key] = count;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: updatedMap,
        ));
      },
    );
  }

  Future<void> _onFetchCurrencyProfiles(
      FetchCurrencyProfiles event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.fetchCurrencyProfiles();
    result.fold(
      (failure) => emit(errorState(
        message: _mapFailureToMessage(failure),
      )),
      (profiles) => emit(FinancialsLoaded(
        scheduledBills: state.scheduledBills,
        goals: state.goals,
        currencyProfiles: profiles,
        bills: state.bills,
        sessionsCountPerMonth: state.sessionsCountPerMonth,
        evaluationsCountPerMonth: state.evaluationsCountPerMonth,
      )),
    );
  }

  Future<void> _onAddCurrencyProfile(
      AddCurrencyProfile event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.addCurrencyProfile(
        currencyProfile: event.profile);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (profile) => emit(successState(
        message: 'currencyProfileAdded'.tr(),
      )),
    );
  }

  Future<void> _onDeleteCurrencyProfile(
      DeleteCurrencyProfile event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.deleteCurrencyProfile(event.id);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (_) => emit(successState(
        message: 'currencyProfileDeleted'.tr(),
      )),
    );
  }

  Future<void> _onUpdateCurrencyProfile(
      UpdateCurrencyProfile event, Emitter<FinancialsState> emit) async {
    final result =
        await _financialsUseCase.updateCurrencyProfile(event.profile);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (profile) => emit(successState(
        message: 'currencyProfileUpdated'.tr(),
      )),
    );
  }

  Future<void> _onFetchGoals(
      FetchGoals event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.fetchGoals();
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (goals) {
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          bills: state.bills,
          currencyProfiles: state.currencyProfiles,
          goals: goals,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
        ));
        // After loading goals, trigger fetching of counts for all goals
        triggerCountsForAllGoals();
      },
    );
  }

  Future<void> _onAddGoal(AddGoal event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.addGoal(goal: event.goal);
    result.fold(
        (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
        (goal) {
      emit(
        successState(
            message: 'goalAdded'.tr(
          args: [goal.title],
        )),
      );
      add(FetchGoals());
    });
  }

  Future<void> _onUpdateGoal(
      UpdateGoal event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.updateGoal(goal: event.goal);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (goal) => emit(successState(
        message: 'goalUpdated'.tr(
          args: [goal.title],
        ),
      )),
    );
  }

  Future<void> _onDeleteGoal(
      DeleteGoal event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.deleteGoal(event.id);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (_) => emit(successState(
        message: 'goalDeleted'.tr(
          args: [event.id],
        ),
      )),
    );
  }

  Future<void> _onFetchScheduledBills(
      FetchScheduledBills event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.fetchScheduledBills();
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (bills) => emit(FinancialsLoaded(
        bills: state.bills,
        currencyProfiles: state.currencyProfiles,
        goals: state.goals,
        scheduledBills: bills,
        sessionsCountPerMonth: state.sessionsCountPerMonth,
        evaluationsCountPerMonth: state.evaluationsCountPerMonth,
      )),
    );
  }

  Future<void> _onAddScheduledBill(
      AddScheduledBill event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.addScheduledBill(
        scheduledBill: event.scheduledBill);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (bill) => emit(successState(
        message: 'scheduledBillAdded'.tr(
          args: [bill.title],
        ),
      )),
    );
  }

  Future<void> _onUpdateScheduledBill(
      UpdateScheduledBill event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.updateScheduledBill(
        scheduledBill: event.scheduledBill);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (bill) => emit(successState(
        message: 'scheduledBillUpdated'.tr(
          args: [bill.title],
        ),
      )),
    );
  }

  Future<void> _onDeleteScheduledBill(
      DeleteScheduledBill event, Emitter<FinancialsState> emit) async {
    final result = await _financialsUseCase.deleteScheduledBill(event.id);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (_) => emit(successState(
        message: 'scheduledBillDeleted'.tr(
          args: [event.id],
        ),
      )),
    );
  }

  /// Maps a [Failure] to a user-friendly error message.
  // ignore: unused_element
  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server error occurred';
      case CacheFailure _:
        return 'Cache error occurred';
      default:
        return 'An unexpected error occurred';
    }
  }

  /// Returns a list of due dates (as DateTime) between [from] and [to] for a scheduled bill.
  List<DateTime> getDueDates(
    ScheduledBillModel scheduledBill, {
    required DateTime from,
    required DateTime to,
  }) {
    final List<DateTime> dueDates = [];
    DateTime next = scheduledBill.scheduledAt.toDate();
    if (next.isAfter(to)) return dueDates;
    while (!next.isAfter(to)) {
      if (!next.isBefore(from)) {
        dueDates.add(next);
      }
      switch (scheduledBill.recurrence) {
        case ScheduledBillRecurrence.none:
          break;
        case ScheduledBillRecurrence.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case ScheduledBillRecurrence.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case ScheduledBillRecurrence.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
      if (scheduledBill.recurrence == ScheduledBillRecurrence.none) break;
    }
    return dueDates;
  }

  /// Generates missing bills for a scheduled bill between [from] and [to].
  /// [existingBillsDueDates] is a set of due dates (yyyy-MM-dd) for which bills already exist.
  List<BillModel> generateMissingBills({
    required ScheduledBillModel scheduledBill,
    required DateTime from,
    required DateTime to,
    required Set<String> existingBillsDueDates,
  }) {
    final dueDates = getDueDates(scheduledBill, from: from, to: to);
    final uuid = Uuid();
    return dueDates
        .where((d) =>
            !existingBillsDueDates.contains(d.toIso8601String().split('T')[0]))
        .map((d) => BillModel(
              id: uuid.v4(),
              scheduledBillId: scheduledBill.id,
              title: scheduledBill.title,
              description: scheduledBill.description,
              amount: scheduledBill.amount,
              currencyProfileId: scheduledBill.currencyProfileId,
              dueDate: Timestamp.fromDate(d),
              status: BillStatus.unpaid,
              createdAt: Timestamp.fromDate(DateTime.now().toUtc()),
              createdBy: scheduledBill.createdBy,
              userId:'',//will be added at repository layer
            ))
        .toList();
  }
}
