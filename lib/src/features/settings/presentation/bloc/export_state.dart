import 'package:equatable/equatable.dart';

/// Base class for all export states.
abstract class ExportState extends Equatable {
  const ExportState();

  @override
  List<Object?> get props => [];
}

/// Initial state before export has started.
class ExportInitial extends ExportState {
  const ExportInitial();
}

/// State when export is in progress.
class ExportInProgress extends ExportState {
  final double progress;
  final String currentCategory;

  const ExportInProgress({
    required this.progress,
    required this.currentCategory,
  });

  @override
  List<Object?> get props => [progress, currentCategory];
}

/// State when export has completed successfully.
class ExportSuccess extends ExportState {
  final String filePath;
  final int fileSize;

  const ExportSuccess({required this.filePath, required this.fileSize});

  @override
  List<Object?> get props => [filePath, fileSize];
}

/// State when export has failed.
class ExportFailure extends ExportState {
  final String error;

  const ExportFailure(this.error);

  @override
  List<Object?> get props => [error];
}
