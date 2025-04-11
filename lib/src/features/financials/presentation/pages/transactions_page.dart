import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          // Navigate to the page to add a transaction
          context.go('/add_transaction');
        },
      ),
      body: const Center(
        child: Text('Transactions Page Content'),
      ),
    );
  }
}
