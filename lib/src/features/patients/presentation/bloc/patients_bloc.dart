import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dr_copilot/src/core/error/failures.dart';
import 'package:dr_copilot/src/features/patients/domain/models/patient_model.dart';
import 'package:dr_copilot/src/features/patients/domain/usecases/patients_usecase.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
    on<GetPatientsCount>(_onGetPatientsCount);
  }

  Future<void> _onGetPatients(
      GetPatients event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading(state.patients));
    final failureOrTuple = await _patientsUseCase.getPatients(
      lastDocumentId: event.lastDocumentID,
      limit: event.limit,
    );
    emit(failureOrTuple.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (tuple) {
        final patients = tuple.value1;
        final lastDocumentSnapshot = tuple.value2;
        return PatientsLoaded(patients, lastDocument: lastDocumentSnapshot);
      },
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
        // Insert the new patient in the correct sorted position (descending by createdAt)
        final patients = List<PatientModel>.from(state.patients)
          ..add(patient)
          ..sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
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
        emit(PatientsSuccess(updatedPatients, message: 'patientDeleted'.tr()));
        return PatientsLoaded(updatedPatients);
      },
    ));
  }

  /// Handles searching for patients based on various criteria.
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
    debugPrint(
        'LoadMorePatients event triggered with lastDocumentId: ${event.lastDocumentId} and limit: ${event.limit}');
    if (state is PatientsLoaded) {
      final currentState = state as PatientsLoaded;
      if (currentState.isLoadingMore) return;

      emit(PatientsLoaded(currentState.patients,
          isLoadingMore: true,
          lastDocument:
              currentState.lastDocument)); // Pass existing lastDocument
      await Future.delayed(const Duration(seconds: 1));
      final failureOrTuple = await _patientsUseCase.getPatients(
        lastDocumentId: event.lastDocumentId,
        limit: event.limit,
      );

      failureOrTuple.fold(
        (failure) {
          debugPrint(
              'LoadMorePatients failed: ${_mapFailureToMessage(failure)}');
          emit(PatientsError(currentState.patients,
              message: _mapFailureToMessage(failure)));
        },
        (tuple) {
          final newPatients = tuple.value1;
          final lastDocumentSnapshot = tuple.value2;
          debugPrint(
              'Fetched ${newPatients.length} new patients: ${newPatients.map((p) => p.id).toList()}');
          final updatedPatients = List<PatientModel>.from(currentState.patients)
            ..addAll(newPatients.where((newPatient) => !currentState.patients
                .any(
                    (existingPatient) => existingPatient.id == newPatient.id)));
          debugPrint(
              'Updated patients list contains ${updatedPatients.length} patients.');
          emit(PatientsLoaded(updatedPatients,
              lastDocument: lastDocumentSnapshot)); // Pass new lastDocument
        },
      );
    }
  }

  Future<void> _onGetPatientsByDate(
      GetPatientsByDate event, Emitter<PatientsState> emit) async {
    emit(PatientsLoading(state.patients));

    final result = await _patientsUseCase.getPatientsByDate(
      event.year,
      event.month,
    );
    result.fold(
      (failure) {
        debugPrint(
            'GetPatientsByDate failed: ${_mapFailureToMessage(failure)}');
        emit(PatientsError(state.patients,
            message: _mapFailureToMessage(failure)));
      },
      (patients) {
        debugPrint(
            'Fetched ${patients.length} patients for month ${event.month}/${event.year}');
        emit(PatientsLoaded(patients));
      },
    );
  }

  Future<void> _onGetPatientsCount(
      GetPatientsCount event, Emitter<PatientsState> emit) async {
    final failureOrCount = await _patientsUseCase.getPatientsCount();
    emit(failureOrCount.fold(
      (failure) =>
          PatientsError(state.patients, message: _mapFailureToMessage(failure)),
      (totalCount) {
        debugPrint('Total patients count: $totalCount');
        return PatientsCountLoaded(totalCount, state.patients);
      },
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

