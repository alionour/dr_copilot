import 'package:flutter/material.dart';

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
  liveAssistant(
      NavItemModel('liveAssistant', Icons.mic), 'Live Voice Assistant'),
  patients(NavItemModel('patients', Icons.people), 'Manage your patients'),
  doctors(NavItemModel('doctors', Icons.person_2_outlined), 'Manage your doctors'),
  staff(NavItemModel('staff', Icons.people_outline), 'Manage your staff'),
  sessions(
      NavItemModel('sessions', Icons.schedule_outlined), 'View your sessions'),
  evaluations(NavItemModel('evaluations', Icons.assessment_outlined),
      'View evaluations'),
  charts(
      NavItemModel('charts', Icons.area_chart_outlined), 'Navigate to Charts'),
  financials(NavItemModel('financials', Icons.attach_money_outlined),
      'Manage your financials'),
  clinicalReports(NavItemModel('clinical_reports', Icons.assignment_outlined),
      'Manage your clinical reports'),
  chatGptProject(NavItemModel('chatGptProject', Icons.hub_outlined),
      'Manage your ChatGPT projects');

  final NavItemModel model;
  final String message; // Tooltip or explanation for the destination
  const Destination(this.model, this.message);
}
