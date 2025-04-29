part of 'navigation_bloc.dart';

class NavigationState extends Equatable {
  final UserModel? user;
  final Destination destination;
  final int selectedIndex;
  final bool isNavigationFocused;

  const NavigationState(
    this.user,
    this.destination,
    this.isNavigationFocused, {
    this.selectedIndex = 0,
  });

  @override
  List<Object?> get props =>
      [destination, user, selectedIndex, isNavigationFocused];

  NavigationState copyWith({
    UserModel? user,
    Destination? destination,
    int? selectedIndex,
    bool? isNavigationFocused,
  }) {
    return NavigationState(
      user ?? this.user,
      destination ?? this.destination,
      isNavigationFocused ?? this.isNavigationFocused,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}
