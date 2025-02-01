part of 'navigation_bloc.dart';

// Events
abstract class NavigationEvent {}

/// fetch userdata
class GetUserData extends NavigationEvent {}

class NavigateToEvent extends NavigationEvent {
  final Destination destination;
  NavigateToEvent(this.destination);
}

class NavItemModel {
  final String title;
  final IconData icon;

  const NavItemModel(this.title, this.icon);
}

enum Destination {
  copilot(NavItemModel('Copilot', Icons.dashboard_outlined)),
  calendar(NavItemModel('Calendar', Icons.calendar_month_outlined)),
  settings(NavItemModel('Settings', Icons.settings_suggest_outlined)),
  notifications(NavItemModel('Notifications', Icons.notifications_on_outlined)),
  chat(NavItemModel('Chat', Icons.chat_outlined));

  final NavItemModel model;
  const Destination(this.model);
}
