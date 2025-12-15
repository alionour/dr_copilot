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

  const RecycleBinLoaded({
    required this.deletedEvaluations,
    required this.deletedSessions,
  });

  @override
  List<Object?> get props => [deletedEvaluations, deletedSessions];

  List<dynamic> get allItems {
    final all = [...deletedEvaluations, ...deletedSessions];
    // Sort by deletedAt descending
    all.sort((a, b) {
      final aTime = (a is EvaluationModel)
          ? a.deletedAt
          : (a as SessionModel).deletedAt;
      final bTime = (b is EvaluationModel)
          ? b.deletedAt
          : (b as SessionModel).deletedAt;
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

