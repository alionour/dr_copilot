part of 'navigation_bloc.dart';

// Events
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => [];
}

class NavigateToEvent extends NavigationEvent {
  final Destination destination;
  const NavigateToEvent(this.destination);

  @override
  List<Object?> get props => [destination];
}

class NavigateUpEvent extends NavigationEvent {}

class NavigateDownEvent extends NavigationEvent {}

class ChangeFocusEvent extends NavigationEvent {
  final bool isFocused;
  const ChangeFocusEvent(this.isFocused);

  @override
  List<Object?> get props => [isFocused];
}

class UserChanged extends NavigationEvent {
  final UserModel? user;
  const UserChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class DestinationsUpdated extends NavigationEvent {
  final Map<String, List<Destination>> destinations;
  const DestinationsUpdated(this.destinations);

  @override
  List<Object?> get props => [destinations];
}

