part of 'patients_bloc.dart';

abstract class PatientsEvent extends Equatable {
  const PatientsEvent();

  @override
  List<Object> get props => [];
}

class GetPatients extends PatientsEvent {}

class AddPatient extends PatientsEvent {
  final PatientModel patient;

  const AddPatient(this.patient);

  @override
  List<Object> get props => [patient];
}

class UpdatePatient extends PatientsEvent {
  final PatientModel patient;

  const UpdatePatient(this.patient);

  @override
  List<Object> get props => [patient];
}

class DeletePatient extends PatientsEvent {
  final String patientId;

  const DeletePatient(this.patientId);

  @override
  List<Object> get props => [patientId];
}
