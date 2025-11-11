import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/staff/domain/models/staff_model.dart';
import 'package:dr_copilot/src/features/staff/domain/usecases/staff_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

part 'staff_event.dart';
part 'staff_state.dart';

class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffUseCases _staffUseCases;

  StaffBloc(this._staffUseCases) : super(const StaffInitial([])) {
    on<AddStaff>(_onAddStaff);
    on<GetStaff>(_onGetStaff);
    on<UpdateStaff>(_onUpdateStaff);
    on<DeleteStaff>(_onDeleteStaff);
  }

  void _onAddStaff(AddStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading(state.staff));
    final failureOrSuccess = await _staffUseCases.addStaff(event.staff);
    failureOrSuccess.fold(
      (failure) =>
          emit(StaffError(state.staff, message: _mapFailureToMessage(failure))),
      (_) {
        final updatedStaff = List<StaffModel>.from(state.staff)
          ..add(event.staff);
        emit(
            StaffSuccess(updatedStaff, message: 'staffAddedSuccessfully'.tr()));
        emit(StaffLoaded(updatedStaff));
      },
    );
  }

  void _onGetStaff(GetStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading(state.staff));
    final failureOrStaff =
        await _staffUseCases.getAllStaff(clinicId: event.clinicId);
    failureOrStaff.fold(
      (failure) =>
          emit(StaffError(state.staff, message: _mapFailureToMessage(failure))),
      (staff) {
        emit(StaffLoaded(staff));
      },
    );
  }

  void _onUpdateStaff(UpdateStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading(state.staff));
    final failureOrSuccess =
        await _staffUseCases.updateStaff(event.staffId, event.staff);
    failureOrSuccess.fold(
      (failure) =>
          emit(StaffError(state.staff, message: _mapFailureToMessage(failure))),
      (_) {
        final updatedStaff = state.staff.map((staff) {
          return staff.id == event.staffId ? event.staff : staff;
        }).toList();
        emit(StaffSuccess(updatedStaff,
            message: 'staffUpdatedSuccessfully'.tr()));
        emit(StaffLoaded(updatedStaff));
      },
    );
  }

  void _onDeleteStaff(DeleteStaff event, Emitter<StaffState> emit) async {
    emit(StaffLoading(state.staff));
    final failureOrSuccess = await _staffUseCases.deleteStaff(event.staffId);
    failureOrSuccess.fold(
      (failure) =>
          emit(StaffError(state.staff, message: _mapFailureToMessage(failure))),
      (_) {
        final updatedStaff =
            state.staff.where((staff) => staff.id != event.staffId).toList();
        emit(StaffSuccess(updatedStaff,
            message: 'staffDeletedSuccessfully'.tr()));
        emit(StaffLoaded(updatedStaff));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure _:
        return 'Server Failure: ${failure.message}';
      case CacheFailure _:
        return 'Cache Failure: ${failure.message}';
      default:
        return 'Unexpected Error: ${failure.message}';
    }
  }
}
