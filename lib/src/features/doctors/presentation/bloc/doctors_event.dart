part of 'doctors_bloc.dart';

abstract class DoctorsEvent extends Equatable {
  const DoctorsEvent();

  @override
  List<Object> get props => [];
}

class AddDoctor extends DoctorsEvent {
  final DoctorModel doctor;

  const AddDoctor(this.doctor);

  @override
  List<Object> get props => [doctor];
}

class GetDoctors extends DoctorsEvent {
  final String? clinicId;

  const GetDoctors({this.clinicId});

  @override
  List<Object> get props => [clinicId ?? ''];
}

class UpdateDoctor extends DoctorsEvent {
  final String doctorId;
  final DoctorModel doctor;

  const UpdateDoctor(this.doctorId, this.doctor);

  @override
  List<Object> get props => [doctorId, doctor];
}

class DeleteDoctor extends DoctorsEvent {
  final String doctorId;

  const DeleteDoctor(this.doctorId);

  @override
  List<Object> get props => [doctorId];
}

