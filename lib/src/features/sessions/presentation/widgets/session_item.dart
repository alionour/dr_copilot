import 'package:flutter/material.dart';

class SessionItem extends StatelessWidget {
  final String sessionData;

  const SessionItem({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(sessionData),
    );
  }
}
