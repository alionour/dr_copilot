import 'package:bloc/bloc.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/doctors/domain/models/doctor_model.dart';
import 'package:dr_copilot/src/features/doctors/domain/usecases/doctors_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

part 'doctors_event.dart';
part 'doctors_state.dart';

/// BLoC for managing the state of the Doctors feature.
///
/// Handles events for fetching, adding, updating, and deleting doctors.
class DoctorsBloc extends Bloc<DoctorsEvent, DoctorsState> {
  final DoctorsUseCase _doctorsUseCase;

  DoctorsBloc(this._doctorsUseCase) : super(const DoctorsInitial([])) {
    on<AddDoctor>(_onAddDoctor);
    on<GetDoctors>(_onGetDoctors);
    on<UpdateDoctor>(_onUpdateDoctor);
    on<DeleteDoctor>(_onDeleteDoctor);
  }

  /// Handles the [AddDoctor] event.
  void _onAddDoctor(AddDoctor event, Emitter<DoctorsState> emit) async {
    emit(DoctorsLoading(state.doctors));
    final failureOrSuccess = await _doctorsUseCase.addDoctor(event.doctor);
    failureOrSuccess.fold(
      (failure) => emit(
          DoctorsError(state.doctors, message: _mapFailureToMessage(failure))),
      (_) {
        final updatedDoctors = List<DoctorModel>.from(state.doctors)
          ..add(event.doctor);
        emit(DoctorsSuccess(updatedDoctors,
            message: 'doctorAddedSuccessfully'.tr()));
        emit(DoctorsLoaded(updatedDoctors));
      },
    );
  }

  /// Handles the [GetDoctors] event.
  void _onGetDoctors(GetDoctors event, Emitter<DoctorsState> emit) async {
    emit(DoctorsLoading(state.doctors));
    final failureOrDoctors =
        await _doctorsUseCase.getDoctors(clinicId: event.clinicId);
    failureOrDoctors.fold(
      (failure) => emit(
          DoctorsError(state.doctors, message: _mapFailureToMessage(failure))),
      (doctors) => emit(DoctorsLoaded(doctors)),
    );
  }

  /// Handles the [UpdateDoctor] event.
  void _onUpdateDoctor(UpdateDoctor event, Emitter<DoctorsState> emit) async {
    emit(DoctorsLoading(state.doctors));
    final failureOrSuccess =
        await _doctorsUseCase.updateDoctor(event.doctorId, event.doctor);
    failureOrSuccess.fold(
      (failure) => emit(
          DoctorsError(state.doctors, message: _mapFailureToMessage(failure))),
      (_) {
        final updatedDoctors = state.doctors.map((doctor) {
          return doctor.id == event.doctorId ? event.doctor : doctor;
        }).toList();
        emit(DoctorsSuccess(updatedDoctors,
            message: 'doctorUpdatedSuccessfully'.tr()));
        emit(DoctorsLoaded(updatedDoctors));
      },
    );
  }

  /// Handles the [DeleteDoctor] event.
  void _onDeleteDoctor(DeleteDoctor event, Emitter<DoctorsState> emit) async {
    emit(DoctorsLoading(state.doctors));
    final failureOrSuccess = await _doctorsUseCase.deleteDoctor(event.doctorId);
    failureOrSuccess.fold(
      (failure) => emit(
          DoctorsError(state.doctors, message: _mapFailureToMessage(failure))),
      (_) {
        final updatedDoctors = state.doctors
            .where((doctor) => doctor.id != event.doctorId)
            .toList();
        emit(DoctorsSuccess(updatedDoctors,
            message: 'doctorDeletedSuccessfully'.tr()));
        emit(DoctorsLoaded(updatedDoctors));
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
