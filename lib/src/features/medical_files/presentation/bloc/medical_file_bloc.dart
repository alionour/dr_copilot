import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dr_copilot/src/features/medical_files/data/repositories/medical_file_repository.dart';
import 'package:dr_copilot/src/features/medical_files/domain/models/medical_file_model.dart';

// Events
abstract class MedicalFileEvent extends Equatable {
  const MedicalFileEvent();

  @override
  List<Object?> get props => [];
}

class LoadMedicalFiles extends MedicalFileEvent {
  final String patientId;

  const LoadMedicalFiles(this.patientId);

  @override
  List<Object?> get props => [patientId];
}

class AddMedicalFile extends MedicalFileEvent {
  final MedicalFileModel medicalFile;
  final File? file;

  const AddMedicalFile({required this.medicalFile, this.file});

  @override
  List<Object?> get props => [medicalFile, file];
}

class DeleteMedicalFile extends MedicalFileEvent {
  final MedicalFileModel medicalFile;

  const DeleteMedicalFile(this.medicalFile);

  @override
  List<Object?> get props => [medicalFile];
}

// State
abstract class MedicalFileState extends Equatable {
  const MedicalFileState();

  @override
  List<Object?> get props => [];
}

class MedicalFileInitial extends MedicalFileState {}

class MedicalFileLoading extends MedicalFileState {}

class MedicalFilesLoaded extends MedicalFileState {
  final List<MedicalFileModel> medicalFiles;

  const MedicalFilesLoaded(this.medicalFiles);

  @override
  List<Object?> get props => [medicalFiles];
}

class MedicalFileOperationSuccess extends MedicalFileState {
  final String message;

  const MedicalFileOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicalFileError extends MedicalFileState {
  final String message;

  const MedicalFileError(this.message);

  @override
  List<Object?> get props => [message];
}

class MedicalFileBloc extends Bloc<MedicalFileEvent, MedicalFileState> {
  final MedicalFileRepository _repository;

  MedicalFileBloc(this._repository) : super(MedicalFileInitial()) {
    on<LoadMedicalFiles>(_onLoadMedicalFiles);
    on<AddMedicalFile>(_onAddMedicalFile);
    on<DeleteMedicalFile>(_onDeleteMedicalFile);
  }

  Future<void> _onLoadMedicalFiles(
    LoadMedicalFiles event,
    Emitter<MedicalFileState> emit,
  ) async {
    emit(MedicalFileLoading());
    final result = await _repository.getMedicalFilesForPatient(event.patientId);
    result.fold(
      (failure) => emit(MedicalFileError(failure.message)),
      (files) => emit(MedicalFilesLoaded(files)),
    );
  }

  Future<void> _onAddMedicalFile(
    AddMedicalFile event,
    Emitter<MedicalFileState> emit,
  ) async {
    emit(MedicalFileLoading());

    var medicalFile = event.medicalFile;

    // 1. Upload file if exists
    if (event.file != null) {
      final uploadResult = await _repository.uploadFile(
        file: event.file!,
        patientId: medicalFile.patientId,
      );

      if (uploadResult.isLeft()) {
        uploadResult.fold(
          (failure) => emit(MedicalFileError(failure.message)),
          (_) {},
        );
        return;
      }

      final downloadUrl = uploadResult.getOrElse(() => '');
      medicalFile = medicalFile.copyWith(fileUrl: downloadUrl);
    }

    // 2. Save metadata to Firestore
    final result = await _repository.addMedicalFile(medicalFile);

    result.fold((failure) => emit(MedicalFileError(failure.message)), (_) {
      // Emit Success specifically to trigger navigation/snackbars
      emit(const MedicalFileOperationSuccess('File added successfully'));
      // Then reload the list
      add(LoadMedicalFiles(medicalFile.patientId));
    });
  }

  Future<void> _onDeleteMedicalFile(
    DeleteMedicalFile event,
    Emitter<MedicalFileState> emit,
  ) async {
    // Keep showing current list while deleting? Or loading?
    // Let's show loading to prevent double clicks
    emit(MedicalFileLoading());

    final result = await _repository.deleteMedicalFile(event.medicalFile);

    result.fold((failure) => emit(MedicalFileError(failure.message)), (_) {
      emit(const MedicalFileOperationSuccess('File deleted successfully'));
      add(LoadMedicalFiles(event.medicalFile.patientId));
    });
  }
}
