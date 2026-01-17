part of 'staff_bloc.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object> get props => [];
}

class AddStaff extends StaffEvent {
  final StaffModel staff;

  const AddStaff(this.staff);

  @override
  List<Object> get props => [staff];
}

class GetStaff extends StaffEvent {
  final String clinicId;

  const GetStaff({required this.clinicId});

  @override
  List<Object> get props => [clinicId];
}

class UpdateStaff extends StaffEvent {
  final String staffId;
  final StaffModel staff;

  const UpdateStaff(this.staffId, this.staff);

  @override
  List<Object> get props => [staffId, staff];
}

class DeleteStaff extends StaffEvent {
  final String staffId;

  const DeleteStaff(this.staffId);

  @override
  List<Object> get props => [staffId];
}

