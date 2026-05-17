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
  final String? departmentId;
  final String? teamId;

  const SearchPatients({
    this.name,
    this.minAge,
    this.maxAge,
    this.address,
    this.gender,
    this.departmentId,
    this.teamId,
  });

  @override
  List<Object?> get props =>
      [name, minAge, maxAge, address, gender, departmentId, teamId];
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
  final int year;
  final int month;

  const GetPatientsByDate({
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [
        year,
        month,
      ];
}

class LoadMorePatients extends PatientsEvent {
  final String lastDocumentId;
  final int limit;

  const LoadMorePatients({required this.lastDocumentId, this.limit = 20});

  @override
  List<Object?> get props => [lastDocumentId, limit];
}

class GetPatientsCount extends PatientsEvent {
  const GetPatientsCount();

  @override
  List<Object?> get props => [];
}

