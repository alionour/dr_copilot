part of 'navigation_bloc.dart';

/// A wrapper class to distinguish between a value that is not provided and a value that is null.
class Value<T> {
  final T value;
  Value(this.value);
}

class NavigationState extends Equatable {
  final UserModel? user;
  final Destination destination;
  final int selectedIndex;
  final bool isNavigationFocused;
  final Map<String, List<Destination>> allowedDestinations;

  const NavigationState(
    this.user,
    this.destination,
    this.isNavigationFocused, {
    this.selectedIndex = 0,
    this.allowedDestinations = const {},
  });

  @override
  List<Object?> get props => [
        destination,
        user,
        selectedIndex,
        isNavigationFocused,
        allowedDestinations
      ];

  NavigationState copyWith({
    Value<UserModel?>? user,
    Destination? destination,
    int? selectedIndex,
    bool? isNavigationFocused,
    Map<String, List<Destination>>? allowedDestinations,
  }) {
    return NavigationState(
      user != null ? user.value : this.user,
      destination ?? this.destination,
      isNavigationFocused ?? this.isNavigationFocused,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      allowedDestinations: allowedDestinations ?? this.allowedDestinations,
    );
  }
}


