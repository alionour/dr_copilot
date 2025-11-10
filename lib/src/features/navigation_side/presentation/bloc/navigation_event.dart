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

class GetUserData extends NavigationEvent {}

class ChangeFocusEvent extends NavigationEvent {
  final bool isFocused;
  const ChangeFocusEvent(this.isFocused);

  @override
  List<Object?> get props => [isFocused];
}
