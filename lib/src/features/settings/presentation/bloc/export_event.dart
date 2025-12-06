import 'package:equatable/equatable.dart';

/// Base class for all export events.
abstract class ExportEvent extends Equatable {
  const ExportEvent();

  @override
  List<Object?> get props => [];
}

/// Event triggered when the user requests to export their data.
class ExportDataRequested extends ExportEvent {
  const ExportDataRequested();
}

/// Event triggered to update export progress.
class ExportProgressUpdated extends ExportEvent {
  final double progress;
  final String currentCategory;

  const ExportProgressUpdated({
    required this.progress,
    required this.currentCategory,
  });

  @override
  List<Object?> get props => [progress, currentCategory];
}

/// Event triggered when the export completes successfully.
class ExportCompleted extends ExportEvent {
  final String filePath;

  const ExportCompleted(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Event triggered when the export fails.
class ExportFailed extends ExportEvent {
  final String error;

  const ExportFailed(this.error);

  @override
  List<Object?> get props => [error];
}

/// Event triggered to reset the export state.
class ExportReset extends ExportEvent {
  const ExportReset();
}
