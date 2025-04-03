import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'patients_event.dart';
part 'patients_state.dart';

class PatientsBloc extends Bloc<PatientsEvent, PatientsState> {
  final PatientsUseCase _patientsUseCase;

  PatientsBloc(this._patientsUseCase) : super(const PatientsInitial([])) {
    on<GetPatients>(_onGetPatients);
    on<AddPatient>(_onAddPatient);
    on<UpdatePatient>(_onUpdatePatient);
    on<DeletePatient>(_onDeletePatient);
    on<SearchPatients>(_onSearchPatients);
    on<LoadMorePatients>(_onLoadMorePatients);
    on<GetPatientsByDate>(_onGetPatientsByDate);
  }

  Future<void> _onGetPatients(
      GetPatients event, Emitter<PatientsState> emit) async {
    emit(const PatientsLoading());
    final failureOrPatients = await _patientsUseCase.getPatients();
    emit(failureOrPatients.fold(
      (failure) => PatientsError(message: _mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    ));
  }

  Future<void> _onAddPatient(
      AddPatient event, Emitter<PatientsState> emit) async {
    emit(const PatientsLoading());
    final failureOrPatient = await _patientsUseCase.addPatient(event.patient);
    emit(failureOrPatient.fold(
      (failure) => PatientsError(message: _mapFailureToMessage(failure)),
      (patient) {
        emit(const PatientsSuccess(message: 'Patient added successfully'));
        return PatientsLoaded([patient]);
      },
    ));
  }

  Future<void> _onUpdatePatient(
      UpdatePatient event, Emitter<PatientsState> emit) async {
    debugPrint('Updating patient: ${event.patientModel}');
    final failureOrPatient = await _patientsUseCase.updatePatient(
        event.patientId, event.patientModel);
    failureOrPatient.fold(
      (failure) {
        final errorMessage = _mapFailureToMessage(failure);
        debugPrint('Update failed: $errorMessage');
        emit(PatientsError(message: errorMessage));
      },
      (updatedPatient) {
        debugPrint('Update successful: $updatedPatient');
        if (state is PatientsLoaded) {
          // Update the list of patients locally
          final currentPatients = (state as PatientsLoaded).patients;
          final updatedPatients = currentPatients.map((patient) {
            return patient.id == updatedPatient.id ? updatedPatient : patient;
          }).toList();
          // Emit the updated list of patients
          emit(PatientsLoaded(updatedPatients));
        } else {
          // If no patients are loaded, emit success without refreshing
          emit(const PatientsSuccess(message: 'Patient updated successfully'));
        }
      },
    );
  }

  Future<void> _onDeletePatient(
      DeletePatient event, Emitter<PatientsState> emit) async {
    emit(const PatientsLoading());
    final failureOrPatient =
        await _patientsUseCase.deletePatient(event.patientId);
    emit(failureOrPatient.fold(
      (failure) => PatientsError(message: _mapFailureToMessage(failure)),
      (patient) {
        emit(const PatientsSuccess(message: 'Patient deleted successfully'));
        return const PatientsLoaded([]);
      },
    ));
  }

  Future<void> _onSearchPatients(
      SearchPatients event, Emitter<PatientsState> emit) async {
    emit(const PatientsLoading());
    final failureOrPatients =
        await _patientsUseCase.searchPatients(event.query);
    emit(failureOrPatients.fold(
      (failure) => PatientsError(message: _mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    ));
  }

  Future<void> _onLoadMorePatients(
      LoadMorePatients event, Emitter<PatientsState> emit) async {
    if (state is PatientsLoaded || state is PatientsLoadingMore) {
      final currentPatients = state.patients;
      emit(PatientsLoadingMore(currentPatients));

      final result = await _patientsRepository.getPatients(
        lastDocumentID: event.lastDocumentId,
        limit: event.limit ?? 20,
      );

      result.fold(
        (failure) =>
            emit(PatientsError(currentPatients, message: failure.message)),
        (newPatients) {
          final updatedPatients = List<PatientModel>.from(currentPatients)
            ..addAll(newPatients);
          emit(PatientsLoaded(updatedPatients));
        },
      );
    }
  }

  Future<void> _onGetPatientsByDate(
      GetPatientsByDate event, Emitter<PatientsState> emit) async {
    emit(const PatientsLoading([]));

    final result = await _patientsRepository.getPatientsByDate(
      event.date,
      lastDocumentID: event.lastDocumentID,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(PatientsError(const [], message: failure.message)),
      (patients) => emit(PatientsLoaded(patients)),
    );
  }

  PatientsState _eitherLoadedOrErrorState(Either<Failure, dynamic> either) {
    return either.fold(
      (failure) => PatientsError(message: _mapFailureToMessage(failure)),
      (result) {
        if (result == null) {
          return const PatientsSuccess();
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
