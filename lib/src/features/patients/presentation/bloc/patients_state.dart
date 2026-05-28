part of 'patients_bloc.dart';

abstract class PatientsState extends Equatable {
  final List<PatientModel> patients;
  final int? totalCount;
  const PatientsState(this.patients, {this.totalCount});

  @override
  List<Object?> get props => [patients, totalCount];
}

class PatientsInitial extends PatientsState {
  const PatientsInitial(super.patients, {super.totalCount});

  @override
  List<Object?> get props => [patients, totalCount];
}

class PatientsLoading extends PatientsState {
  const PatientsLoading(super.patients, {super.totalCount});

  @override
  List<Object?> get props => [patients, totalCount];
}

class PatientsLoadingMore extends PatientsState {
  const PatientsLoadingMore(super.patients, {super.totalCount});

  @override
  List<Object?> get props => [patients, totalCount];
}

class PatientsLoaded extends PatientsState {
  final bool isLoadingMore;
  final DocumentSnapshot? lastDocument;

  const PatientsLoaded(super.patients, {this.isLoadingMore = false, this.lastDocument, super.totalCount});

  @override
  List<Object?> get props => [patients, isLoadingMore, lastDocument, totalCount];
}

class PatientsSuccess extends PatientsState {
  final String? message;

  const PatientsSuccess(super.patients, {this.message, super.totalCount});

  @override
  List<Object?> get props => [patients, message, totalCount];
}

class PatientsError extends PatientsState {
  final String message;

  const PatientsError(super.patients, {required this.message, super.totalCount});

  @override
  List<Object?> get props => [patients, message, totalCount];
}

class PatientsCountLoaded extends PatientsState {
  final int count;
  const PatientsCountLoaded(this.count, super.patients, {super.totalCount});

  @override
  List<Object?> get props => [count, patients, totalCount];
}

