import 'package:flutter/material.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView.builder(
        itemCount: 10, // Replace with the actual number of notifications
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(
                'Notification ${index + 1}'), // Replace with actual notification data
            subtitle: Text(
                'Details for notification ${index + 1}'), // Replace with actual notification data
            onTap: () {
              // Handle notification tap
            },
          );
        },
      ),
    );
  }
}
