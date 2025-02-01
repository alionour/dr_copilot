part of 'navigation_bloc.dart';

class NavigationState extends Equatable {
  final Destination destination;
  final User? user;
  const NavigationState(this.user, this.destination);

  @override
  List<Object?> get props => [destination, user];

  NavigationState copyWith({User? user, Destination? destination}) {
    return NavigationState(
      user ?? this.user,
      destination ?? this.destination,
    );
  }
}
