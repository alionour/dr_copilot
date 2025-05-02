import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bill & Payments as horizontal cards (like in dbestech video)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 220,
                  child: Card(
                    elevation: 8,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(0),
                        topLeft: Radius.circular(0),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('profit'.tr(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                          SizedBox(height: 8),
                          Text('USD 190,655',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer)),
                          SizedBox(height: 8),
                          Text('Today\'s left in billing cycle (Feb 28, 2025)',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha:0.7))),
                          SizedBox(height: 8),
                        
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                SizedBox(
                  width: 220,
                  child: Card(
                    elevation: 4,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(0),
                        bottomLeft: Radius.circular(20),
                        topLeft: Radius.circular(20),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('payments'.tr(),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer)),
                          SizedBox(height: 8),
                          Text('USD 4,200',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer)),
                          SizedBox(height: 8),
                          Text('1 day left in billing cycle (Mar 1, 2025)',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withValues(alpha:0.7))),
                          SizedBox(height: 8),
                         
                        ],
                      ),
                    ),
                  ),
                ),
                // Add more cards here if needed
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Transactions Activity
          Text(
            'transactionsActivity'.tr(),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: 5, // Replace with actual transaction count
              itemBuilder: (context, index) {
                return ListTile(
                  title: const Text('Account 6799'),
                  subtitle: const Text('Feb 17, 2025 - Pending'),
                  trailing: const Text('Adam Barba'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
