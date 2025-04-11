import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

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
      body: FutureBuilder(
        future: _fetchTransactions(), // Simulate fetching transactions
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Show shimmer effect while loading
            return ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 80.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading transactions'));
          } else {
            // Replace with actual transaction list
            return const Center(child: Text('Transactions Page Content'));
          }
        },
      ),
    );
  }

  Future<List<String>> _fetchTransactions() async {
    // Simulate a delay for fetching transactions
    await Future.delayed(const Duration(seconds: 2));
    return []; // Replace with actual transaction data
  }
}
