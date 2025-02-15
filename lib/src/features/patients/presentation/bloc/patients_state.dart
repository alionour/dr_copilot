part of 'patients_bloc.dart';

abstract class PatientsState extends Equatable {
  const PatientsState();

  @override
  List<Object> get props => [];
}

class PatientsInitial extends PatientsState {}

class PatientsLoading extends PatientsState {}

class PatientsLoaded extends PatientsState {
  final List<PatientModel> patients;

  const PatientsLoaded(this.patients);

  @override
  List<Object> get props => [patients];
}

class PatientsSuccess extends PatientsState {}

class PatientsError extends PatientsState {
  final String message;

  const PatientsError(this.message);

  @override
  List<Object> get props => [message];
}
