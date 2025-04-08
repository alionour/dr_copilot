import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('notifications'.tr()),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with the actual number of notifications
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.notifications),
            title: Text('notificationTitle'.tr(args: [
              '${index + 1}'
            ])), // Replace with actual notification data
            subtitle: Text('notificationDetails'.tr(args: [
              '${index + 1}'
            ])), // Replace with actual notification data
            onTap: () {
              // Handle notification tap
            },
          );
        },
      ),
    );
  }
}
