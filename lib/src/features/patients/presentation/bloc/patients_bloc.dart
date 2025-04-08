import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    emit(PatientsLoading(state.patients));
    final failureOrPatients = await _patientsUseCase.getPatients(
      lastDocumentId: event.lastDocumentID, // Corrected property name
      limit: event.limit, // Removed unnecessary null check
    );
    emit(failureOrPatients.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    ));
  }

  Future<void> _onAddPatient(
      AddPatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading(state.patients));
    final failureOrPatient = await _patientsUseCase.addPatient(event.model);
    emit(failureOrPatient.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (patient) {
        final patients = List<PatientModel>.from(state.patients)..add(patient);
        emit(PatientsSuccess(patients,
            message: 'patientAddedSuccessfully'.tr()));
        return PatientsLoaded(patients);
      },
    ));
  }

  Future<void> _onUpdatePatient(
      UpdatePatient event, Emitter<PatientsState> emit) async {
    final failureOrPatient =
        await _patientsUseCase.updatePatient(event.patientId, event.model);
    emit(failureOrPatient.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (updatedPatient) {
        final patients = state.patients.map((patient) {
          return patient.id == updatedPatient.id ? updatedPatient : patient;
        }).toList();
        emit(PatientsSuccess(patients, message: 'patientUpdated'.tr()));
        return PatientsLoaded(patients);
      },
    ));
  }

  Future<void> _onDeletePatient(
      DeletePatient event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading(state.patients));
    final failureOrResult =
        await _patientsUseCase.deletePatient(event.patientId);
    emit(failureOrResult.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (_) {
        final updatedPatients = state.patients
            .where((patient) => patient.id != event.patientId)
            .toList();
        emit(PatientsSuccess(updatedPatients,
            message: 'patientDeleted'));
        return PatientsLoaded(updatedPatients);
      },
    ));
  }

  Future<void> _onSearchPatients(
      SearchPatients event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading(state.patients));

    final failureOrPatients = await _patientsUseCase.searchPatients(
      name: event.name,
      minAge: event.minAge,
      maxAge: event.maxAge,
      address: event.address,
      gender: event.gender,
    );

    emit(failureOrPatients.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    ));
  }

  Future<void> _onLoadMorePatients(
      LoadMorePatients event, Emitter<PatientsState> emit) async {
    if (state is PatientsLoaded || state is PatientsLoadingMore) {
      final currentPatients = state.patients;
      emit(PatientsLoadingMore(currentPatients));

      final result = await _patientsUseCase.getPatients(
        lastDocumentId: event.lastDocumentId,
        limit: event.limit,
      );

      emit(result.fold(
        (failure) => PatientsError(currentPatients,
            message: _mapFailureToMessage(failure)),
        (newPatients) {
          final updatedPatients = List<PatientModel>.from(currentPatients)
            ..addAll(newPatients);
          return PatientsLoaded(updatedPatients);
        },
      ));
    }
  }

  Future<void> _onGetPatientsByDate(
      GetPatientsByDate event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading(state.patients));

    final result = await _patientsUseCase.getPatientsByDate(
      event.date,
    );
    emit(result.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (patients) => PatientsLoaded(patients),
    ));
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server Failure: ${failure.message}';
    } else if (failure is CacheFailure) {
      return 'Cache Failure: ${failure.message}';
    } else {
      return 'Unexpected Error: ${failure.message}';
    }
  }
}
