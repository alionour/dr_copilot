part of 'doctors_bloc.dart';

abstract class DoctorsState extends Equatable {
  final List<DoctorModel> doctors;
  final String? message;

  const DoctorsState(this.doctors, {this.message});

  @override
  List<Object?> get props => [doctors, message];
}

class DoctorsInitial extends DoctorsState {
  const DoctorsInitial(super.doctors);
}

class DoctorsLoading extends DoctorsState {
  const DoctorsLoading(super.doctors);
}

class DoctorsLoaded extends DoctorsState {
  const DoctorsLoaded(super.doctors);
}

class DoctorsError extends DoctorsState {
  const DoctorsError(super.doctors, {super.message});
}

class DoctorsSuccess extends DoctorsState {
  const DoctorsSuccess(super.doctors, {super.message});
}

