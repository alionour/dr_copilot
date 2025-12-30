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

  const RecycleBinLoaded({
    required this.deletedEvaluations,
    required this.deletedSessions,
    required this.deletedPatients,
    required this.deletedCalendarEvents,
  });

  @override
  List<Object?> get props => [
        deletedEvaluations,
        deletedSessions,
        deletedPatients,
        deletedCalendarEvents,
      ];

  List<dynamic> get allItems {
    final all = [
      ...deletedEvaluations,
      ...deletedSessions,
      ...deletedPatients,
      ...deletedCalendarEvents,
    ];
    // Sort by deletedAt descending
    all.sort((a, b) {
      final aTime = (a is EvaluationModel)
          ? a.deletedAt
          : (a is SessionModel)
              ? (a as SessionModel).deletedAt
              : (a is PatientModel)
                  ? (a as PatientModel).deletedAt
                  : (a as CalendarEventModel).deletedAt;
      final bTime = (b is EvaluationModel)
          ? b.deletedAt
          : (b is SessionModel)
              ? (b as SessionModel).deletedAt
              : (b is PatientModel)
                  ? (b as PatientModel).deletedAt
                  : (b as CalendarEventModel).deletedAt;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });
    return all;
  }
}

class RecycleBinError extends RecycleBinState {
  final String message;

  const RecycleBinError(this.message);

  @override
  List<Object?> get props => [message];
}
