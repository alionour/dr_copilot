part of 'patients_bloc.dart';

abstract class PatientsEvent extends Equatable {
  const PatientsEvent();

  @override
  List<Object?> get props => [];
}

class GetPatients extends PatientsEvent {
  final String? lastDocumentID;
  final int limit;

  const GetPatients({this.lastDocumentID, this.limit = 20});

  @override
  List<Object?> get props => [lastDocumentID, limit];
}

class SearchPatients extends PatientsEvent {
  final String? name;
  final int? minAge;
  final int? maxAge;
  final String? address;
  final String? gender;

  const SearchPatients(
      {this.name, this.minAge, this.maxAge, this.address, this.gender});

  @override
  List<Object?> get props => [name, minAge, maxAge, address, gender];
}

class AddPatient extends PatientsEvent {
  final PatientModel model;

  const AddPatient(this.model);

  @override
  List<Object> get props => [model];
}

class UpdatePatient extends PatientsEvent {
  final String patientId;
  final PatientModel model;

  const UpdatePatient(this.patientId, this.model);

  @override
  List<Object> get props => [patientId, model];
}

class DeletePatient extends PatientsEvent {
  final String patientId;

  const DeletePatient(this.patientId);

  @override
  List<Object> get props => [patientId];
}

class GetPatientsByDate extends PatientsEvent {
  final DateTime date;
  final String? lastDocumentID;
  final int limit;

  const GetPatientsByDate({
    required this.date,
    this.lastDocumentID,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [date, lastDocumentID, limit];
}

class LoadMorePatients extends PatientsEvent {
  final String query;
  final int? limit;
  final String? lastDocumentId;

  const LoadMorePatients(this.query, {this.lastDocumentId, this.limit});

  @override
  List<Object?> get props => [query, lastDocumentId, limit];
}
