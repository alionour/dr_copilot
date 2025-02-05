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

/// Model for navigation items.
class NavItemModel {
  final String title;
  final IconData icon;

  const NavItemModel(this.title, this.icon);
}

/// Enum representing different navigation destinations.
enum Destination {
  copilot(NavItemModel('Copilot', Icons.dashboard_outlined)),
  calendar(NavItemModel('Calendar', Icons.calendar_month_outlined)),
  settings(NavItemModel('Settings', Icons.settings_suggest_outlined)),
  notifications(NavItemModel('Notifications', Icons.notifications_on_outlined)),
  chat(NavItemModel('Chat', Icons.chat_outlined)),
  patients(NavItemModel('Patients', Icons.people)); // Added Patients destination

  final NavItemModel model;
  const Destination(this.model);
}
