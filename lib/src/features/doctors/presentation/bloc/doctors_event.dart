part of 'doctors_bloc.dart';

/// Abstract base class for all Doctors events.
abstract class DoctorsEvent extends Equatable {
  const DoctorsEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered to add a new doctor.
class AddDoctor extends DoctorsEvent {
  final DoctorModel doctor;

  const AddDoctor(this.doctor);

  @override
  List<Object> get props => [doctor];
}

/// Event triggered to fetch the list of doctors for a clinic.
class GetDoctors extends DoctorsEvent {
  final String? clinicId;

  const GetDoctors({this.clinicId});

  @override
  List<Object> get props => [clinicId ?? ''];
}

/// Event triggered to update an existing doctor's information.
class UpdateDoctor extends DoctorsEvent {
  final String doctorId;
  final DoctorModel doctor;

  const UpdateDoctor(this.doctorId, this.doctor);

  @override
  List<Object> get props => [doctorId, doctor];
}

/// Event triggered to delete a doctor.
class DeleteDoctor extends DoctorsEvent {
  final String doctorId;

  const DeleteDoctor(this.doctorId);

  @override
  List<Object> get props => [doctorId];
}
