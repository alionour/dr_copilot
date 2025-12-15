import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/app/notifiers/owner_notifier.dart';
import 'package:dr_copilot/src/features/financials/domain/models/bill_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/goal_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/invoice_model.dart';
import 'package:dr_copilot/src/features/financials/domain/models/scheduled_bill_model.dart';
import 'package:dr_copilot/src/features/financials/domain/financials_progress_utils.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/models/transaction_model.dart';
import 'package:dr_copilot/src/features/financials/transactions/domain/usecases/transactions_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../domain/usecases/financials_usecase.dart';
import '../../../../core/error/failures.dart';

part 'financials_event.dart';
part 'financials_state.dart';

/// Bloc for managing financial transactions.
class FinancialsBloc extends Bloc<FinancialsEvent, FinancialsState> {
  // --- Bill CRUD Handlers ---
  Future<void> _onFetchBills(
      FetchBills event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.fetchBills();
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (bills) => emit(FinancialsLoaded(
        scheduledBills: state.scheduledBills,
        goals: state.goals,
        currencyProfiles: state.currencyProfiles,
        bills: bills,
        sessionsCountPerMonth: state.sessionsCountPerMonth,
        evaluationsCountPerMonth: state.evaluationsCountPerMonth,
        expensesPerMonth: state.expensesPerMonth,
        revenuePerMonth: state.revenuePerMonth,
        revenuePerYear: state.revenuePerYear,
        expensesPerYear: state.expensesPerYear,
      )),
    );
  }

  Future<void> _onAddBill(AddBill event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.addBill(bill: event.bill);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (bill) => emit(successState(
        message: 'billAdded'.tr(args: [bill.title]),
      )),
    );
  }

  Future<void> _onUpdateBill(
      UpdateBill event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.updateBill(bill: event.bill);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (bill) => emit(successState(
        message: 'billUpdated'.tr(args: [bill.title]),
      )),
    );
  }

  Future<void> _onDeleteBill(
      DeleteBill event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.deleteBill(event.id);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (_) => emit(successState(
        message: 'billDeleted'.tr(args: [event.id]),
      )),
    );
  }

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
    return FinancialsProgressCalculator.calculateGoalProgress(
      goal: goal,
      sessionsCountPerMonth: state.sessionsCountPerMonth,
      evaluationsCountPerMonth: state.evaluationsCountPerMonth,
      bills: state.bills,
    );
  }

  final FinancialsUseCase financialsUseCase;
  final TransactionsUseCase transactionsUseCase;
  FinancialsBloc(this.financialsUseCase, this.transactionsUseCase)
      : super(FinancialsInitial(
          scheduledBills: const [],
          goals: const [],
          currencyProfiles: const [],
          bills: const [],
          sessionsCountPerMonth: const {},
          evaluationsCountPerMonth: const {},
          revenuePerYear: const {},
          expensesPerYear: const {},
          revenuePerMonth: const {},
          expensesPerMonth: const {},
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

    // Scheduled Bill Events
    on<FetchBills>(_onFetchBills);
    on<AddBill>(_onAddBill);
    on<UpdateBill>(_onUpdateBill);
    on<DeleteBill>(_onDeleteBill);

    // Bill Payment Event
    on<PayBill>(_onPayBill);

    // Invoice Events
    on<FetchInvoices>(_onFetchInvoices);
    on<AddInvoice>(_onAddInvoice);
    on<UpdateInvoice>(_onUpdateInvoice);
    on<DeleteInvoice>(_onDeleteInvoice);

    // Transaction Events
    on<FetchTransactions>(_onFetchTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);

    // --- Transaction Aggregation Events ---
    on<FetchTotalRevenueForYear>(_onFetchTotalRevenueForYear);
    on<FetchTotalExpensesForYear>(_onFetchTotalExpensesForYear);
    on<GetTotalRevenueForMonth>(_onFetchTotalRevenueForMonth);
    on<GetTotalExpensesForMonth>(_onFetchTotalExpensesForMonth);
    on<FetchTotalByDirectionAndSource>(_onFetchTotalByDirectionAndSource);

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

    final DateTime now = DateTime.now();
    final year = now.year;
    final month = now.month;

    add(GetSessionsCountForYear(year));
    add(GetSessionsCountForMonth(year, month));
    add(GetEvaluationsCountForYear(year));
    add(GetEvaluationsCountForMonth(year, month));

    /// Iterates through the next 12 months starting from the current month,
    /// calculates the corresponding month and year for each iteration,
    /// and dispatches two events for each month:
    /// - `GetSessionsCountForMonth` to retrieve the session count for the month.
    /// - `GetEvaluationsCountForMonth` to retrieve the evaluation count for the month.
    ///
    /// The calculation for the month uses modulo 12 to ensure it wraps around
    /// correctly after December, and the year is adjusted accordingly based on
    /// the overflow from the month calculation.
    // Always fetch data for all months in the current year (January to December)
    // Fetch data for all months in the current year and two years before
    for (int y = year - 2; y <= year; y++) {
      for (int m = 1; m <= 12; m++) {
        add(GetTotalRevenueForMonth(y, m));
        add(GetTotalExpensesForMonth(y, m));
      }
    }
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
      expensesPerMonth: state.expensesPerMonth,
      revenuePerMonth: state.revenuePerMonth,
      revenuePerYear: state.revenuePerYear,
      expensesPerYear: state.expensesPerYear,
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
      expensesPerMonth: state.expensesPerMonth,
      revenuePerMonth: state.revenuePerMonth,
      revenuePerYear: state.revenuePerYear,
      expensesPerYear: state.expensesPerYear,
    );
  }

  Future<void> _onGenerateBillsFromScheduled(
      GenerateBillsFromScheduled event, Emitter<FinancialsState> emit) async {
    // 1. Fetch all scheduled bills
    final scheduledBillsResult = await financialsUseCase.fetchScheduledBills();
    if (scheduledBillsResult.isLeft()) return;
    final scheduledBills = scheduledBillsResult.getOrElse(() => []);

    // 2. Fetch all existing bills
    final billsResult = await financialsUseCase.fetchBills();
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
          await financialsUseCase.fetchSuppressedDueDates(scheduledBill.id);
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
      await financialsUseCase.addBill(bill: bill);
    }
    // Optionally, emit a state or refetch bills
  }

  Future<void> _onGetSessionsCountForYear(
      GetSessionsCountForYear event, Emitter<FinancialsState> emit) async {
    final result =
        await financialsUseCase.getSessionsCountForYear(year: event.year);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (acc) {
        final key = event.year.toString().padLeft(4, '0');
        final updatedMap = Map<String, int>.from(state.sessionsCountPerMonth);
        updatedMap[key] = acc;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: updatedMap,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
          expensesPerMonth: state.expensesPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
      },
    );
  }

  Future<void> _onGetSessionsCountForMonth(
      GetSessionsCountForMonth event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.getSessionsCountForMonth(
        year: event.year, month: event.month);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (acc) {
        final key =
            '${event.year.toString().padLeft(4, '0')}-${event.month.toString().padLeft(2, '0')}';
        final updatedMap = Map<String, int>.from(state.sessionsCountPerMonth);
        updatedMap[key] = acc;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: updatedMap,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
          expensesPerMonth: state.expensesPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
      },
    );
  }

  Future<void> _onGetEvaluationsCountForYear(
      GetEvaluationsCountForYear event, Emitter<FinancialsState> emit) async {
    final result =
        await financialsUseCase.getEvaluationsCountForYear(year: event.year);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (acc) {
        final key = event.year.toString().padLeft(4, '0');
        final updatedMap =
            Map<String, int>.from(state.evaluationsCountPerMonth);
        updatedMap[key] = acc;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: updatedMap,
          expensesPerMonth: state.expensesPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
      },
    );
  }

  Future<void> _onGetEvaluationsCountForMonth(
      GetEvaluationsCountForMonth event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.getEvaluationsCountForMonth(
        year: event.year, month: event.month);
    result.fold(
      (failure) => emit(errorState(
        message: _mapFailureToMessage(failure),
      )),
      (acc) {
        final key =
            '${event.year.toString().padLeft(4, '0')}-${event.month.toString().padLeft(2, '0')}';
        final updatedMap =
            Map<String, int>.from(state.evaluationsCountPerMonth);
        updatedMap[key] = acc;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: updatedMap,
          expensesPerMonth: state.expensesPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
      },
    );
  }

  Future<void> _onFetchCurrencyProfiles(
      FetchCurrencyProfiles event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.fetchCurrencyProfiles();
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
        expensesPerMonth: state.expensesPerMonth,
        revenuePerMonth: state.revenuePerMonth,
        revenuePerYear: state.revenuePerYear,
        expensesPerYear: state.expensesPerYear,
      )),
    );
  }

  Future<void> _onAddCurrencyProfile(
      AddCurrencyProfile event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.addCurrencyProfile(
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
    final result = await financialsUseCase.deleteCurrencyProfile(event.id);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (_) => emit(successState(
        message: 'currencyProfileDeleted'.tr(),
      )),
    );
  }

  Future<void> _onUpdateCurrencyProfile(
      UpdateCurrencyProfile event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.updateCurrencyProfile(event.profile);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (profile) => emit(successState(
        message: 'currencyProfileUpdated'.tr(),
      )),
    );
  }

  Future<void> _onFetchGoals(
      FetchGoals event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.fetchGoals();
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
          expensesPerMonth: state.expensesPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
        // After loading goals, trigger fetching of counts for all goals
        triggerCountsForAllGoals();
      },
    );
  }

  Future<void> _onAddGoal(AddGoal event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.addGoal(goal: event.goal);
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
    final result = await financialsUseCase.updateGoal(goal: event.goal);
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
    final result = await financialsUseCase.deleteGoal(event.id);
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
    final result = await financialsUseCase.fetchScheduledBills();
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (bills) => emit(FinancialsLoaded(
        bills: state.bills,
        currencyProfiles: state.currencyProfiles,
        goals: state.goals,
        scheduledBills: bills,
        sessionsCountPerMonth: state.sessionsCountPerMonth,
        evaluationsCountPerMonth: state.evaluationsCountPerMonth,
        expensesPerMonth: state.expensesPerMonth,
        revenuePerMonth: state.revenuePerMonth,
        revenuePerYear: state.revenuePerYear,
        expensesPerYear: state.expensesPerYear,
      )),
    );
  }

  Future<void> _onAddScheduledBill(
      AddScheduledBill event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.addScheduledBill(
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
    final result = await financialsUseCase.updateScheduledBill(
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
    final result = await financialsUseCase.deleteScheduledBill(event.id);
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
              ownerId:
                  OwnerNotifier().ownerId!, //will be added at repository layer
              clinicId:
                  OwnerNotifier().clinicId!, //will be added at repository layer
            ))
        .toList();
  }

  // Invoice Events Handlers
  Future<void> _onFetchInvoices(
      FetchInvoices event, Emitter<FinancialsState> emit) async {
    // final result = await financialsUseCase.fetchInvoices();
    // result.fold(
    //   (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
    //   (invoices) => emit(FinancialsLoaded(
    //     scheduledBills: state.scheduledBills,
    //     goals: state.goals,
    //     currencyProfiles: state.currencyProfiles,
    //     bills: state.bills,
    //     sessionsCountPerMonth: state.sessionsCountPerMonth,
    //     evaluationsCountPerMonth: state.evaluationsCountPerMonth,
    //     invoices: invoices,
    //   )),
    // );
  }

  Future<void> _onAddInvoice(
      AddInvoice event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.addInvoice(invoice: event.invoice);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (invoice) => emit(successState(
        message: 'invoiceAdded'.tr(
          args: [invoice.title],
        ),
      )),
    );
  }

  Future<void> _onUpdateInvoice(
      UpdateInvoice event, Emitter<FinancialsState> emit) async {
    final result =
        await financialsUseCase.updateInvoice(invoice: event.invoice);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (invoice) => emit(successState(
        message: 'invoiceUpdated'.tr(
          args: [invoice.title],
        ),
      )),
    );
  }

  Future<void> _onDeleteInvoice(
      DeleteInvoice event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.deleteInvoice(event.id);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (_) => emit(successState(
        message: 'invoiceDeleted'.tr(),
      )),
    );
  }

  // Transactions Events Handlers
  Future<void> _onFetchTransactions(
      FetchTransactions event, Emitter<FinancialsState> emit) async {
    // final result = await financialsUseCase.fetchTransactions();
    // result.fold(
    //   (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
    //   (transactions) => emit(FinancialsLoaded(
    //     scheduledBills: state.scheduledBills,
    //     goals: state.goals,
    //     currencyProfiles: state.currencyProfiles,
    //     bills: state.bills,
    //     sessionsCountPerMonth: state.sessionsCountPerMonth,
    //     evaluationsCountPerMonth: state.evaluationsCountPerMonth,
    //     transactions: transactions,
    //   )),
    // );
  }

  Future<void> _onAddTransaction(
      AddTransaction event, Emitter<FinancialsState> emit) async {
    final result =
        await financialsUseCase.addTransaction(transaction: event.transaction);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (transaction) => emit(successState(
        message: 'transactionAdded'.tr(
          args: [],
        ),
      )),
    );
  }

  Future<void> _onUpdateTransaction(
      UpdateTransaction event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.updateTransaction(
        transaction: event.transaction);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (transaction) => emit(successState(
        message: 'transactionUpdated'.tr(
          args: [transaction.description],
        ),
      )),
    );
  }

  Future<void> _onDeleteTransaction(
      DeleteTransaction event, Emitter<FinancialsState> emit) async {
    final result = await financialsUseCase.deleteTransaction(event.id);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (_) => emit(successState(
        message: 'transactionDeleted'.tr(),
      )),
    );
  }

  Future<void> _onFetchTotalRevenueForYear(
      FetchTotalRevenueForYear event, Emitter<FinancialsState> emit) async {
    final result = await transactionsUseCase.getTotalRevenueForYear(event.year);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (totalRevenue) {
        final updatedRevenuePerYear =
            Map<String, double>.from(state.revenuePerYear);
        updatedRevenuePerYear[event.year.toString()] = totalRevenue;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          expensesPerMonth: state.expensesPerMonth,
          revenuePerYear: updatedRevenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
      },
    );
  }

  Future<void> _onFetchTotalExpensesForYear(
      FetchTotalExpensesForYear event, Emitter<FinancialsState> emit) async {
    final result =
        await transactionsUseCase.getTotalExpensesForYear(event.year);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (totalExpenses) {
        final updatedExpensesPerYear =
            Map<String, double>.from(state.expensesPerYear);
        updatedExpensesPerYear[event.year.toString()] = totalExpenses;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          expensesPerMonth: state.expensesPerMonth,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: updatedExpensesPerYear,
        ));
      },
    );
  }

  Future<void> _onFetchTotalRevenueForMonth(
      GetTotalRevenueForMonth event, Emitter<FinancialsState> emit) async {
    debugPrint(
      'Fetching total revenue for ${event.year}-${event.month}',
    );
    // Fetch the total revenue for the specified month and year
    final result = await transactionsUseCase.getTotalRevenueForMonth(
        event.year, event.month);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (total) {
        final key =
            '${event.year.toString().padLeft(4, '0')}-${event.month.toString().padLeft(2, '0')}';
        final updatedRevenueMap =
            Map<String, double>.from(state.revenuePerMonth);
        updatedRevenueMap[key] = total;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
          revenuePerMonth: updatedRevenueMap,
          expensesPerMonth: state.expensesPerMonth,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
        debugPrint(
          'Updated revenue for $updatedRevenueMap',
        );
      },
    );
  }

  Future<void> _onFetchTotalExpensesForMonth(
      GetTotalExpensesForMonth event, Emitter<FinancialsState> emit) async {
    final result = await transactionsUseCase.getTotalExpensesForMonth(
        event.year, event.month);
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (total) {
        final key =
            '${event.year.toString().padLeft(4, '0')}-${event.month.toString().padLeft(2, '0')}';
        final updatedExpensesMap =
            Map<String, double>.from(state.expensesPerMonth);
        updatedExpensesMap[key] = total;
        emit(FinancialsLoaded(
          scheduledBills: state.scheduledBills,
          goals: state.goals,
          currencyProfiles: state.currencyProfiles,
          bills: state.bills,
          sessionsCountPerMonth: state.sessionsCountPerMonth,
          evaluationsCountPerMonth: state.evaluationsCountPerMonth,
          revenuePerMonth: state.revenuePerMonth,
          expensesPerMonth: updatedExpensesMap,
          revenuePerYear: state.revenuePerYear,
          expensesPerYear: state.expensesPerYear,
        ));
        debugPrint(
          'Updated expenses for $updatedExpensesMap',
        );
      },
    );
  }

  Future<void> _onFetchTotalByDirectionAndSource(
      FetchTotalByDirectionAndSource event,
      Emitter<FinancialsState> emit) async {
    final result = await transactionsUseCase.getTotalByDirectionAndSource(
      direction: event.direction,
      source: event.source,
      year: event.year,
      month: event.month,
    );
    result.fold(
      (failure) => emit(errorState(message: _mapFailureToMessage(failure))),
      (total) => emit(FinancialsLoaded(
        scheduledBills: state.scheduledBills,
        goals: state.goals,
        currencyProfiles: state.currencyProfiles,
        bills: state.bills,
        sessionsCountPerMonth: state.sessionsCountPerMonth,
        evaluationsCountPerMonth: state.evaluationsCountPerMonth,
        revenuePerMonth: state.revenuePerMonth,
        expensesPerMonth: state.expensesPerMonth,
        revenuePerYear: state.revenuePerYear,
        expensesPerYear: state.expensesPerYear,
      )),
    );
  }

  // Handler for PayBill event
  Future<void> _onPayBill(PayBill event, Emitter<FinancialsState> emit) async {
    final bill = event.bill; // Get the bill to be paid from the event

    // 1. Create a transaction for this bill
    final transaction = TransactionModel(
      id: const Uuid().v4(), // Generate a unique ID for the transaction
      amount: bill.amount, // Set the transaction amount to the bill amount
      description:
          'Payment for bill: ${bill.id}', // Description for the transaction
      transactionDate: Timestamp.fromDate(
          DateTime.now().toUtc()), // Set the transaction date to now
      transactionSource: TransactionSource.bill, // Mark the source as a bill
      direction: TransactionDirection.fromSource(
          TransactionSource.bill), // Set the direction based on the source
      createdAt: Timestamp.fromDate(
          DateTime.now().toUtc()), // Set creation time to now (UTC)
      ownerId: bill.ownerId, // Associate the transaction with the bill's user
      createdBy: bill.createdBy, // Set who created the transaction
      currencyProfileId:
          bill.currencyProfileId, // Use the bill's currency profile
      notes: null, // No additional notes
      status: TransactionStatus.completed, // Mark the transaction as completed
      referenceId: bill.id, // Reference the bill ID
      clinicId: bill.clinicId, // Associate the transaction with the clinic
    );

    // Await the transaction creation
    final transactionResult =
        await financialsUseCase.addTransaction(transaction: transaction);
    if (emit.isDone) return;
    if (transactionResult.isLeft()) {
      final failure = transactionResult.swap().getOrElse(() => ServerFailure(
          'Failed to update bill status'
          'billId: ${bill.id}',
          401));
      emit(errorState(message: _mapFailureToMessage(failure)));
      return;
    }

    // 2. Mark the bill as paid
    final paidBill = bill.copyWith(
      status: BillStatus.paid,
      payedAt: Timestamp.fromDate(DateTime.now()),
    );
    final billResult = await financialsUseCase.updateBill(bill: paidBill);
    if (emit.isDone) return;
    if (billResult.isLeft()) {
      final failure = billResult.swap().getOrElse(() => ServerFailure(
          'Failed to update bill status'
          'billId: ${bill.id}',
          401));
      emit(errorState(message: _mapFailureToMessage(failure)));
      return;
    }
    emit(successState(message: 'billHasPaid'.tr(args: [bill.title])));
  }
}

