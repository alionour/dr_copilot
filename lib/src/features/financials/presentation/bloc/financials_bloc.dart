import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/features/financials/domain/models/currency_profile_model.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/financials_usecase.dart';
import '../../../../core/error/failures.dart';

part 'financials_event.dart';
part 'financials_state.dart';

/// Bloc for managing financial transactions.
class FinancialsBloc extends Bloc<FinancialsEvent, FinancialsState> {
  // ignore: unused_field
  final FinancialsUseCase _financialsUseCase;

  FinancialsBloc(FinancialsUseCase financialsUseCase)
      : _financialsUseCase = financialsUseCase,
        super(FinancialsInitial()) {
    on<GetSessionsCountForYear>(_onGetSessionsCountForYear);
    on<GetSessionsCountForMonth>(_onGetSessionsCountForMonth);
    on<GetEvaluationsCountForYear>(_onGetEvaluationsCountForYear);
    on<GetEvaluationsCountForMonth>(_onGetEvaluationsCountForMonth);

    // Currency Profile Events
    on<FetchCurrencyProfiles>(_onFetchCurrencyProfiles);
    on<AddCurrencyProfile>(_onAddCurrencyProfile);
    on<DeleteCurrencyProfile>(_onDeleteCurrencyProfile);
    on<UpdateCurrencyProfile>(_onUpdateCurrencyProfile);
  }

  Future<void> _onGetSessionsCountForYear(
      GetSessionsCountForYear event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result =
        await _financialsUseCase.getSessionsCountForYear(year: event.year);
    result.fold(
      (failure) =>
          emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (count) =>
          emit(FinancialsSuccess(message: 'Sessions in ${event.year}: $count')),
    );
  }

  Future<void> _onGetSessionsCountForMonth(
      GetSessionsCountForMonth event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await _financialsUseCase.getSessionsCountForMonth(
        year: event.year, month: event.month);
    result.fold(
      (failure) =>
          emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (count) => emit(FinancialsSuccess(
          message: 'Sessions in ${event.year}-${event.month}: $count')),
    );
  }

  Future<void> _onGetEvaluationsCountForYear(
      GetEvaluationsCountForYear event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result =
        await _financialsUseCase.getEvaluationsCountForYear(year: event.year);
    result.fold(
      (failure) =>
          emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (count) => emit(
          FinancialsSuccess(message: 'Evaluations in ${event.year}: $count')),
    );
  }

  Future<void> _onGetEvaluationsCountForMonth(
      GetEvaluationsCountForMonth event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await _financialsUseCase.getEvaluationsCountForMonth(
        year: event.year, month: event.month);
    result.fold(
      (failure) =>
          emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (count) => emit(FinancialsSuccess(
          message: 'Evaluations in ${event.year}-${event.month}: $count')),
    );
  }
  

  Future<void> _onFetchCurrencyProfiles(
      FetchCurrencyProfiles event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await _financialsUseCase.fetchCurrencyProfiles();
    result.fold(
      (failure) => emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (profiles) => emit(FinancialsCurrencyProfilesLoaded(profiles)),
    );
  }

  Future<void> _onAddCurrencyProfile(
      AddCurrencyProfile event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await _financialsUseCase.addCurrencyProfile(currencyProfile: event.profile);
    result.fold(
      (failure) => emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (profile) => emit(FinancialsCurrencyProfileAdded(profile)),
    );
  }

  Future<void> _onDeleteCurrencyProfile(
      DeleteCurrencyProfile event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await _financialsUseCase.deleteCurrencyProfile(event.id);
    result.fold(
      (failure) => emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (_) => emit(FinancialsCurrencyProfileDeleted(event.id)),
    );
  }

  Future<void> _onUpdateCurrencyProfile(
      UpdateCurrencyProfile event, Emitter<FinancialsState> emit) async {
    emit(FinancialsLoading());
    final result = await _financialsUseCase.updateCurrencyProfile(event.profile);
    result.fold(
      (failure) => emit(FinancialsError(message: _mapFailureToMessage(failure))),
      (profile) => emit(FinancialsCurrencyProfileUpdated(profile)),
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
}
