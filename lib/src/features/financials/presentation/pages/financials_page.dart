import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/transaction_model.dart';
import '../../data/remote/financials_firebase_api.dart';

/// Displays a list of financial transactions and allows adding new ones.
class FinancialsPage extends StatefulWidget {
  const FinancialsPage({Key? key}) : super(key: key);

  @override
  State<FinancialsPage> createState() => _FinancialsPageState();
}

class _FinancialsPageState extends State<FinancialsPage> {
  final FinancialsFirebaseApi _api = FinancialsFirebaseApi();
  final List<TransactionModel> _transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  /// Fetches transactions from Firestore and updates the state.
  Future<void> _fetchTransactions() async {
    final transactions = await _api.getTransactions();
    setState(() {
      _transactions.clear();
      _transactions.addAll(transactions);
    });
  }

  /// Opens a dialog to add a new transaction.
  Future<void> _addTransactionDialog() async {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String type = 'income';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              DropdownButton<String>(
                value: type,
                onChanged: (value) {
                  setState(() {
                    type = value!;
                  });
                },
                items: const [
                  DropdownMenuItem(value: 'income', child: Text('Income')),
                  DropdownMenuItem(value: 'expense', child: Text('Expense')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final transaction = TransactionModel(
                  id: FirebaseFirestore.instance
                      .collection('transactions')
                      .doc()
                      .id,
                  amount: double.parse(amountController.text),
                  type: type,
                  date: Timestamp.now(),
                  description: descriptionController.text,
                );
                await _api.addTransaction(transaction);
                _fetchTransactions();
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTransactionDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return ListTile(
            title: Text(transaction.description),
            subtitle: Text(transaction.type),
            trailing: Text('${transaction.amount.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}
