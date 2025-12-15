import 'package:flutter/material.dart';

/// Model for navigation items.
class NavItemModel {
  final String title;
  final IconData icon;

  const NavItemModel(this.title, this.icon);
}

/// Enum representing different navigation destinations.
enum Destination {
  // Core Operations
  copilot(
    NavItemModel('copilot', Icons.psychology_outlined),
    'Navigate to Copilot',
  ),
  calendar(
    NavItemModel('calendar', Icons.event_outlined),
    'View your calendar',
  ),

  // Management
  patients(
    NavItemModel('patients', Icons.person_search_outlined),
    'Manage your patients',
  ),
  doctors(
    NavItemModel('doctors', Icons.medical_services_outlined),
    'Manage your doctors',
  ),
  staff(NavItemModel('staff', Icons.badge_outlined), 'Manage your staff'),
  invitations(
    NavItemModel('invitations', Icons.mail_outline),
    'Manage user invitations',
  ),
  clinicalReports(
    NavItemModel('clinical_reports', Icons.description_outlined),
    'Manage your clinical reports',
  ),

  // Appointments
  sessions(
    NavItemModel('sessions', Icons.event_seat_outlined),
    'View your sessions',
  ),
  evaluations(
    NavItemModel('evaluations', Icons.assignment_turned_in_outlined),
    'View evaluations',
  ),

  // Business
  financials(
    NavItemModel('financials', Icons.account_balance_wallet_outlined),
    'Manage your financials',
  ),
  charts(
    NavItemModel('charts', Icons.analytics_outlined),
    'Navigate to Charts',
  ),

  // Utilities
  notifications(
    NavItemModel('notifications', Icons.notifications_outlined),
    'View notifications',
  ),
  settings(
    NavItemModel('settings', Icons.settings_outlined),
    'Adjust your settings',
  ),
  chatGptProject(
    NavItemModel('chatGptProject', Icons.api_outlined),
    'Manage your ChatGPT projects',
  ),
  recycleBin(
    NavItemModel('recycleBin', Icons.delete_outline),
    'View deleted items',
  ),

  // Team Collaboration
  teamChat(NavItemModel('messages', Icons.chat), 'Messages'),
  teams(NavItemModel('teams', Icons.groups), 'Manage your teams'),

  // Additional (not currently in menu)
  chat(NavItemModel('chat', Icons.chat_bubble_outline), 'Open chat'),
  liveAssistant(
    NavItemModel('liveAssistant', Icons.mic_outlined),
    'Live Voice Assistant',
  );

  final NavItemModel model;
  final String message; // Tooltip or explanation for the destination
  const Destination(this.model, this.message);
}

