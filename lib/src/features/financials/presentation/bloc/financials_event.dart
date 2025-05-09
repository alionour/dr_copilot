part of 'financials_bloc.dart';

/// Base class for all financial events.
abstract class FinancialsEvent extends Equatable {
  const FinancialsEvent();
  @override
  List<Object?> get props => [];
}

/// Event to retrieve the count of sessions for a specific year.
///
/// Typically used to trigger the fetching of session statistics
/// for analytics or reporting purposes within the financials feature.
class GetSessionsCountForYear extends FinancialsEvent {
  /// The year associated with the financial event.
  ///
  /// This value typically represents the calendar year for which the financial data applies.
  /// This typically represents the calendar year for which the financial data is relevant.
  /// This value typically represents the calendar year for which the financial data is relevant.
  final int year;
  const GetSessionsCountForYear(this.year);
  @override
  List<Object?> get props => [year];
}

/// Event to retrieve the count of sessions for a specific month.
///
/// This event should be dispatched when the application needs to fetch
/// the total number of sessions that occurred within a given month.
/// Typically used in financial reporting or analytics features.
class GetSessionsCountForMonth extends FinancialsEvent {
  final int year;

  /// The month represented as an integer (1 for January, 12 for December).
  final int month;
  const GetSessionsCountForMonth(this.year, this.month);
  @override
  List<Object?> get props => [year, month];
}

/// Event to retrieve the count of evaluations for a specific year.
///
/// This event should be dispatched when the application needs to fetch
/// the number of evaluations that occurred within a given year.
class GetEvaluationsCountForYear extends FinancialsEvent {
  final int year;
  const GetEvaluationsCountForYear(this.year);
  @override
  List<Object?> get props => [year];
}

/// Event to retrieve the count of evaluations for a specific month.
///
/// This event should be dispatched when the application needs to fetch
/// the number of evaluations that occurred within a given month.
///
/// Typically used in the financials feature to update statistics or reports
/// based on monthly evaluation data.
class GetEvaluationsCountForMonth extends FinancialsEvent {
  final int year;
  final int month;
  const GetEvaluationsCountForMonth(this.year, this.month);
  @override
  List<Object?> get props => [year, month];
}

/// Event to fetch the list of currency profiles in the financials feature.
class FetchCurrencyProfiles extends FinancialsEvent {}

/// Event to add a new currency profile to the financials feature.
///
/// This event should be dispatched when a user wants to add a new currency
/// profile, triggering the corresponding logic in the Financials BLoC.
class AddCurrencyProfile extends FinancialsEvent {
  final CurrencyProfileModel profile;
  const AddCurrencyProfile(this.profile);
  @override
  List<Object?> get props => [profile];
}

/// Event to delete a currency profile within the financials feature.
///
/// This event should be dispatched when a currency profile needs to be removed.
/// Extend this class to provide additional information if necessary.
class DeleteCurrencyProfile extends FinancialsEvent {
  final String id;
  const DeleteCurrencyProfile(this.id);
  @override
  List<Object?> get props => [id];
}

/// Event to update the currency profile in the financials feature.
///
/// This event should be dispatched when the user's currency profile needs to be updated,
/// such as when changing the preferred currency or updating related settings.
class UpdateCurrencyProfile extends FinancialsEvent {
  final CurrencyProfileModel profile;
  const UpdateCurrencyProfile(this.profile);
  @override
  List<Object?> get props => [profile];
}

/// Event to fetch all goals.
class FetchGoals extends FinancialsEvent {}

/// Event to add a new goal.
class AddGoal extends FinancialsEvent {
  final GoalModelBase goal;
  const AddGoal(this.goal);
  @override
  List<Object?> get props => [goal];
}

/// Event to update an existing goal.
class UpdateGoal extends FinancialsEvent {
  final GoalModelBase goal;
  const UpdateGoal(this.goal);
  @override
  List<Object?> get props => [goal];
}

/// Event to delete a goal.
class DeleteGoal extends FinancialsEvent {
  final String id;
  const DeleteGoal(this.id);
  @override
  List<Object?> get props => [id];
}

/// Event to fetch all scheduled bills.
class FetchScheduledBills extends FinancialsEvent {}

/// Event to add a new scheduled bill.
class AddScheduledBill extends FinancialsEvent {
  final ScheduledBillModel scheduledBill;
  const AddScheduledBill(this.scheduledBill);
  @override
  List<Object?> get props => [scheduledBill];
}

/// Event to update an existing scheduled bill.
class UpdateScheduledBill extends FinancialsEvent {
  final ScheduledBillModel scheduledBill;
  const UpdateScheduledBill(this.scheduledBill);
  @override
  List<Object?> get props => [scheduledBill];
}

/// Event to delete a scheduled bill.
class DeleteScheduledBill extends FinancialsEvent {
  final String id;
  const DeleteScheduledBill(this.id);
  @override
  List<Object?> get props => [id];
}

/// Event to generate missing bills from scheduled bills (should be dispatched on app start or tab open)
class GenerateBillsFromScheduled extends FinancialsEvent {
  const GenerateBillsFromScheduled();
  @override
  List<Object?> get props => [];
}


// Events for CRUD Invoices

/// Event to trigger fetching of invoices in the financials feature.
class FetchInvoices extends FinancialsEvent {}

/// Event to add a new invoice in the financials feature.
/// 
/// This event should be dispatched when a new invoice needs to be created
/// and added to the financial records. The associated data required to
/// create the invoice should be provided as part of this event.
class AddInvoice extends FinancialsEvent {
  final InvoiceModel invoice;
  const AddInvoice(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

/// Event to update an existing invoice within the financials feature.
/// 
/// This event should be dispatched when an invoice needs to be updated,
/// typically containing the updated invoice data as part of its payload.
class UpdateInvoice extends FinancialsEvent {
  final InvoiceModel invoice;
  const UpdateInvoice(this.invoice);
  @override
  List<Object?> get props => [invoice];
}

/// Event to trigger the deletion of an invoice within the financials feature.
/// 
/// This event should be dispatched when an invoice needs to be removed.
/// The associated handler should process the deletion logic accordingly.
class DeleteInvoice extends FinancialsEvent {
  final String id;
  const DeleteInvoice(this.id);
  @override
  List<Object?> get props => [id];
}


// Events for CRUD Transactions
/// Event to trigger fetching of transactions in the financials feature.
class FetchTransactions extends FinancialsEvent {}

/// Event to add a new transaction in the financials feature.
/// This event should be dispatched when a new transaction needs to be created
/// and added to the financial records. The associated data required to create
/// the transaction should be provided as part of this event.
class AddTransaction extends FinancialsEvent {
  final TransactionModel transaction;
  const AddTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}

/// Event to update an existing transaction within the financials feature.
/// This event should be dispatched when an existing transaction needs to be updated,
/// typically containing the updated transaction data as part of its payload.
class UpdateTransaction extends FinancialsEvent {
  final TransactionModel transaction;
  const UpdateTransaction(this.transaction);
  @override
  List<Object?> get props => [transaction];
}


/// Event to trigger the deletion of a transaction within the financials feature.
/// This event should be dispatched when an existing transaction needs to be removed.
class DeleteTransaction extends FinancialsEvent {
  final String id;
  const DeleteTransaction(this.id);
  @override
  List<Object?> get props => [id];
}