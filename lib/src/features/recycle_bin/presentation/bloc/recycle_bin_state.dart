part of 'recycle_bin_bloc.dart';

abstract class RecycleBinState extends Equatable {
  const RecycleBinState();

  @override
  List<Object?> get props => [];
}

class RecycleBinInitial extends RecycleBinState {}

class RecycleBinLoading extends RecycleBinState {}

class RecycleBinLoaded extends RecycleBinState {
  final List<EvaluationModel> deletedEvaluations;
  final List<SessionModel> deletedSessions;
  final List<PatientModel> deletedPatients;
  final List<CalendarEventModel> deletedCalendarEvents;
  final String? warningMessage;

  const RecycleBinLoaded({
    required this.deletedEvaluations,
    required this.deletedSessions,
    required this.deletedPatients,
    required this.deletedCalendarEvents,
    this.warningMessage,
  });

  @override
  List<Object?> get props => [
        deletedEvaluations,
        deletedSessions,
        deletedPatients,
        deletedCalendarEvents,
        warningMessage,
      ];
}

class RecycleBinError extends RecycleBinState {
  final String message;

  const RecycleBinError(this.message);

  @override
  List<Object?> get props => [message];
}
