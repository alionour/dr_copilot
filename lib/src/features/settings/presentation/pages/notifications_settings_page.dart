import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
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
    final email = await _secureStorage.read(key: 'emailNotifications');
    final push = await _secureStorage.read(key: 'pushNotifications');
    final reminders = await _secureStorage.read(key: 'appointmentReminders');

    if (mounted) {
      setState(() {
        _emailNotifications = email == null ? true : email == 'true';
        _pushNotifications = push == null ? true : push == 'true';
        _appointmentReminders = reminders == null ? true : reminders == 'true';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    await _secureStorage.write(key: key, value: value.toString());
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
                    _updateSetting('emailNotifications', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('pushNotifications').tr(),
                  value: _pushNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pushNotifications = value;
                    });
                    _updateSetting('pushNotifications', value);
                  },
                ),
                SwitchListTile(
                  title: const Text('appointmentReminders').tr(),
                  value: _appointmentReminders,
                  onChanged: (value) {
                    setState(() {
                      _appointmentReminders = value;
                    });
                    _updateSetting('appointmentReminders', value);
                  },
                ),
              ],
            ),
    );
  }
}
