part of 'patients_bloc.dart';

abstract class PatientsState extends Equatable {
  final List<PatientModel> patients;
  const PatientsState(this.patients);

  @override
  List<Object?> get props => [patients];
}

class PatientsInitial extends PatientsState {
  const PatientsInitial(super.patients);

  @override
  List<Object?> get props => [patients];
}

class PatientsLoading extends PatientsState {


  const PatientsLoading(super.patients);

  @override
  List<Object?> get props => [patients];
}

class PatientsLoadingMore extends PatientsState {


  const PatientsLoadingMore(super.patients);

  @override
  List<Object?> get props => [patients];
}

class PatientsLoaded extends PatientsState {


  const PatientsLoaded(super.patients);

  @override
  List<Object?> get props => [patients];
}

class PatientsSuccess extends PatientsState {
  final String? message;

  const PatientsSuccess(super.patients,{this.message});

  @override
  List<Object?> get props => [patients,message];
}

class PatientsError extends PatientsState {
  final String message;

  const PatientsError(super.patients,{required this.message});

  @override
  List<Object?> get props => [patients,message];
}
