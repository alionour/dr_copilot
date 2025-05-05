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

class GetEvaluationsCountForYear extends FinancialsEvent {
  final int year;
  const GetEvaluationsCountForYear(this.year);
  @override
  List<Object?> get props => [year];
}

class GetEvaluationsCountForMonth extends FinancialsEvent {
  final int year;
  final int month;
  const GetEvaluationsCountForMonth(this.year, this.month);
  @override
  List<Object?> get props => [year, month];
}

class FetchCurrencyProfiles extends FinancialsEvent {}

class AddCurrencyProfile extends FinancialsEvent {
  final CurrencyProfileModel profile;
  const AddCurrencyProfile(this.profile);
  @override
  List<Object?> get props => [profile];
}

class DeleteCurrencyProfile extends FinancialsEvent {
  final String id;
  const DeleteCurrencyProfile(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateCurrencyProfile extends FinancialsEvent {
  final CurrencyProfileModel profile;
  const UpdateCurrencyProfile(this.profile);
  @override
  List<Object?> get props => [profile];
}
