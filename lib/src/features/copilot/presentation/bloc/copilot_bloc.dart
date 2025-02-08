import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/copilot/domain/models/copilot_model.dart';
import 'package:dr_copilot/src/features/copilot/domain/usecases/copilot_usecase.dart';
import 'package:equatable/equatable.dart';

part 'copilot_event.dart';
part 'copilot_state.dart';

class CopilotBloc extends Bloc<CopilotEvent, CopilotState> {
  final CopilotUseCase _copilotUseCase;

  CopilotBloc(this._copilotUseCase) : super(CopilotInitial()) {
    // ...additional event handlers...
  }

  

  CopilotState _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return CopilotError('Server Failure: ${failure.message}');
      case CacheFailure _:
        return CopilotError('Cache Failure: ${failure.message}');
      default:
        return const CopilotError('Unexpected Error');
    }
  }
}
