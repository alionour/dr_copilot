import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';

part 'patients_event.dart';
part 'patients_state.dart';

class PatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  final PatientsUseCase patientsUseCase;

  PatientsBloc(this.patientsUseCase) : super(PatientsInitial()) {
    on<GetPatients>(_onGetPatients);
    on<AddPatient>(_onAddPatient);
    on<UpdatePatient>(_onUpdatePatient);
    on<DeletePatient>(_onDeletePatient);
  }

  Future<void> _onGetPatients(GetPatients event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatients = await patientsUseCase.getPatients();
    emit(_eitherLoadedOrErrorState(failureOrPatients));
  }

  Future<void> _onAddPatient(AddPatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatient = await patientsUseCase.addPatient(event.patient);
    emit(_eitherLoadedOrErrorState(failureOrPatient));
  }

  Future<void> _onUpdatePatient(UpdatePatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrPatient = await patientsUseCase.updatePatient(event.patient);
    emit(_eitherLoadedOrErrorState(failureOrPatient));
  }

  Future<void> _onDeletePatient(DeletePatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading());
    final failureOrVoid = await patientsUseCase.deletePatient(event.patientId);
    emit(_eitherLoadedOrErrorState(failureOrVoid));
  }

  PatientsState _eitherLoadedOrErrorState(Either<Failure, dynamic> either) {
    return either.fold(
      (failure) => PatientsError(_mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server Failure';
      case CacheFailure:
        return 'Cache Failure';
      default:
        return 'Unexpected Error';
    }
  }
}
