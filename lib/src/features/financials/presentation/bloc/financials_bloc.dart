import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/usecases/financials_usecase.dart';
import '../../../../core/error/failures.dart';

part 'financials_event.dart';
part 'financials_state.dart';

/// Bloc for managing financial transactions.
class FinancialsBloc extends Bloc<FinancialsEvent, FinancialsState> {
  final FinancialsUseCase _financialsUseCase;

  FinancialsBloc(FinancialsUseCase financialsUseCase)
      : _financialsUseCase = financialsUseCase,
        super(FinancialsInitial()) ;


  /// Maps a [Failure] to a user-friendly error message.
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
