part of 'patients_bloc.dart';

abstract class PatientsState extends Equatable {
  const PatientsState();

  @override
  List<Object?> get props => [];
}

class PatientsInitial extends PatientsState {
    const PatientsInitial();

  @override
  List<Object?> get props => [];
}

class PatientsLoading extends PatientsState {
      const PatientsLoading();

  @override
  List<Object?> get props => [];
}

class PatientsLoaded extends PatientsState {
  final List<PatientModel> patients;

  const PatientsLoaded(this.patients);

  @override
  List<Object> get props => [patients];
}

class PatientsSuccess extends PatientsState {
    final String? message;

  const PatientsSuccess({this.message});

  @override
  List<Object?> get props => [message];
}


class PatientsError extends PatientsState {
  final String? message;

  const PatientsError({this.message});

  @override
  List<Object?> get props => [message];
}
