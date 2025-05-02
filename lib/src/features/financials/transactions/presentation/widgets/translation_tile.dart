import 'package:flutter/material.dart';

/// A tile widget to display individual transactions.
class TransactionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String amount;

  const TransactionTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text(
        amount,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
