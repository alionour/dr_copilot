import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/medications/data/repositories/medication_repository.dart';
import 'package:dr_copilot/src/features/medications/domain/models/medication_model.dart';

// Events
abstract class MedicationEvent extends Equatable {
  const MedicationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedications extends MedicationEvent {
  final String patientId;

  const LoadMedications(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class AddMedication extends MedicationEvent {
  final MedicationModel medication;
  final File? file;

  const AddMedication({required this.medication, this.file});

  @override
  List<Object?> get props => [medication, file];
}

class DeleteMedication extends MedicationEvent {
  final MedicationModel medication;

  const DeleteMedication(this.medication);

  @override
  List<Object?> get props => [medication];
}

// State
abstract class MedicationState extends Equatable {
  const MedicationState();

  @override
  List<Object?> get props => [];
}

class MedicationInitial extends MedicationState {}

class MedicationLoading extends MedicationState {}

class MedicationsLoaded extends MedicationState {
  final List<MedicationModel> medications;

  const MedicationsLoaded(this.medications);

  @override
  List<Object?> get props => [medications];
}

class MedicationOperationSuccess extends MedicationState {
  final String message;

  const MedicationOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicationError extends MedicationState {
  final String message;

  const MedicationError(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicationBloc extends Bloc<MedicationEvent, MedicationState> {
  final MedicationRepository _repository;

  MedicationBloc(this._repository) : super(MedicationInitial()) {
    on<LoadMedications>(_onLoadMedications);
    on<AddMedication>(_onAddMedication);
    on<DeleteMedication>(_onDeleteMedication);
  }

  Future<void> _onLoadMedications(
    LoadMedications event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    final result = await _repository.getMedicationsForPatient(event.patientId);
    result.fold(
      (failure) => emit(MedicationError(failure.message)),
      (medications) => emit(MedicationsLoaded(medications)),
    );
  }

  Future<void> _onAddMedication(
    AddMedication event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());

    var medication = event.medication;

    if (event.file != null) {
      final uploadResult = await _repository.uploadPrescription(
        file: event.file!,
        patientId: medication.patientId,
      );

      if (uploadResult.isLeft()) {
        uploadResult.fold(
          (failure) => emit(MedicationError(failure.message)),
          (_) {},
        );
        return;
      }

      final downloadUrl = uploadResult.getOrElse(() => '');
      medication = medication.copyWith(fileUrl: downloadUrl);
    }

    final result = await _repository.addMedication(medication);

    result.fold((failure) => emit(MedicationError(failure.message)), (_) {
      emit(const MedicationOperationSuccess('Medication added successfully'));
      add(LoadMedications(medication.patientId));
    });
  }

  Future<void> _onDeleteMedication(
    DeleteMedication event,
    Emitter<MedicationState> emit,
  ) async {
    emit(MedicationLoading());
    final result = await _repository.deleteMedication(event.medication);

    result.fold((failure) => emit(MedicationError(failure.message)), (_) {
      emit(const MedicationOperationSuccess('Medication deleted successfully'));
      add(LoadMedications(event.medication.patientId));
    });
  }
}

