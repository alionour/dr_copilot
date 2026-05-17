import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/app/notifiers/owner_notifier.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _appointmentReminders = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId;

    if (clinicId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          final notifications = data['notifications'] as Map<String, dynamic>?;
          if (mounted) {
            setState(() {
              _emailNotifications = notifications?['email'] ?? true;
              _pushNotifications = notifications?['push'] ?? true;
              _appointmentReminders = notifications?['reminders'] ?? true;
              _isLoading = false;
            });
            return;
          }
        }
      } catch (e) {
        debugPrint('Error loading notification settings: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final ownerNotifier = context.read<OwnerNotifier>();
    final clinicId = ownerNotifier.clinicId;

    if (clinicId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('clinics')
            .doc(clinicId)
            .set({
          'notifications': {
            key: value,
            // Preserve other values
            if (key != 'email') 'email': _emailNotifications,
            if (key != 'push') 'push': _pushNotifications,
            if (key != 'reminders') 'reminders': _appointmentReminders,
          }
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error updating notification setting: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: SelectionArea(child: Text('Error saving setting: $e'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('notifications').tr(),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('emailNotifications').tr(),
                  value: _emailNotifications,
                  onChanged: (value) {
                    setState(() {
                      _emailNotifications = value;
                    });
                    _updateSetting('email', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('pushNotifications').tr(),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    _updateSetting('push', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('appointmentReminders').tr(),
                  subtitle: const Text(
                          'Automatically send email reminders to patients 24 hours before appointment')
                      .tr(),
                  value: _appointmentReminders,
                  onChanged: (value) {
                    setState(() {
                      _appointmentReminders = value;
                    });
                    _updateSetting('reminders', value);
                  },
                ),
              ],
            ),
    );
  }
}
