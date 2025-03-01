import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:equatable/equatable.dart';

part 'patients_event.dart';
part 'patients_state.dart';

class PatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  final PatientsUseCase _patientsUseCase;

  PatientsBloc(this._patientsUseCase) : super(PatientsInitial()) {
    on<GetPatients>(_onGetPatients);
    on<AddPatient>(_onAddPatient);
    on<UpdatePatient>(_onUpdatePatient);
    on<DeletePatient>(_onDeletePatient);
    on<SearchPatients>(_onSearchPatients);
  }

  Future<void> _onGetPatients(
      GetPatients event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatients = await _patientsUseCase.getPatients(event.query);
    emit(failureOrPatients.fold(
      (failure) => PatientsError(_mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    ));
  }

  Future<void> _onAddPatient(
      AddPatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatient = await _patientsUseCase.addPatient(event.patient);
    emit(failureOrPatient.fold(
      (failure) => PatientsError(_mapFailureToMessage(failure)),
      (patient) {
        emit(PatientsSuccess());
        return PatientsLoaded([patient]);
      },
    ));
  }

  Future<void> _onUpdatePatient(
      UpdatePatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatient =
        await _patientsUseCase.updatePatient(event.patient);
    emit(failureOrPatient.fold(
      (failure) => PatientsError(_mapFailureToMessage(failure)),
      (patient) {
        emit(PatientsSuccess());
        return PatientsLoaded([patient]);
      },
    ));
  }

  Future<void> _onDeletePatient(
      DeletePatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatient =
        await _patientsUseCase.deletePatient(event.patientId);
    emit(failureOrPatient.fold(
      (failure) => PatientsError(_mapFailureToMessage(failure)),
      (patient) {
        emit(PatientsSuccess());
        return PatientsLoaded([patient]);
      },
    ));
  }

  Future<void> _onSearchPatients(
      SearchPatients event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatients =
        await _patientsUseCase.searchPatients(event.query);
    emit(failureOrPatients.fold(
      (failure) => PatientsError(_mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    ));
  }

  PatientsState _eitherLoadedOrErrorState(Either<Failure, dynamic> either) {
    return either.fold(
      (failure) => PatientsError(_mapFailureToMessage(failure)),
      (result) {
        if (result == null) {
          return PatientsSuccess();
        } else {
          return PatientsLoaded(result as List<PatientModel>);
        }
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
