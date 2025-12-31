part of 'doctors_bloc.dart';

/// Abstract base class for all Doctors states.
abstract class DoctorsState extends Equatable {
  final List<DoctorModel> doctors;
  final String? message;

  const DoctorsState(this.doctors, {this.message});

  @override
  List<Object?> get props => [doctors, message];
}

/// Initial state of the Doctors feature.
class DoctorsInitial extends DoctorsState {
  const DoctorsInitial(super.doctors);
}

/// State indicating that an operation is in progress.
class DoctorsLoading extends DoctorsState {
  const DoctorsLoading(super.doctors);
}

/// State indicating that the list of doctors has been loaded successfully.
class DoctorsLoaded extends DoctorsState {
  const DoctorsLoaded(super.doctors);
}

/// State indicating that an error occurred.
class DoctorsError extends DoctorsState {
  const DoctorsError(super.doctors, {super.message});
}

/// State indicating that an operation (add, update, delete) completed successfully.
class DoctorsSuccess extends DoctorsState {
  const DoctorsSuccess(super.doctors, {super.message});
}
