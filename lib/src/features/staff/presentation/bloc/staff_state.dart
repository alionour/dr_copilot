part of 'staff_bloc.dart';

abstract class StaffState extends Equatable {
  final List<StaffModel> staff;
  final String? message;

  const StaffState(this.staff, {this.message});

  @override
  List<Object?> get props => [staff, message];
}

class StaffInitial extends StaffState {
  const StaffInitial(super.staff);
}

class StaffLoading extends StaffState {
  const StaffLoading(super.staff);
}

class StaffLoaded extends StaffState {
  const StaffLoaded(super.staff);
}

class StaffError extends StaffState {
  const StaffError(super.staff, {super.message});
}

class StaffSuccess extends StaffState {
  const StaffSuccess(super.staff, {super.message});
}
