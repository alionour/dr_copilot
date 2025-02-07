part of 'patients_bloc.dart';

abstract class PatientsEvent extends Equatable {
  const PatientsEvent();

  @override
  List<Object> get props => [];
}

class GetPatients extends PatientsEvent {
  final String query;

  const GetPatients(this.query);

  @override
  List<Object> get props => [query];
}

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

class SearchPatients extends PatientsEvent {
  final String query;

  const SearchPatients(this.query);

  @override
  List<Object> get props => [query];
}
