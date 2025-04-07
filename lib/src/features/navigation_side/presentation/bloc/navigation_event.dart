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
  copilot(
      NavItemModel('copilot', Icons.dashboard_outlined), 'Navigate to Copilot'),
  calendar(NavItemModel('calendar', Icons.calendar_month_outlined),
      'View your calendar'),
  settings(NavItemModel('settings', Icons.settings_suggest_outlined),
      'Adjust your settings'),
  notifications(NavItemModel('notifications', Icons.notifications_on_outlined),
      'View notifications'),
  chat(NavItemModel('chat', Icons.chat_outlined), 'Open chat'),
  patients(NavItemModel('patients', Icons.people), 'Manage your patients'),
  sessions(
      NavItemModel('sessions', Icons.schedule_outlined), 'View your sessions'),
  evaluations(NavItemModel('evaluations', Icons.assessment_outlined),
      'View evaluations');

  final NavItemModel model;
  final String message; // Tooltip or explanation for the destination
  const Destination(this.model, this.message);
}
