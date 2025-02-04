part of 'navigation_bloc.dart';

// Events
abstract class NavigationEvent {}

/// Event to fetch user data.
class GetUserData extends NavigationEvent {}

/// Event to navigate to a specific destination.
class NavigateToEvent extends NavigationEvent {
  final Destination destination;
  NavigateToEvent(this.destination);
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
